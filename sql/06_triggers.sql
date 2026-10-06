-- Little Lemon Restaurant Management System
-- Triggers

USE LittleLemonDB;

DELIMITER //

-- A booking cannot exceed the seats at its table
CREATE TRIGGER trg_Bookings_BeforeInsert
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
    DECLARE v_capacity INT;

    SELECT Capacity INTO v_capacity
    FROM RestaurantTables
    WHERE TableNumber = NEW.TableNumber;

    IF v_capacity IS NOT NULL AND NEW.GuestCount > v_capacity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Guest count exceeds table capacity';
    END IF;
END //

-- Unavailable menu items cannot be ordered
CREATE TRIGGER trg_OrderItems_BeforeInsert
BEFORE INSERT ON OrderItems
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM MenuItems
               WHERE MenuItemID = NEW.MenuItemID AND NOT IsAvailable) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Menu item is not available';
    END IF;
END //

-- Keep Orders.TotalCost equal to the sum of its lines
CREATE TRIGGER trg_OrderItems_AfterInsert
AFTER INSERT ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET TotalCost = (SELECT COALESCE(SUM(Quantity * UnitPrice), 0)
                     FROM OrderItems WHERE OrderID = NEW.OrderID)
    WHERE OrderID = NEW.OrderID;
END //

CREATE TRIGGER trg_OrderItems_AfterUpdate
AFTER UPDATE ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET TotalCost = (SELECT COALESCE(SUM(Quantity * UnitPrice), 0)
                     FROM OrderItems WHERE OrderID = NEW.OrderID)
    WHERE OrderID = NEW.OrderID;
END //

CREATE TRIGGER trg_OrderItems_AfterDelete
AFTER DELETE ON OrderItems
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET TotalCost = (SELECT COALESCE(SUM(Quantity * UnitPrice), 0)
                     FROM OrderItems WHERE OrderID = OLD.OrderID)
    WHERE OrderID = OLD.OrderID;
END //

-- Record every order status in OrderDeliveryStatuses
CREATE TRIGGER trg_Orders_AfterInsert
AFTER INSERT ON Orders
FOR EACH ROW
BEGIN
    INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
    VALUES (NEW.OrderID, NEW.OrderDate, NEW.Status);
END //

CREATE TRIGGER trg_Orders_AfterUpdate
AFTER UPDATE ON Orders
FOR EACH ROW
BEGIN
    IF OLD.Status <> NEW.Status THEN
        INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
        VALUES (NEW.OrderID, NOW(), NEW.Status);
    END IF;
END //

-- Audit trail for salary changes
CREATE TRIGGER trg_StaffInformation_AfterUpdate
AFTER UPDATE ON StaffInformation
FOR EACH ROW
BEGIN
    IF OLD.Salary <> NEW.Salary THEN
        INSERT INTO StaffSalaryAudit (StaffID, OldSalary, NewSalary, ChangedBy)
        VALUES (NEW.StaffID, OLD.Salary, NEW.Salary, CURRENT_USER());
    END IF;
END //

DELIMITER ;
