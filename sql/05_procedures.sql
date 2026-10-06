-- Little Lemon Restaurant Management System
-- Stored procedures

USE LittleLemonDB;

DELIMITER //

-- Largest quantity of a single item in one order line.
-- Pass NULL to search across all menu items.
CREATE PROCEDURE GetMaxQuantity(IN p_menu_item_id INT)
BEGIN
    IF p_menu_item_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM MenuItems WHERE MenuItemID = p_menu_item_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Menu item does not exist';
    END IF;

    SELECT MAX(Quantity) AS MaximumOrderedQuantity
    FROM OrderItems
    WHERE p_menu_item_id IS NULL OR MenuItemID = p_menu_item_id;
END //

-- Reports whether a table is free at a given date and time
CREATE PROCEDURE CheckBooking(IN p_date DATE, IN p_time TIME, IN p_table_number INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM RestaurantTables WHERE TableNumber = p_table_number) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table does not exist';
    END IF;

    SELECT IF(EXISTS (SELECT 1
                      FROM Bookings
                      WHERE TableNumber = p_table_number
                        AND BookingDate = p_date
                        AND BookingTime = p_time
                        AND Status <> 'Cancelled'),
              'Table is already booked.',
              'Table is available.') AS TableStatus;
END //

-- Tables with enough seats that are free at a given date and time
CREATE PROCEDURE GetAvailableTables(IN p_date DATE, IN p_time TIME, IN p_guests INT)
BEGIN
    SELECT t.TableNumber, t.Capacity
    FROM RestaurantTables t
    WHERE t.Capacity >= p_guests
      AND NOT EXISTS (SELECT 1
                      FROM Bookings b
                      WHERE b.TableNumber = t.TableNumber
                        AND b.BookingDate = p_date
                        AND b.BookingTime = p_time
                        AND b.Status <> 'Cancelled')
    ORDER BY t.Capacity, t.TableNumber;
END //

-- Creates a booking. The unique key on (table, date, time) is what prevents
-- double booking, so two concurrent callers cannot both succeed.
CREATE PROCEDURE AddBooking(
    IN  p_customer_id  INT,
    IN  p_staff_id     INT,
    IN  p_table_number INT,
    IN  p_date         DATE,
    IN  p_time         TIME,
    IN  p_guests       INT,
    OUT p_booking_id   INT
)
BEGIN
    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table is already booked for that date and time';
    END;

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer, staff member or table does not exist';
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking date cannot be in the past';
    END IF;

    START TRANSACTION;

    INSERT INTO Bookings (CustomerID, StaffID, TableNumber, BookingDate, BookingTime, GuestCount)
    VALUES (p_customer_id, p_staff_id, p_table_number, p_date, p_time, p_guests);

    SET p_booking_id = LAST_INSERT_ID();

    COMMIT;

    SELECT p_booking_id AS BookingID, 'Booking confirmed' AS Confirmation;
END //

-- Moves a confirmed booking to a new date and time
CREATE PROCEDURE UpdateBooking(IN p_booking_id INT, IN p_date DATE, IN p_time TIME)
BEGIN
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR 1062
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Table is already booked for that date and time';
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking date cannot be in the past';
    END IF;

    START TRANSACTION;

    SELECT Status INTO v_status FROM Bookings WHERE BookingID = p_booking_id FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking does not exist';
    ELSEIF v_status <> 'Confirmed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only confirmed bookings can be changed';
    END IF;

    UPDATE Bookings
    SET BookingDate = p_date,
        BookingTime = p_time
    WHERE BookingID = p_booking_id;

    COMMIT;

    SELECT CONCAT('Booking ', p_booking_id, ' updated') AS Confirmation;
END //

-- Cancels a confirmed booking and frees its slot
CREATE PROCEDURE CancelBooking(IN p_booking_id INT)
BEGIN
    DECLARE v_status VARCHAR(20);

    SELECT Status INTO v_status FROM Bookings WHERE BookingID = p_booking_id;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking does not exist';
    ELSEIF v_status <> 'Confirmed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only confirmed bookings can be cancelled';
    END IF;

    UPDATE Bookings SET Status = 'Cancelled' WHERE BookingID = p_booking_id;

    SELECT CONCAT('Booking ', p_booking_id, ' cancelled') AS Confirmation;
END //

