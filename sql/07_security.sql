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
