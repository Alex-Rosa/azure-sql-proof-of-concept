DBCC FREEPROCCACHE WITH NO_INFOMSGS;
-- Correct Pattern

/*
Correct Pattern: Proper Use of Parameterized Dynamic SQL
This stored procedure uses sp_executesql to safely execute parameterized dynamic SQL, improving security and performance.

Benefits: Prevents SQL Injection: Parameters are safely passed, neutralizing harmful input.
Example: Passing john@example.com' OR 1=1 -- is treated as a single string value, not executable SQL.

Efficient Plan Reuse: SQL Server caches and reuses execution plans, reducing unnecessary recompilations.

Improved Performance: The query operates in a safer and faster manner without bloating the plan cache.
*/
CREATE PROCEDURE dbo.GetCustomerByEmailCorrectPattern
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

-- Proof of Concept
EXEC dbo.GetCustomerByEmailCorrectPattern
    @Email = 'orlando0@adventure-works.com';

EXEC dbo.GetCustomerByEmailCorrectPattern
    @Email = 'orlando0@adventure-works.com'' OR 1=1 --';


/*
Script to Simulate Plan Cache Bloat
Here's a script that retrieves email addresses from the SalesLT.Customer table and iteratively calls the dbo.GetCustomerByEmailAntiPattern procedure with each email as a parameter. 
This demonstrates how excessive use of non-parameterized dynamic SQL can lead to Plan Cache Bloat, as SQL Server will generate a new execution plan for each distinct email:

*/
-- Declare a cursor to loop through the email addresses
DECLARE EmailCursor CURSOR FOR
SELECT EmailAddress
FROM SalesLT.Customer
WHERE EmailAddress IS NOT NULL;

-- Variable to hold each email address
DECLARE @Email NVARCHAR(50);

-- Open the cursor
OPEN EmailCursor;

-- Fetch the first email
FETCH NEXT FROM EmailCursor INTO @Email;

-- Loop through all email addresses
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Call the stored procedure with the current email
    EXEC dbo.GetCustomerByEmailCorrectPattern @Email;

    -- Fetch the next email
    FETCH NEXT FROM EmailCursor INTO @Email;
END;

-- Close and deallocate the cursor
CLOSE EmailCursor;
DEALLOCATE EmailCursor;

/*
Explanation of the Script:
Cursor Setup:
The EmailCursor retrieves all valid EmailAddress values from the SalesLT.Customer table.
A cursor is used to iterate through each email address one at a time.

Procedure Execution:
For each email address, the anti-pattern procedure dbo.GetCustomerByEmailAntiPattern is executed.
Since this procedure uses unparameterized dynamic SQL, a new query plan is generated and added to the plan cache for each unique email address.

Impact:
If the table contains many email addresses, the plan cache will fill up with ad hoc plans—one for each email—creating Plan Cache Bloat.
This degrades server performance by consuming memory and forcing SQL Server to compile new plans repeatedly.

Cursor Management:
The cursor is properly closed and deallocated to ensure no resources are left hanging.

How to Observe the Cache Bloat:
To monitor the plan cache behavior, you can query the plan cache and look for ad hoc query plans:
*/

-- Count the number of ad hoc query plans in the plan cache
SELECT 
    COUNT(*) AS AdHocPlanCount
FROM sys.dm_exec_cached_plans
WHERE objtype = 'Adhoc';

-- Retrieve sample ad hoc plans related to the stored procedure
SELECT 
    cp.plan_handle, 
    cp.cacheobjtype, 
    cp.objtype, 
    st.text AS QueryText
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE st.text LIKE '%FROM SalesLT.Customer%'
AND cp.objtype = 'Adhoc';