-- Places an order from a JSON array such as
--   [{"menu_item_id": 1, "quantity": 2}, {"menu_item_id": 6, "quantity": 2}]
-- Prices are copied from the menu at the time of the order.
CREATE PROCEDURE PlaceOrder(
    IN  p_customer_id INT,
    IN  p_staff_id    INT,
    IN  p_items       JSON,
    OUT p_order_id    INT
)
BEGIN
    DECLARE v_requested INT;
    DECLARE v_available INT;

    DECLARE EXIT HANDLER FOR 1452
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Customer, staff member or menu item does not exist';
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_items IS NULL OR JSON_TYPE(p_items) <> 'ARRAY' OR JSON_LENGTH(p_items) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Items must be a non-empty JSON array';
    END IF;

    DROP TEMPORARY TABLE IF EXISTS tmp_order_items;
    CREATE TEMPORARY TABLE tmp_order_items AS
    SELECT jt.menu_item_id AS MenuItemID, SUM(jt.quantity) AS Quantity
    FROM JSON_TABLE(p_items, '$[*]' COLUMNS (
             menu_item_id INT PATH '$.menu_item_id',
             quantity     INT PATH '$.quantity'
         )) AS jt
    GROUP BY jt.menu_item_id;

    SELECT COUNT(*) INTO v_requested FROM tmp_order_items;

    SELECT COUNT(*) INTO v_available
    FROM tmp_order_items t
    JOIN MenuItems mi ON mi.MenuItemID = t.MenuItemID
    WHERE mi.IsAvailable
      AND t.Quantity > 0;

    IF v_available <> v_requested THEN
        DROP TEMPORARY TABLE tmp_order_items;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Every item must exist, be available and have a quantity above zero';
    END IF;

    START TRANSACTION;

    INSERT INTO Orders (CustomerID, StaffID) VALUES (p_customer_id, p_staff_id);
    SET p_order_id = LAST_INSERT_ID();

    INSERT INTO OrderItems (OrderID, MenuItemID, Quantity, UnitPrice)
    SELECT p_order_id, t.MenuItemID, t.Quantity, mi.Price
    FROM tmp_order_items t
    JOIN MenuItems mi ON mi.MenuItemID = t.MenuItemID;

    COMMIT;

    DROP TEMPORARY TABLE tmp_order_items;

    SELECT p_order_id AS OrderID, TotalCost, 'Order placed' AS Confirmation
    FROM Orders
    WHERE OrderID = p_order_id;
END //

-- Moves an order forward through Placed > Preparing > Out for delivery > Delivered
CREATE PROCEDURE UpdateOrderStatus(IN p_order_id INT, IN p_new_status VARCHAR(20))
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_old_rank INT;
    DECLARE v_new_rank INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SET v_new_rank = FIELD(p_new_status, 'Placed', 'Preparing', 'Out for delivery', 'Delivered');

    IF v_new_rank = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Status must be Preparing, Out for delivery or Delivered. Use CancelOrder to cancel';
    END IF;

    START TRANSACTION;

    SELECT Status INTO v_status FROM Orders WHERE OrderID = p_order_id FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order does not exist';
    END IF;

    SET v_old_rank = FIELD(v_status, 'Placed', 'Preparing', 'Out for delivery', 'Delivered');

    IF v_old_rank = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A cancelled order cannot change status';
    ELSEIF v_new_rank <= v_old_rank THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order status can only move forward';
    END IF;

    UPDATE Orders SET Status = p_new_status WHERE OrderID = p_order_id;

    COMMIT;

    SELECT CONCAT('Order ', p_order_id, ' is now ', p_new_status) AS Confirmation;
END //

-- Cancels an order that has not been delivered yet. The row is kept so
-- revenue history and the status log stay intact.
CREATE PROCEDURE CancelOrder(IN p_order_id INT)
BEGIN
    DECLARE v_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT Status INTO v_status FROM Orders WHERE OrderID = p_order_id FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order does not exist';
    ELSEIF v_status = 'Delivered' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A delivered order cannot be cancelled';
    ELSEIF v_status = 'Cancelled' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order is already cancelled';
    END IF;

    UPDATE Orders SET Status = 'Cancelled' WHERE OrderID = p_order_id;

    COMMIT;

    SELECT CONCAT('Order ', p_order_id, ' is cancelled') AS Confirmation;
END //

DELIMITER ;
