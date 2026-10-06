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
