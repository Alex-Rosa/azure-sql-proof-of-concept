-- Scenario 1: The Non-Repeatable Read (READ COMMITTED Default)
-- STEP 2
-- Update the quantity and commit the change
UPDATE dbo.Widgets
SET Quantity = 45
WHERE WidgetName = 'Hyper Spanner';


-- Scenario 2: The Dirty Read (READ UNCOMMITTED / NOLOCK)
-- STEP 1
-- Start a transaction and update the data
BEGIN TRANSACTION;
UPDATE dbo.Widgets
SET Quantity = 999
WHERE WidgetName = 'Flux Capacitor';

-- Wait for 15 seconds before rolling back
WAITFOR DELAY '00:00:15';

-- The change is undone!
ROLLBACK TRANSACTION;


-- Scenario 3: The Phantom Read (REPEATABLE READ)
-- STEP 2
-- Insert a new row that matches the filter in Connection 1
INSERT INTO dbo.Widgets (WidgetName, Quantity)
VALUES ('Nano Spanner', 200);


-- Scenario 4: Reader/Writer Blocking (READ COMMITTED) vs. READ COMMITTED SNAPSHOT (RCSI)
-- Part A: The Blocking Problem
-- STEP 1
BEGIN TRANSACTION;
UPDATE dbo.Widgets 
SET Quantity = 99 
WHERE WidgetName = 'Standard Gear';
-- Hold the lock for 15 seconds
WAITFOR DELAY '00:00:15';
COMMIT TRANSACTION;


-- Part B: The RCSI Solution
-- STEP 1
BEGIN TRANSACTION;
UPDATE dbo.Widgets 
SET Quantity = 101 
WHERE WidgetName = 'Standard Gear';
-- Hold the lock for 15 seconds
WAITFOR DELAY '00:00:15';
COMMIT TRANSACTION;

