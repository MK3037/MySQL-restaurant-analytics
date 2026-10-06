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
