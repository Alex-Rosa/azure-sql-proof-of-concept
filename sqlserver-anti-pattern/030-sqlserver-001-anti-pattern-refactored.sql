/*
Correct Pattern: Proper Use of Parameterized Dynamic SQL
This stored procedure uses sp_executesql to safely execute parameterized dynamic SQL, improving security and performance.

Benefits: Prevents SQL Injection: Parameters are safely passed, neutralizing harmful input.
Example: Passing john@example.com' OR 1=1 -- is treated as a single string value, not executable SQL.

Efficient Plan Reuse: SQL Server caches and reuses execution plans, reducing unnecessary recompilations.

Improved Performance: The query operates in a safer and faster manner without bloating the plan cache.
*/
CREATE PROCEDURE dbo.GetCustomerByEmailAntiPatternRefactored
    @Email NVARCHAR(50)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @EmailParam NVARCHAR(50);

    -- Dynamic SQL construction with parameter placeholders
    SET @SQL = 'SELECT CustomerID, FirstName, LastName, EmailAddress ' +
               'FROM SalesLT.Customer ' +
               'WHERE EmailAddress = @EmailParam';

    -- Execution of parameterized dynamic SQL using sp_executesql
    EXEC sp_executesql @SQL,
                       N'@EmailParam NVARCHAR(50)',
                       @EmailParam = @Email;
END;