DBCC FREEPROCCACHE WITH NO_INFOMSGS;
-- Anti-Pattern

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

/*
Script to Simulate the Malicious Input

Explanation of the Malicious Input:
'john@example.com' is the beginning of a normal email address.

'' escapes the single quote, effectively closing the string.

OR 1=1 introduces a condition that always evaluates as true, potentially exposing all rows in the SalesLT.Customer table.

-- is a SQL comment marker, which ignores the rest of the query that SQL Server would have executed, thus ending the query prematurely.

Potential Impact:
Running this with the anti-pattern procedure can return all rows from the SalesLT.Customer table because the WHERE EmailAddress = @Email clause becomes:

sql
WHERE EmailAddress = 'john@example.com' OR 1=1;

*/
EXEC dbo.GetCustomerByEmailCorrectPattern
    @Email = 'orlando0@adventure-works.com';

EXEC dbo.GetCustomerByEmailAntiPattern
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
    EXEC dbo.GetCustomerByEmailAntiPattern @Email;

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
Anti-Pattern: Vulnerable to Parameter Sniffing
This procedure retrieves customers from the SalesLT.Customer table based on their CompanyName. 
SQL Server may create an execution plan optimized for the first execution with specific parameter values, which could perform poorly for subsequent executions with different parameter sets.

Issues: Execution Plan Dependency: The query plan is created based on the first @CompanyName value encountered, which may not be optimal for other values.

Example: If the initial @CompanyName returns many rows, the plan may use a clustered index scan. For a later execution that returns only a few rows, a seek would have been preferable.

Unpredictable Response Times: Subsequent executions with different @CompanyName values may experience degraded performance.
*/
CREATE PROCEDURE dbo.GetCustomersByCompanyAntiPattern
    @CompanyName NVARCHAR(128)
AS
BEGIN
    -- Parameter used directly in the query, leading to potential parameter sniffing issues
    SELECT CustomerID, FirstName, LastName, CompanyName, EmailAddress
    FROM SalesLT.Customer
    WHERE CompanyName = @CompanyName;
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
EXEC dbo.GetCustomersByCompanyAntiPattern
    @CompanyName = 'Friendly Bike Shop';

-- Low Cardinality
EXEC dbo.GetCustomersByCompanyAntiPattern
    @CompanyName = 'Global Sporting Goods';

