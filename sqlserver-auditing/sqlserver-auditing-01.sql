/*
Ravinder mentioned that the current setup is generating 6 to 8GB of data every day, 
which amounts to approximately 250GB per month. 
Over the course of a year, this would result in a total of around 2 to 3 terabytes of data
*/

-- Ensure that the folder "C:\Temp\HPAuditLogs\" exists and SQL Server’s service account has full control.
-- Create a server audit that writes to disk.

USE [master]; 
GO

CREATE SERVER AUDIT [SQLServerInstance01_Audit_01]
TO FILE 
(
    FILEPATH = 'C:\Temp\HPAuditLogs\', 
    MAXSIZE = 1024 MB,        -- maximum size per audit file
    MAX_FILES = 3120,         -- how many files to cycle through
    RESERVE_DISK_SPACE = OFF
)
WITH
(
    QUEUE_DELAY = 1000,     -- delay in milliseconds before writing events to disk
    ON_FAILURE = CONTINUE   -- if audit fails, continue the session
)
WHERE session_server_principal_name <> 'HP\user1' and schema_name <> 'sys';
GO

-- Enable the server audit.
ALTER SERVER AUDIT [SQLServerInstance01_Audit_01] WITH (STATE = ON);
GO

-- Create the server audit specification.
CREATE SERVER AUDIT SPECIFICATION [SQLServerInstance01_AuditSpec_01]
FOR SERVER AUDIT [SQLServerInstance01_Audit_01]
	-- Capture DDL changes (e.g., CREATE, ALTER, DROP statements)
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),
    -- Capture DML operations (e.g., SELECT, INSERT, UPDATE, DELETE)
    ADD (SCHEMA_OBJECT_ACCESS_GROUP)
WITH (STATE = ON);
GO


-- Now create a database audit specification.
USE [AdventureWorks2019];  -- Replace with the actual database name.
GO


-- Create the database audit specification.
CREATE DATABASE AUDIT SPECIFICATION [AdventureWorks_Audit_01]
FOR SERVER AUDIT [SQLServerInstance01_Audit_01]
	-- Capture DDL changes (e.g., CREATE, ALTER, DROP statements)
    ADD (SCHEMA_OBJECT_CHANGE_GROUP),
    -- Capture DML operations (e.g., SELECT, INSERT, UPDATE, DELETE)
	ADD (SCHEMA_OBJECT_ACCESS_GROUP)
    --ADD (SELECT, INSERT, UPDATE, DELETE ON SCHEMA::Sales BY PUBLIC)
WITH (STATE = ON);
GO

---------------------------------------------------------------------

SELECT *
FROM Person.Address;

SELECT 
    AddressID,
    AddressLine1,
    ISNULL(AddressLine2, '') AS AddressLine2,
    City,
    PostalCode,
    CONCAT(AddressLine1, ' ', ISNULL(AddressLine2, '')) AS FullAddress
FROM Person.Address;

SELECT *
FROM Sales.Customer;


UPDATE Person.Address
SET City = UPPER(City);


-- DDL Test – Drop a table
DROP TABLE [Sales].[AuditTestTable];
GO

-- Test DDL on a table in a non-dbo schema:
CREATE TABLE [Sales].[AuditTestTable] (ID INT PRIMARY KEY);
GO
ALTER TABLE [Sales].[AuditTestTable] ADD NewColumn INT;
GO

-- Test DML on that table:
INSERT INTO [Sales].[AuditTestTable] (ID) VALUES (2);
GO
UPDATE [Sales].[AuditTestTable] SET NewColumn = 120 WHERE ID = 2;
GO

ALTER TABLE Sales.AuditTestTable
ADD ThirdColumn VARCHAR(100) NOT NULL CONSTRAINT DF_AuditTestTable_ThirdColumn DEFAULT ('DefaultValue');
GO


-- Example: Get audit events from the past 30 days
SELECT event_time, action_id, succeeded, session_id, session_server_principal_name, server_instance_name, database_name, schema_name, object_id, object_name, statement, additional_information, file_name, client_ip, application_name
FROM sys.fn_get_audit_file('C:\Temp\HPAuditLogs\\*.sqlaudit', DEFAULT, DEFAULT)
WHERE event_time > DATEADD(DAY, -30, GETDATE())
ORDER BY event_time DESC;
GO


-- Example: Get audit events from the past 30 days and Object Name filter
SELECT event_time, action_id, succeeded, session_id, session_server_principal_name, server_instance_name, database_name, schema_name, object_id, object_name, statement, additional_information, file_name, client_ip, application_name
FROM sys.fn_get_audit_file('C:\Temp\HPAuditLogs\\*.sqlaudit', DEFAULT, DEFAULT)
WHERE event_time > DATEADD(DAY, -30, GETDATE())
AND object_name = 'Customer'
ORDER BY event_time DESC;
GO

