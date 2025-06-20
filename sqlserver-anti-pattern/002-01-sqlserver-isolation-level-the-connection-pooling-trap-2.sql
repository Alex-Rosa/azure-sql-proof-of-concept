-- Blocking Script to run in SSMS
-- This will hold an exclusive lock on the table, preventing
-- any SERIALIZABLE transaction from reading it.

BEGIN TRANSACTION;

-- Place an exclusive lock on a row.
UPDATE dbo.Widgets
SET Quantity = Quantity + 1
WHERE WidgetID = 1;

-- !! DO NOT COMMIT YET !!
-- Hold the transaction open for 60 seconds to block the C# app
WAITFOR DELAY '00:01:00';

-- The transaction will be rolled back after the wait.
ROLLBACK TRANSACTION;

PRINT 'Transaction rolled back. Lock released.';