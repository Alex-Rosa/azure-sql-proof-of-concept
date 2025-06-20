-- INSERT Script to run in SSMS

-- This command will attempt to insert a new row that falls
-- within the range read by the C# application.
-- Because the C# app is using a SERIALIZABLE transaction,
-- this INSERT will be BLOCKED until that transaction completes.

PRINT 'Attempting to INSERT a new "Spanner"...';

INSERT INTO dbo.Widgets (WidgetName, Quantity)
VALUES ('Mini Spanner', 150);

PRINT 'INSERT completed successfully!';