-- Little Lemon Restaurant Management System
-- Analytical queries using CTEs and window functions
-- Cancelled orders and bookings are excluded from every figure.

USE LittleLemonDB;

-- 1. Monthly revenue, change on the previous month and running total
WITH monthly AS (
    SELECT DATE_FORMAT(OrderDate, '%Y-%m') AS Month,
           COUNT(*)                        AS Orders,
           SUM(TotalCost)                  AS Revenue
    FROM Orders
    WHERE Status <> 'Cancelled'
    GROUP BY DATE_FORMAT(OrderDate, '%Y-%m')
)
SELECT Month,
       Orders,
       Revenue,
       ROUND(100 * (Revenue - LAG(Revenue) OVER (ORDER BY Month))
                 / LAG(Revenue) OVER (ORDER BY Month), 1) AS GrowthPct,
       SUM(Revenue) OVER (ORDER BY Month)                  AS RunningRevenue
FROM monthly
ORDER BY Month;

-- 2. Top 10 customers by spend with spend quartile across all customers
WITH spend AS (
    SELECT cd.CustomerID,
           cd.Name,
           COUNT(o.OrderID)  AS Orders,
           SUM(o.TotalCost)  AS TotalSpent
    FROM CustomerDetails cd
    JOIN Orders o ON o.CustomerID = cd.CustomerID AND o.Status <> 'Cancelled'
    GROUP BY cd.CustomerID, cd.Name
),
ranked AS (
    SELECT s.*,
           RANK()   OVER (ORDER BY TotalSpent DESC) AS SpendRank,
           NTILE(4) OVER (ORDER BY TotalSpent DESC) AS Quartile
    FROM spend s
)
SELECT SpendRank, CustomerID, Name, Orders, TotalSpent, Quartile
FROM ranked
WHERE SpendRank <= 10
ORDER BY SpendRank;

-- 3. Best three sellers in each menu category
WITH item_sales AS (
    SELECT mc.Name AS Category,
           mi.Name AS MenuName,
           SUM(oi.Quantity)                AS UnitsSold,
           SUM(oi.Quantity * oi.UnitPrice) AS Revenue
    FROM OrderItems oi
    JOIN Orders o          ON o.OrderID = oi.OrderID AND o.Status <> 'Cancelled'
    JOIN MenuItems mi      ON mi.MenuItemID = oi.MenuItemID
    JOIN MenuCategories mc ON mc.CategoryID = mi.CategoryID
    GROUP BY mc.Name, mi.Name
),
ranked AS (
    SELECT item_sales.*,
           DENSE_RANK() OVER (PARTITION BY Category ORDER BY UnitsSold DESC) AS CategoryRank
    FROM item_sales
)
SELECT Category, CategoryRank, MenuName, UnitsSold, Revenue
FROM ranked
WHERE CategoryRank <= 3
ORDER BY Category, CategoryRank;

-- 4. Share of revenue by cuisine
SELECT cu.Name AS Cuisine,
       SUM(oi.Quantity * oi.UnitPrice) AS Revenue,
       ROUND(100 * SUM(oi.Quantity * oi.UnitPrice)
                 / SUM(SUM(oi.Quantity * oi.UnitPrice)) OVER (), 1) AS SharePct
FROM OrderItems oi
JOIN Orders o     ON o.OrderID = oi.OrderID AND o.Status <> 'Cancelled'
JOIN MenuItems mi ON mi.MenuItemID = oi.MenuItemID
JOIN Cuisines cu  ON cu.CuisineID = mi.CuisineID
GROUP BY cu.Name
ORDER BY Revenue DESC;

-- 5. Staff ranked by revenue from the orders they took
SELECT RANK() OVER (ORDER BY SUM(o.TotalCost) DESC) AS RevenueRank,
       s.StaffID,
       s.Name,
       s.Role,
       COUNT(*)           AS Orders,
       SUM(o.TotalCost)   AS Revenue,
       ROUND(AVG(o.TotalCost), 2) AS AvgOrderValue
FROM StaffInformation s
JOIN Orders o ON o.StaffID = s.StaffID AND o.Status <> 'Cancelled'
GROUP BY s.StaffID, s.Name, s.Role
ORDER BY RevenueRank;

-- 6. Repeat customers: share of customers who ordered more than once
WITH per_customer AS (
    SELECT CustomerID, COUNT(*) AS Orders
    FROM Orders
    WHERE Status <> 'Cancelled'
    GROUP BY CustomerID
)
SELECT COUNT(*)                                         AS Customers,
       SUM(Orders > 1)                                  AS RepeatCustomers,
       ROUND(100 * SUM(Orders > 1) / COUNT(*), 1)       AS RepeatPct
FROM per_customer;

-- 7. Days between a customer's consecutive orders (average per customer, top 10)
WITH gaps AS (
    SELECT CustomerID,
           DATEDIFF(OrderDate,
                    LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate)) AS DaysSincePrevious
    FROM Orders
    WHERE Status <> 'Cancelled'
)
SELECT CustomerID, ROUND(AVG(DaysSincePrevious), 1) AS AvgDaysBetweenOrders
FROM gaps
WHERE DaysSincePrevious IS NOT NULL
GROUP BY CustomerID
ORDER BY AvgDaysBetweenOrders
LIMIT 10;

-- 8. Table utilisation: share of available slots that were used, per table
--    (four slots per table per day over the booking period)
WITH period AS (
    SELECT DATEDIFF(MAX(BookingDate), MIN(BookingDate)) + 1 AS Days
    FROM Bookings
    WHERE BookingDate >= '2024-01-01' AND BookingDate < '2025-01-01'
)
SELECT t.TableNumber,
       t.Capacity,
       COUNT(b.BookingID) AS Bookings,
       ROUND(100 * COUNT(b.BookingID) / (p.Days * 4), 1) AS UtilisationPct
FROM RestaurantTables t
CROSS JOIN period p
LEFT JOIN Bookings b
       ON b.TableNumber = t.TableNumber
      AND b.Status <> 'Cancelled'
      AND b.BookingDate >= '2024-01-01' AND b.BookingDate < '2025-01-01'
GROUP BY t.TableNumber, t.Capacity, p.Days
ORDER BY UtilisationPct DESC;

-- 9. Busiest day of week by revenue
SELECT DAYNAME(OrderDate) AS DayOfWeek,
       COUNT(*)           AS Orders,
       ROUND(SUM(TotalCost), 2) AS Revenue
FROM Orders
WHERE Status <> 'Cancelled'
GROUP BY DAYOFWEEK(OrderDate), DAYNAME(OrderDate)
ORDER BY DAYOFWEEK(OrderDate);

-- 10. Cancellation rate for orders and bookings
SELECT 'Orders' AS Entity,
       COUNT(*) AS Total,
       SUM(Status = 'Cancelled') AS Cancelled,
       ROUND(100 * SUM(Status = 'Cancelled') / COUNT(*), 1) AS CancelledPct
FROM Orders
UNION ALL
SELECT 'Bookings',
       COUNT(*),
       SUM(Status = 'Cancelled'),
       ROUND(100 * SUM(Status = 'Cancelled') / COUNT(*), 1)
FROM Bookings;
