-- Little Lemon Restaurant Management System
-- Schema: tables, constraints and indexes (MySQL 8.0+)

DROP DATABASE IF EXISTS LittleLemonDB;
CREATE DATABASE LittleLemonDB
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;
USE LittleLemonDB;

-- People

CREATE TABLE CustomerDetails (
    CustomerID    INT          NOT NULL AUTO_INCREMENT,
    Name          VARCHAR(100) NOT NULL,
    ContactNumber VARCHAR(20)  NOT NULL,
    Email         VARCHAR(100) NOT NULL,
    CreatedAt     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (CustomerID),
    UNIQUE KEY uq_CustomerDetails_Email (Email),
    CONSTRAINT chk_CustomerDetails_Email CHECK (Email LIKE '%_@_%._%')
) ENGINE = InnoDB;

CREATE TABLE StaffInformation (
    StaffID INT           NOT NULL AUTO_INCREMENT,
    Name    VARCHAR(100)  NOT NULL,
    Role    VARCHAR(30)   NOT NULL,
    Salary  DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (StaffID),
    CONSTRAINT chk_StaffInformation_Role
        CHECK (Role IN ('Manager', 'Waiter', 'Chef', 'Cashier', 'Hostess')),
    CONSTRAINT chk_StaffInformation_Salary CHECK (Salary >= 0)
) ENGINE = InnoDB;

