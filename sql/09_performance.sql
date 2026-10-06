-- Little Lemon Restaurant Management System
-- Index effectiveness check with EXPLAIN
-- Run after the bulk data is loaded. An index is made invisible to see the
-- plan the optimizer would choose without it, then visible again.

USE LittleLemonDB;

ANALYZE TABLE Orders, OrderItems, Bookings;

-- Query 1: orders in a date range
ALTER TABLE Orders ALTER INDEX idx_Orders_OrderDate INVISIBLE;
ALTER TABLE Orders ALTER INDEX idx_Orders_Customer_Date INVISIBLE;
EXPLAIN FORMAT = TREE
SELECT OrderID, TotalCost
FROM Orders
WHERE OrderDate >= '2024-03-01' AND OrderDate < '2024-03-08';

ALTER TABLE Orders ALTER INDEX idx_Orders_OrderDate VISIBLE;
EXPLAIN FORMAT = TREE
SELECT OrderID, TotalCost
FROM Orders
WHERE OrderDate >= '2024-03-01' AND OrderDate < '2024-03-08';

-- Query 2: order history of one customer
EXPLAIN FORMAT = TREE
SELECT OrderID, OrderDate, TotalCost
FROM Orders
WHERE CustomerID = 42
ORDER BY OrderDate DESC;

ALTER TABLE Orders ALTER INDEX idx_Orders_Customer_Date VISIBLE;
EXPLAIN FORMAT = TREE
SELECT OrderID, OrderDate, TotalCost
FROM Orders
WHERE CustomerID = 42
ORDER BY OrderDate DESC;

-- Query 3: double-booking check uses the unique slot key
EXPLAIN FORMAT = TREE
SELECT 1
FROM Bookings
WHERE TableNumber = 5
  AND BookingDate = '2024-06-15'
  AND BookingTime = '18:00:00';
