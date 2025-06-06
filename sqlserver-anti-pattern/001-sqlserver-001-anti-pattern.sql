/*
Anti-Pattern: Inappropriate Use of Dynamic SQL
This stored procedure creates a SELECT query for the SalesLT.Customer table by concatenating string values directly, 
which exposes the system to SQL injection risks and leads to poor plan cache management.

Issues: SQL Injection Vulnerability: Malicious input for @Email can compromise the database.
Example: Passing john@example.com' OR 1=1 -- would return all rows.

Plan Cache Bloat: Each variation in @Email leads to a new query plan being compiled and stored.

Performance Impact: Repeated recompilations degrade server efficiency.
*/
CREATE PROCEDURE dbo.GetCustomerByEmailAntiPattern
    @Email NVARCHAR(50)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);

    -- Dynamic SQL construction with direct concatenation (anti-pattern)
    SET @SQL = 'SELECT CustomerID, FirstName, LastName, EmailAddress ' +
               'FROM SalesLT.Customer ' +
               'WHERE EmailAddress = ''' + @Email + '''';

    -- Execution of unparameterized dynamic SQL
    EXEC(@SQL);
END;