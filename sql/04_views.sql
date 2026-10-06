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