CREATE TABLE StaffSalaryAudit (
    AuditID   INT           NOT NULL AUTO_INCREMENT,
    StaffID   INT           NOT NULL,
    OldSalary DECIMAL(10,2) NOT NULL,
    NewSalary DECIMAL(10,2) NOT NULL,
    ChangedAt DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ChangedBy VARCHAR(100)  NOT NULL,
    PRIMARY KEY (AuditID),
    KEY idx_StaffSalaryAudit_StaffID (StaffID),
    CONSTRAINT fk_StaffSalaryAudit_Staff
        FOREIGN KEY (StaffID) REFERENCES StaffInformation (StaffID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Menu

CREATE TABLE Cuisines (
    CuisineID INT         NOT NULL AUTO_INCREMENT,
    Name      VARCHAR(45) NOT NULL,
    PRIMARY KEY (CuisineID),
    UNIQUE KEY uq_Cuisines_Name (Name)
) ENGINE = InnoDB;

CREATE TABLE MenuCategories (
    CategoryID INT         NOT NULL AUTO_INCREMENT,
    Name       VARCHAR(45) NOT NULL,
    PRIMARY KEY (CategoryID),
    UNIQUE KEY uq_MenuCategories_Name (Name)
) ENGINE = InnoDB;

CREATE TABLE MenuItems (
    MenuItemID  INT          NOT NULL AUTO_INCREMENT,
    Name        VARCHAR(80)  NOT NULL,
    CategoryID  INT          NOT NULL,
    CuisineID   INT          NOT NULL,
    Price       DECIMAL(8,2) NOT NULL,
    IsAvailable BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (MenuItemID),
    UNIQUE KEY uq_MenuItems_Name (Name),
    KEY idx_MenuItems_Category (CategoryID),
    KEY idx_MenuItems_Cuisine (CuisineID),
    CONSTRAINT chk_MenuItems_Price CHECK (Price > 0),
    CONSTRAINT fk_MenuItems_Category
        FOREIGN KEY (CategoryID) REFERENCES MenuCategories (CategoryID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_MenuItems_Cuisine
        FOREIGN KEY (CuisineID) REFERENCES Cuisines (CuisineID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Bookings

CREATE TABLE RestaurantTables (
    TableNumber INT     NOT NULL,
    Capacity    TINYINT NOT NULL,
    PRIMARY KEY (TableNumber),
    CONSTRAINT chk_RestaurantTables_Capacity CHECK (Capacity BETWEEN 1 AND 20)
) ENGINE = InnoDB;

-- SlotLock is NULL for cancelled bookings, so the unique key below only
-- applies to live bookings and a cancelled slot can be booked again.
CREATE TABLE Bookings (
    BookingID   INT        NOT NULL AUTO_INCREMENT,
    CustomerID  INT        NOT NULL,
    StaffID     INT        NOT NULL,
    TableNumber INT        NOT NULL,
    BookingDate DATE       NOT NULL,
    BookingTime TIME       NOT NULL,
    GuestCount  TINYINT    NOT NULL,
    Status      ENUM('Confirmed', 'Completed', 'Cancelled') NOT NULL DEFAULT 'Confirmed',
    SlotLock    TINYINT GENERATED ALWAYS AS (IF(Status = 'Cancelled', NULL, 1)) STORED,
    PRIMARY KEY (BookingID),
    UNIQUE KEY uq_Bookings_Slot (TableNumber, BookingDate, BookingTime, SlotLock),
    KEY idx_Bookings_Date (BookingDate),
    KEY idx_Bookings_Customer (CustomerID),
    KEY idx_Bookings_Staff (StaffID),
    CONSTRAINT chk_Bookings_GuestCount CHECK (GuestCount > 0),
    CONSTRAINT fk_Bookings_Customer
        FOREIGN KEY (CustomerID) REFERENCES CustomerDetails (CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_Bookings_Staff
        FOREIGN KEY (StaffID) REFERENCES StaffInformation (StaffID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_Bookings_Table
        FOREIGN KEY (TableNumber) REFERENCES RestaurantTables (TableNumber)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Orders

CREATE TABLE Orders (
    OrderID    INT           NOT NULL AUTO_INCREMENT,
    CustomerID INT           NOT NULL,
    StaffID    INT           NOT NULL,
    OrderDate  DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Status     ENUM('Placed', 'Preparing', 'Out for delivery', 'Delivered', 'Cancelled')
               NOT NULL DEFAULT 'Placed',
    TotalCost  DECIMAL(10,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (OrderID),
    KEY idx_Orders_OrderDate (OrderDate),
    KEY idx_Orders_Customer_Date (CustomerID, OrderDate),
    KEY idx_Orders_Staff (StaffID),
    KEY idx_Orders_Status (Status),
    CONSTRAINT chk_Orders_TotalCost CHECK (TotalCost >= 0),
    CONSTRAINT fk_Orders_Customer
        FOREIGN KEY (CustomerID) REFERENCES CustomerDetails (CustomerID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_Orders_Staff
        FOREIGN KEY (StaffID) REFERENCES StaffInformation (StaffID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE OrderItems (
    OrderID    INT          NOT NULL,
    MenuItemID INT          NOT NULL,
    Quantity   SMALLINT     NOT NULL,
    UnitPrice  DECIMAL(8,2) NOT NULL,
    PRIMARY KEY (OrderID, MenuItemID),
    KEY idx_OrderItems_MenuItem (MenuItemID),
    CONSTRAINT chk_OrderItems_Quantity CHECK (Quantity > 0),
    CONSTRAINT chk_OrderItems_UnitPrice CHECK (UnitPrice > 0),
    CONSTRAINT fk_OrderItems_Order
        FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_OrderItems_MenuItem
        FOREIGN KEY (MenuItemID) REFERENCES MenuItems (MenuItemID)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE TABLE OrderDeliveryStatuses (
    DeliveryID INT      NOT NULL AUTO_INCREMENT,
    OrderID    INT      NOT NULL,
    StatusDate DATETIME NOT NULL,
    Status     ENUM('Placed', 'Preparing', 'Out for delivery', 'Delivered', 'Cancelled') NOT NULL,
    PRIMARY KEY (DeliveryID),
    KEY idx_OrderDeliveryStatuses_Order (OrderID, StatusDate),
    CONSTRAINT fk_OrderDeliveryStatuses_Order
        FOREIGN KEY (OrderID) REFERENCES Orders (OrderID)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE = InnoDB;

-- Little Lemon Restaurant Management System
-- Reference data and a hand-written sample dataset

USE LittleLemonDB;

INSERT INTO CustomerDetails (CustomerID, Name, ContactNumber, Email) VALUES
(1,  'John Doe', '555-1234', 'customer1@email.com'),
(2,  'Jane Doe',        '555-2345', 'customer2@email.com'),
(3,  'Alice Morgan',    '555-3456', 'customer3@email.com'),
(4,  'Bob Harris',      '555-4567', 'customer4@email.com'),
(5,  'Charlie Brooks',  '555-5678', 'customer5@email.com'),
(6,  'David Kim',       '555-6789', 'customer6@email.com'),
(7,  'Emily Clarke',    '555-7890', 'customer7@email.com'),
(8,  'Frank Wilson',    '555-8901', 'customer8@email.com'),
(9,  'Grace Lee',       '555-9012', 'customer9@email.com'),
(10, 'Hannah Patel',    '555-0123', 'customer10@email.com');

INSERT INTO StaffInformation (StaffID, Name, Role, Salary) VALUES
(1,  'Sarah',   'Manager', 55000.00),
(2,  'Tom',     'Waiter',  30000.00),
(3,  'Linda',   'Chef',    40000.00),
(4,  'Robert',  'Cashier', 31000.00),
(5,  'Daniel',  'Waiter',  32000.00),
(6,  'Susan',   'Hostess', 28000.00),
(7,  'Chris',   'Manager', 60000.00),
(8,  'Jessica', 'Chef',    38000.00),
(9,  'Brian',   'Waiter',  29000.00),
(10, 'Kim',     'Hostess', 27000.00);

INSERT INTO Cuisines (CuisineID, Name) VALUES
(1, 'American'),
(2, 'Italian'),
(3, 'Mediterranean'),
(4, 'Indian'),
(5, 'Mexican');

INSERT INTO MenuCategories (CategoryID, Name) VALUES
(1, 'Starter'),
(2, 'Main'),
(3, 'Side'),
(4, 'Dessert'),
(5, 'Drink');

INSERT INTO MenuItems (MenuItemID, Name, CategoryID, CuisineID, Price) VALUES
(1,  'Cheese Burger',    2, 1, 10.50),
(2,  'Veggie Burger',    2, 1,  9.50),
(3,  'French Fries',     3, 1,  3.25),
(4,  'Caesar Salad',     1, 1,  8.00),
(5,  'Chicken Wings',    1, 1,  6.50),
(6,  'Coca Cola',        5, 1,  2.25),
(7,  'Pasta Carbonara',  2, 2, 11.75),
(8,  'Bruschetta',       1, 2,  5.50),
(9,  'Margarita',        5, 5,  5.00),
(10, 'Ice Cream',        4, 1,  4.00),
(11, 'Greek Salad',      1, 3,  7.25),
(12, 'Falafel Wrap',     2, 3,  8.75),
(13, 'Chicken Curry',    2, 4, 10.00),
(14, 'Samosas',          1, 4,  4.50),
(15, 'Gulab Jamun',      4, 4,  4.25),
(16, 'Tiramisu',         4, 2,  5.75),
(17, 'Lemonade',         5, 3,  3.00),
(18, 'Steamed Rice',     3, 4,  3.50);

INSERT INTO RestaurantTables (TableNumber, Capacity) VALUES
(1, 2), (2, 2), (3, 2),
(4, 4), (5, 4), (6, 4), (7, 4),
(8, 6), (9, 6), (10, 6),
(11, 8), (12, 8),
(13, 10), (14, 10),
(15, 12);

INSERT INTO Bookings (CustomerID, StaffID, TableNumber, BookingDate, BookingTime, GuestCount, Status) VALUES
(1, 6,  5, '2023-09-01', '12:00:00', 4, 'Completed'),
(2, 10, 2, '2023-09-01', '12:30:00', 2, 'Completed'),
(3, 6,  9, '2023-09-02', '13:00:00', 5, 'Completed'),
(4, 10, 11,'2023-09-02', '14:00:00', 7, 'Completed'),
(5, 6,  4, '2023-09-03', '15:00:00', 3, 'Cancelled'),
(6, 10, 8, '2023-09-03', '16:00:00', 6, 'Completed'),
(7, 6,  1, '2023-09-04', '17:00:00', 2, 'Completed'),
(8, 10, 13,'2023-09-04', '18:00:00', 9, 'Completed'),
(3, 6,  5, '2022-11-12', '19:00:00', 4, 'Completed'),
(1, 7,  5, '2022-10-10', '19:00:00', 4, 'Cancelled'),
(1, 6,  5, '2022-10-10', '19:00:00', 3, 'Completed');

INSERT INTO Bookings (CustomerID, StaffID, TableNumber, BookingDate, BookingTime, GuestCount, Status) VALUES
(2,  6,  4,  CURDATE() + INTERVAL 1 DAY, '18:00:00', 4, 'Confirmed'),
(9,  10, 12, CURDATE() + INTERVAL 1 DAY, '20:00:00', 8, 'Confirmed'),
(10, 6,  3,  CURDATE() + INTERVAL 2 DAY, '19:00:00', 2, 'Confirmed'),
(4,  10, 15, CURDATE() + INTERVAL 5 DAY, '19:30:00', 11,'Confirmed');

INSERT INTO Orders (OrderID, CustomerID, StaffID, OrderDate, Status) VALUES
(1,  1,  2, '2023-09-01 12:00:00', 'Delivered'),
(2,  2,  2, '2023-09-01 12:30:00', 'Delivered'),
(3,  3,  5, '2023-09-02 13:00:00', 'Delivered'),
(4,  4,  4, '2023-09-02 14:00:00', 'Delivered'),
(5,  5,  9, '2023-09-03 15:00:00', 'Cancelled'),
(6,  6,  2, '2023-09-03 16:00:00', 'Delivered'),
(7,  7,  5, '2023-09-04 17:00:00', 'Delivered'),
(8,  8,  4, '2023-09-04 18:00:00', 'Delivered'),
(9,  9,  9, '2023-09-05 19:00:00', 'Out for delivery'),
(10, 10, 2, '2023-09-05 20:00:00', 'Preparing');

INSERT INTO OrderItems (OrderID, MenuItemID, Quantity, UnitPrice)
SELECT x.OrderID, x.MenuItemID, x.Quantity, m.Price
FROM (
    SELECT 1 AS OrderID, 1 AS MenuItemID, 2 AS Quantity UNION ALL
    SELECT 1, 3, 2  UNION ALL SELECT 1, 6, 2  UNION ALL
    SELECT 2, 7, 1  UNION ALL SELECT 2, 8, 1  UNION ALL SELECT 2, 16, 1 UNION ALL
    SELECT 3, 13, 2 UNION ALL SELECT 3, 18, 2 UNION ALL SELECT 3, 14, 1 UNION ALL SELECT 3, 17, 3 UNION ALL
    SELECT 4, 4, 1  UNION ALL
    SELECT 5, 2, 1  UNION ALL SELECT 5, 3, 1  UNION ALL
    SELECT 6, 12, 2 UNION ALL SELECT 6, 11, 2 UNION ALL SELECT 6, 17, 2 UNION ALL
    SELECT 7, 7, 1  UNION ALL SELECT 7, 9, 2  UNION ALL SELECT 7, 10, 1 UNION ALL
    SELECT 8, 5, 2  UNION ALL SELECT 8, 1, 2  UNION ALL SELECT 8, 6, 4  UNION ALL
    SELECT 9, 13, 1 UNION ALL SELECT 9, 15, 3 UNION ALL
    SELECT 10, 2, 1 UNION ALL SELECT 10, 17, 1
) AS x
JOIN MenuItems AS m ON m.MenuItemID = x.MenuItemID;

UPDATE Orders AS o
JOIN (
    SELECT OrderID, SUM(Quantity * UnitPrice) AS Total
    FROM OrderItems
    GROUP BY OrderID
) AS s ON s.OrderID = o.OrderID
SET o.TotalCost = s.Total
WHERE o.OrderID <= 10;

-- Status history for the sample orders
INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate, 'Placed' FROM Orders WHERE OrderID <= 10;

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 10 MINUTE, 'Preparing'
FROM Orders WHERE OrderID <= 10 AND Status IN ('Preparing', 'Out for delivery', 'Delivered');

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 25 MINUTE, 'Out for delivery'
FROM Orders WHERE OrderID <= 10 AND Status IN ('Out for delivery', 'Delivered');

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 40 MINUTE, 'Delivered'
FROM Orders WHERE OrderID <= 10 AND Status = 'Delivered';

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 5 MINUTE, 'Cancelled'
FROM Orders WHERE OrderID <= 10 AND Status = 'Cancelled';

-- Little Lemon Restaurant Management System
-- Deterministic bulk data for analytics and index testing
-- Adds 190 customers, 3,000 bookings and 5,000 orders (2024) with line items

USE LittleLemonDB;

SET SESSION cte_max_recursion_depth = 10000;

-- Customers 11..200
INSERT INTO CustomerDetails (CustomerID, Name, ContactNumber, Email)
WITH RECURSIVE seq (n) AS (
    SELECT 11 UNION ALL SELECT n + 1 FROM seq WHERE n < 200
)
SELECT n,
       CONCAT(
           ELT(1 + MOD(n, 12), 'Aarav', 'Maya', 'Liam', 'Sofia', 'Rohan', 'Emma',
                               'Noah', 'Priya', 'Lucas', 'Zara', 'Arjun', 'Olivia'),
           ' ',
           ELT(1 + MOD(FLOOR(n / 12), 12), 'Sharma', 'Patel', 'Smith', 'Garcia', 'Mehta', 'Johnson',
                                          'Nair', 'Brown', 'Shah', 'Davis', 'Reddy', 'Miller')
       ),
       CONCAT('555-', LPAD(n, 4, '0')),
       CONCAT('customer', n, '@email.com')
FROM seq;

-- Bookings: 60 slots per day (15 tables x 4 time slots). Stepping through the
-- slot index by 7 never repeats a slot and spreads bookings across 2024.
INSERT INTO Bookings (CustomerID, StaffID, TableNumber, BookingDate, BookingTime, GuestCount, Status)
WITH RECURSIVE seq (i) AS (
    SELECT 1 UNION ALL SELECT i + 1 FROM seq WHERE i < 3000
),
slots AS (
    SELECT i, 7 * i AS slot_index FROM seq
)
SELECT 1 + MOD(i * 11, 200),
       ELT(1 + MOD(i, 4), 6, 10, 1, 7),
       t.TableNumber,
       DATE '2024-01-01' + INTERVAL FLOOR(s.slot_index / 60) DAY,
       ELT(1 + FLOOR(MOD(s.slot_index, 60) / 15), '12:00:00', '14:00:00', '18:00:00', '20:00:00'),
       1 + MOD(i, t.Capacity),
       IF(MOD(i, 11) = 0, 'Cancelled', 'Completed')
FROM slots s
JOIN RestaurantTables t ON t.TableNumber = 1 + MOD(s.slot_index, 15);

-- Orders 11..5010, skewed toward lower menu item ids so a few items sell most
INSERT INTO Orders (OrderID, CustomerID, StaffID, OrderDate, Status)
WITH RECURSIVE seq (i) AS (
    SELECT 1 UNION ALL SELECT i + 1 FROM seq WHERE i < 5000
)
SELECT 10 + i,
       1 + MOD(i * 7, 200),
       ELT(1 + MOD(i, 4), 2, 4, 5, 9),
       TIMESTAMP('2024-01-01 11:00:00')
           + INTERVAL MOD(i * 53, 365) DAY
           + INTERVAL (MOD(i, 11) * 60 + MOD(i * 17, 60)) MINUTE,
       IF(MOD(i, 25) = 0, 'Cancelled', 'Delivered')
FROM seq;

INSERT INTO OrderItems (OrderID, MenuItemID, Quantity, UnitPrice)
WITH RECURSIVE seq (i) AS (
    SELECT 1 UNION ALL SELECT i + 1 FROM seq WHERE i < 5000
),
order_lines AS (
    SELECT i,
           k,
           1 + FLOOR(18 * POW(MOD(i * 37, 1000) / 1000, 2)) AS base
    FROM seq
    CROSS JOIN (SELECT 0 AS k UNION ALL SELECT 1 UNION ALL SELECT 2) AS ks
    WHERE k <= MOD(i, 3)
)
SELECT 10 + l.i,
       m.MenuItemID,
       1 + MOD(l.i + l.k, 3),
       m.Price
FROM order_lines l
JOIN MenuItems m ON m.MenuItemID = 1 + MOD(l.base - 1 + l.k * 5, 18);

UPDATE Orders AS o
JOIN (
    SELECT OrderID, SUM(Quantity * UnitPrice) AS Total
    FROM OrderItems
    GROUP BY OrderID
) AS s ON s.OrderID = o.OrderID
SET o.TotalCost = s.Total
WHERE o.OrderID > 10;

-- Status history for the bulk orders
INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate, 'Placed' FROM Orders WHERE OrderID > 10;

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 10 MINUTE, 'Preparing'
FROM Orders WHERE OrderID > 10 AND Status IN ('Preparing', 'Out for delivery', 'Delivered');

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 25 MINUTE, 'Out for delivery'
FROM Orders WHERE OrderID > 10 AND Status IN ('Out for delivery', 'Delivered');

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 40 MINUTE, 'Delivered'
FROM Orders WHERE OrderID > 10 AND Status = 'Delivered';

INSERT INTO OrderDeliveryStatuses (OrderID, StatusDate, Status)
SELECT OrderID, OrderDate + INTERVAL 5 MINUTE, 'Cancelled'
FROM Orders WHERE OrderID > 10 AND Status = 'Cancelled';

ANALYZE TABLE CustomerDetails, Orders, OrderItems, OrderDeliveryStatuses, Bookings;

-- Little Lemon Restaurant Management System
-- Views

USE LittleLemonDB;

-- Orders containing more than two items in total
CREATE OR REPLACE SQL SECURITY INVOKER VIEW OrdersView AS
SELECT o.OrderID,
       SUM(oi.Quantity) AS Quantity,
       o.TotalCost      AS Cost
FROM Orders o
JOIN OrderItems oi ON oi.OrderID = o.OrderID
GROUP BY o.OrderID, o.TotalCost
HAVING SUM(oi.Quantity) > 2;

-- One row per order line with customer, menu item and category
CREATE OR REPLACE SQL SECURITY INVOKER VIEW OrderDetailsView AS
SELECT cd.CustomerID,
       cd.Name        AS FullName,
       o.OrderID,
       o.OrderDate,
       o.Status,
       o.TotalCost    AS Cost,
       mi.Name        AS MenuName,
       mc.Name        AS CourseName,
       oi.Quantity,
       oi.UnitPrice
FROM CustomerDetails cd
JOIN Orders o         ON o.CustomerID   = cd.CustomerID
JOIN OrderItems oi    ON oi.OrderID     = o.OrderID
JOIN MenuItems mi     ON mi.MenuItemID  = oi.MenuItemID
JOIN MenuCategories mc ON mc.CategoryID = mi.CategoryID;

-- Menu items whose total quantity sold is above the average across all items
CREATE OR REPLACE SQL SECURITY INVOKER VIEW PopularMenuItemsView AS
SELECT mi.MenuItemID,
       mi.Name AS MenuName,
       s.TotalQuantity
FROM MenuItems mi
JOIN (
    SELECT oi.MenuItemID, SUM(oi.Quantity) AS TotalQuantity
    FROM OrderItems oi
    JOIN Orders o ON o.OrderID = oi.OrderID
    WHERE o.Status <> 'Cancelled'
    GROUP BY oi.MenuItemID
) s ON s.MenuItemID = mi.MenuItemID
WHERE s.TotalQuantity > (
    SELECT AVG(t.TotalQuantity)
    FROM (
        SELECT SUM(oi.Quantity) AS TotalQuantity
        FROM OrderItems oi
        JOIN Orders o ON o.OrderID = oi.OrderID
        WHERE o.Status <> 'Cancelled'
        GROUP BY oi.MenuItemID
    ) t
);

-- Sales per menu item, excluding cancelled orders
CREATE OR REPLACE SQL SECURITY INVOKER VIEW MenuItemSalesView AS
SELECT mi.MenuItemID,
       mi.Name                          AS MenuName,
       mc.Name                          AS Category,
       cu.Name                          AS Cuisine,
       COALESCE(SUM(oi.Quantity), 0)    AS UnitsSold,
       COALESCE(SUM(oi.Quantity * oi.UnitPrice), 0) AS Revenue
FROM MenuItems mi
JOIN MenuCategories mc ON mc.CategoryID = mi.CategoryID
JOIN Cuisines cu       ON cu.CuisineID  = mi.CuisineID
LEFT JOIN (
    SELECT oi.MenuItemID, oi.Quantity, oi.UnitPrice
    FROM OrderItems oi
    JOIN Orders o ON o.OrderID = oi.OrderID AND o.Status <> 'Cancelled'
) oi ON oi.MenuItemID = mi.MenuItemID
GROUP BY mi.MenuItemID, mi.Name, mc.Name, cu.Name;

-- Revenue and order counts per day, excluding cancelled orders
CREATE OR REPLACE SQL SECURITY INVOKER VIEW DailyRevenueView AS
SELECT DATE(OrderDate)  AS OrderDay,
       COUNT(*)         AS Orders,
       SUM(TotalCost)   AS Revenue
FROM Orders
WHERE Status <> 'Cancelled'
GROUP BY DATE(OrderDate);

-- Confirmed bookings from today onwards
CREATE OR REPLACE SQL SECURITY INVOKER VIEW UpcomingBookingsView AS
SELECT b.BookingID,
       b.BookingDate,
       b.BookingTime,
       b.TableNumber,
       t.Capacity,
       b.GuestCount,
       cd.Name AS CustomerName,
       cd.ContactNumber
FROM Bookings b
JOIN CustomerDetails cd   ON cd.CustomerID  = b.CustomerID
JOIN RestaurantTables t   ON t.TableNumber  = b.TableNumber
WHERE b.Status = 'Confirmed'
  AND b.BookingDate >= CURDATE()
ORDER BY b.BookingDate, b.BookingTime;

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

-- Little Lemon Restaurant Management System
-- Roles and privileges (MySQL 8.0+)
--
-- Create accounts and attach a role, for example:
--   CREATE USER 'asha'@'localhost' IDENTIFIED BY '<password>';
--   GRANT 'll_waiter' TO 'asha'@'localhost';
--   SET DEFAULT ROLE 'll_waiter' TO 'asha'@'localhost';

USE LittleLemonDB;

CREATE ROLE IF NOT EXISTS 'll_manager', 'll_waiter', 'll_analyst';

-- Managers: full data access and every procedure
GRANT SELECT, INSERT, UPDATE, DELETE ON LittleLemonDB.* TO 'll_manager';
GRANT EXECUTE ON LittleLemonDB.* TO 'll_manager';

-- Waiters work through stored procedures and read-only reference data.
-- Procedures run with their definer's rights, so waiters need no write
-- access to the underlying tables and cannot read salaries.
GRANT SELECT ON LittleLemonDB.MenuItems        TO 'll_waiter';
GRANT SELECT ON LittleLemonDB.MenuCategories   TO 'll_waiter';
GRANT SELECT ON LittleLemonDB.Cuisines         TO 'll_waiter';
GRANT SELECT ON LittleLemonDB.RestaurantTables TO 'll_waiter';
GRANT SELECT ON LittleLemonDB.UpcomingBookingsView TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.CheckBooking        TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.GetAvailableTables  TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.AddBooking          TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.UpdateBooking       TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.CancelBooking       TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.PlaceOrder          TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.UpdateOrderStatus   TO 'll_waiter';
GRANT EXECUTE ON PROCEDURE LittleLemonDB.CancelOrder         TO 'll_waiter';

-- Analysts: read-only on sales data, no personal or staff data
GRANT SELECT ON LittleLemonDB.Orders         TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.OrderItems     TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.MenuItems      TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.MenuCategories TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.Cuisines       TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.Bookings       TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.RestaurantTables TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.MenuItemSalesView TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.DailyRevenueView  TO 'll_analyst';
GRANT SELECT ON LittleLemonDB.PopularMenuItemsView TO 'll_analyst';

