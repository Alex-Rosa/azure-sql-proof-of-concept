-- Scenario 1: The Non-Repeatable Read (READ COMMITTED Default)
-- STEP 1
-- Start a transaction
BEGIN TRANSACTION;

-- 1. First read
SELECT * FROM dbo.Widgets WHERE WidgetName = 'Hyper Spanner';

-- Wait for 10 seconds, giving Connection 2 time to act
WAITFOR DELAY '00:00:10';

-- 2. Second read
SELECT * FROM dbo.Widgets WHERE WidgetName = 'Hyper Spanner';

-- Commit the transaction
COMMIT TRANSACTION;


-- Scenario 2: The Dirty Read (READ UNCOMMITTED / NOLOCK)
-- STEP 2
-- This query will not wait and will read the uncommitted data
SELECT * 
FROM dbo.Widgets WITH (NOLOCK) 
WHERE WidgetName = 'Flux Capacitor';

-- STEP 3
-- Now read the actual, committed data
SELECT * 
FROM dbo.Widgets
WHERE WidgetName = 'Flux Capacitor';


-- Scenario 3: The Phantom Read (REPEATABLE READ)
-- STEP 1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
-- 1. First read, finds one row
SELECT * 
FROM dbo.Widgets 
WHERE WidgetName LIKE '%Spanner%';
-- Wait for 10 seconds
WAITFOR DELAY '00:00:10';
-- 2. Second read, will it find the same number of rows?
SELECT * 
FROM dbo.Widgets 
WHERE WidgetName LIKE '%Spanner%';
COMMIT TRANSACTION;


-- Scenario 4: Reader/Writer Blocking (READ COMMITTED) vs. READ COMMITTED SNAPSHOT (RCSI)
-- Part A: The Blocking Problem
-- STEP 2
-- This query will be BLOCKED until Connection 2 commits
SELECT * 
FROM dbo.Widgets


-- Part B: The RCSI Solution
MASTER Database

SELECT * FROM sys.databases;

ALTER DATABASE [YourDatabaseName] SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE [YourDatabaseName] SET READ_COMMITTED_SNAPSHOT ON;
GO

-- STEP 2
-- This query will now run INSTANTLY!
SELECT * 
FROM dbo.Widgets;


-- Cleanup Script
USER Database
DROP TABLE dbo.Widgets;
GO

MASTER Database
-- Disable RCSI
ALTER DATABASE [YourDatabaseName] SET READ_COMMITTED_SNAPSHOT OFF;
ALTER DATABASE [YourDatabaseName] SET ALLOW_SNAPSHOT_ISOLATION OFF;
GO

