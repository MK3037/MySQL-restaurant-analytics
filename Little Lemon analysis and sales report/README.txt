Little Lemon Analysis and Sales Report

Files
- Little Lemon Analysis and Sales Report.ipynb : the executed Jupyter notebook (outputs included)
- README.txt : this file

How to run
1. Install Python, MySQL Server 8.x and: pip install mysql-connector-python notebook
2. Make sure a MySQL server is running on the host and port in notes.txt, and that the user in notes.txt exists
   with privileges to create a database (CREATE USER ... ; GRANT ALL ON *.* TO ...).
3. Open the notebook in Jupyter and run all cells from the top.

What the notebook does
Task 1  Creates connection pool pool_a with 2 connections.
Task 2  Creates database little_lemon_db with tables Employees, MenuItems, Bookings, Orders and populates them (committed).
Task 3  Creates stored procedures GetBookingsWithStaff, AddBooking, UpdateBookingSlot, CancelBooking, SalesByItem, SalesByCategory.
Task 4  Lists bookings with the assigned staff member (calls GetBookingsWithStaff).
Task 5  Adds, updates and cancels a booking (calls the stored procedures, commits each change).
Task 6  Sales report by menu item and by category (calls SalesByItem and SalesByCategory).
Task 7  Confirms committed data is visible from a new pooled connection and that both pooled connections are free again.

Every task takes its connection from pool_a, prints progress messages, commits its changes and closes the connection
(which returns it to the pool).
