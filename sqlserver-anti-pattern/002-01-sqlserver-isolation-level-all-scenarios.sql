-- Drop the table if it already exists to ensure a clean start
IF OBJECT_ID('dbo.Widgets', 'U') IS NOT NULL
    DROP TABLE dbo.Widgets;
GO

-- Create a simple table for our demos
CREATE TABLE dbo.Widgets (
    WidgetID INT PRIMARY KEY IDENTITY,
    WidgetName VARCHAR(100),
    Quantity INT,
    LastUpdated DATETIME DEFAULT GETDATE()
);
GO

-- Insert some baseline data
INSERT INTO dbo.Widgets (WidgetName, Quantity)
VALUES ('Standard Gear', 100),
       ('Flux Capacitor', 10),
       ('Hyper Spanner', 50),
       ('Sonic Screwdriver', 1);
GO