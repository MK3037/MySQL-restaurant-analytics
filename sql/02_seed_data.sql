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