/*
Correct Pattern: Mitigating Parameter Sniffing
This procedure addresses the parameter sniffing issue by copying the input parameter into a local variable. 
SQL Server optimizes the query plan generically rather than for specific parameter values.

Benefits: Generic Execution Plan: SQL Server generates a plan that works well across a variety of @CompanyName values, reducing performance disparities.

Consistent Response Times: The query executes efficiently regardless of the distribution of data for the specific parameter values.
*/
CREATE PROCEDURE dbo.GetCustomersByCompanyCorrectPattern
    @CompanyName NVARCHAR(128)
AS
BEGIN
    -- Declare a local variable and assign the input parameter to it
    DECLARE @LocalCompanyName NVARCHAR(128) = @CompanyName;

    -- Use the local variable in the query to mitigate parameter sniffing
    SELECT CustomerID, FirstName, LastName, CompanyName, EmailAddress
    FROM SalesLT.Customer
    WHERE CompanyName = @LocalCompanyName;
END;

/*
Alternative: Using Query Hints
In some cases, query hints like OPTION (RECOMPILE) or OPTIMIZE FOR can be used to further mitigate parameter sniffing issues. 
For example:
*/
CREATE PROCEDURE dbo.GetCustomersByCompanyWithHints
    @CompanyName NVARCHAR(128)
AS
BEGIN
    -- OPTION (RECOMPILE) forces SQL Server to compile a new plan for each execution
    SELECT CustomerID, FirstName, LastName, CompanyName, EmailAddress
    FROM SalesLT.Customer
    WHERE CompanyName = @CompanyName
    OPTION (RECOMPILE);

    -- OPTION (OPTIMIZE FOR) can be used to explicitly optimize for a specific parameter value
    -- Uncomment the query below to use OPTIMIZE FOR
    /*
    SELECT CustomerID, FirstName, LastName, CompanyName, EmailAddress
    FROM SalesLT.Customer
    WHERE CompanyName = @CompanyName
    OPTION (OPTIMIZE FOR (@CompanyName = 'ExampleCompany'));
    */
END;

/*
Practical Example: How to Test and Observe
You can test these procedures by passing parameter values that represent different scenarios:

High Cardinality Case: A @CompanyName value that matches many rows.

Low Cardinality Case: A @CompanyName value that matches few rows.

To observe execution plans:

Use SQL Server Management Studio to check query execution plans before and after applying best practices.

Run SET STATISTICS TIME ON; and SET STATISTICS IO ON; to monitor CPU and I/O usage.

Here’s a SQL query to help you identify CompanyName values for both High Cardinality (many matching rows) and Low Cardinality (few matching rows):
*/
-- Query to identify CompanyName values with row counts
SELECT CompanyName,
       COUNT(*) AS NumberOfCustomers
FROM SalesLT.Customer
WHERE CompanyName IS NOT NULL
GROUP BY CompanyName
ORDER BY NumberOfCustomers DESC;

/*
Explanation:
COUNT(*) AS NumberOfCustomers: Counts how many rows correspond to each unique CompanyName.

WHERE CompanyName IS NOT NULL: Filters out rows where CompanyName is null to focus only on valid entries.

GROUP BY CompanyName: Groups rows by CompanyName to compute the count per company name.

ORDER BY NumberOfCustomers DESC: Sorts the results in descending order so that high cardinality values appear first (with the most rows).

Steps to Identify Values:
High Cardinality Case:

Look at the top rows of the output. These companies have the highest NumberOfCustomers and represent high cardinality scenarios.

Low Cardinality Case:

Look at the bottom rows of the output. These companies have the lowest NumberOfCustomers (possibly even just one) and represent low cardinality scenarios.

You can choose CompanyName values from the results to test scenarios such as high-cardinality performance issues or low-cardinality inefficiencies in stored procedures.
*/

-- High Cardinality
EXEC dbo.GetCustomersByCompanyCorrectPattern
    @CompanyName = 'Friendly Bike Shop';

-- Low Cardinality
EXEC dbo.GetCustomersByCompanyCorrectPattern
    @CompanyName = 'Global Sporting Goods';

