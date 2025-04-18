/*
This query intentionally generates a massive Cartesian product from several SalesLT tables
and then forces a full sort using ORDER BY NEWID(), which is a non-SARGable operation.
Both factors combine to create high CPU consumption.

How this works:
Multiple CROSS JOINs: Each CROSS JOIN multiplies the number of rows. For example, if each table holds 1,000 rows, you’re looking at 1,000⁵ (i.e. 10¹⁵) rows in total. (Even if the tables are smaller, the effect can be dramatic on larger datasets.)
ORDER BY NEWID(): Sorting on a function call like NEWID() forces the server to generate a completely new random value per row. This both prevents index use and requires a full sort of the entire result set, which is very CPU intensive.

Caution: Although this query may help in testing CPU load or stressing the SQL Server engine during performance tests, 
do not run it in production environments unless you fully understand the impact it could have on system resources.
*/
SELECT
    a.AddressID,
    c.CustomerID,
    p.ProductID,
    so.SalesOrderID,
    sod.SalesOrderDetailID,
    NEWID() AS RandomValue
FROM SalesLT.Address AS a
CROSS JOIN SalesLT.Customer AS c
CROSS JOIN SalesLT.Product AS p
CROSS JOIN SalesLT.SalesOrderHeader AS so
CROSS JOIN SalesLT.SalesOrderDetail AS sod
ORDER BY NEWID();


/*
Below is a set of sample T‑SQL SELECT statements—each crafted to access one of the SalesLT tables in a different way. These examples illustrate a variety of query operations such as full table scans, filtering, computed columns, ordering, joins, aggregation, and even XML value extraction. You can use these as starting points and adjust them for your particular testing or learning purposes.
*/
SELECT *
FROM SalesLT.Address;

SELECT TOP 10 
    AddressID,
    AddressLine1,
    City,
    PostalCode,
    ModifiedDate
FROM SalesLT.Address
WHERE PostalCode LIKE '750%'
ORDER BY ModifiedDate DESC;

SELECT 
    AddressID,
    AddressLine1,
    ISNULL(AddressLine2, '') AS AddressLine2,
    City,
    PostalCode,
    CONCAT(AddressLine1, ' ', ISNULL(AddressLine2, '')) AS FullAddress
FROM SalesLT.Address;

SELECT 
    AddressID,
    AddressLine1,
    ISNULL(AddressLine2, '') AS AddressLine2,
    City,
    PostalCode,
    CONCAT(AddressLine1, ' ', ISNULL(AddressLine2, '')) AS FullAddress
FROM SalesLT.Address;


SELECT *
FROM SalesLT.Customer;

SELECT 
    CustomerID,
    FirstName + ' ' + LastName AS FullName,
    EmailAddress,
    ModifiedDate
FROM SalesLT.Customer
WHERE EmailAddress IS NOT NULL;

SELECT TOP 5
    CustomerID,
    FirstName,
    LastName,
    CompanyName,
    ModifiedDate
FROM SalesLT.Customer
ORDER BY ModifiedDate DESC;

SELECT *
FROM SalesLT.CustomerAddress;

SELECT 
    ca.CustomerID,
    ca.AddressType,
    a.AddressLine1,
    a.City,
    a.PostalCode
FROM SalesLT.CustomerAddress ca
JOIN SalesLT.Address a ON ca.AddressID = a.AddressID;

SELECT 
    AddressType, 
    COUNT(*) AS AddressCount
FROM SalesLT.CustomerAddress
GROUP BY AddressType;

SELECT *
FROM SalesLT.Product;

SELECT 
    ProductID,
    Name,
    ListPrice,
    StandardCost,
    ListPrice - StandardCost AS Margin
FROM SalesLT.Product
WHERE Color IS NOT NULL;

SELECT TOP 10 
    ProductID,
    Name,
    ListPrice,
    ModifiedDate
FROM SalesLT.Product
ORDER BY ModifiedDate DESC;

SELECT TOP 10 
    ProductID,
    Name,
    ListPrice,
    ModifiedDate
FROM SalesLT.Product
ORDER BY ModifiedDate DESC;

SELECT 
    pc.ProductCategoryID,
    pc.Name AS CategoryName,
    ppc.Name AS ParentCategoryName
FROM SalesLT.ProductCategory pc
LEFT JOIN SalesLT.ProductCategory ppc 
    ON pc.ParentProductCategoryID = ppc.ProductCategoryID;

SELECT 
    ProductCategoryID,
    Name,
    ModifiedDate
FROM SalesLT.ProductCategory
WHERE Name LIKE 'B%'
ORDER BY ModifiedDate;

SELECT *
FROM SalesLT.ProductDescription;

SELECT 
    ProductDescriptionID,
    LEFT(Description, 100) AS DescriptionSummary,
    ModifiedDate
FROM SalesLT.ProductDescription;

SELECT 
    ProductDescriptionID,
    Description
FROM SalesLT.ProductDescription
WHERE Description LIKE '%durable%';

SELECT 
    ProductModelID,
    Name,
    CatalogDescription,
    ModifiedDate
FROM SalesLT.ProductModel;

SELECT 
    ProductModelID,
    Name,
    CatalogDescription.value('(/Catalog/Text)[1]', 'nvarchar(100)') AS CatalogText
FROM SalesLT.ProductModel
WHERE CatalogDescription IS NOT NULL;

SELECT 
    ProductModelID,
    Name
FROM SalesLT.ProductModel
WHERE Name LIKE '%Pro%';

SELECT *
FROM SalesLT.ProductModelProductDescription;

SELECT 
    ProductModelID,
    ProductDescriptionID,
    Culture,
    ModifiedDate
FROM SalesLT.ProductModelProductDescription
WHERE Culture = N'ENUS';

SELECT 
    Culture, 
    COUNT(*) AS TotalDescriptions
FROM SalesLT.ProductModelProductDescription
GROUP BY Culture;

SELECT *
FROM SalesLT.SalesOrderDetail;

SELECT 
    SalesOrderID,
    SalesOrderDetailID,
    OrderQty,
    UnitPrice,
    UnitPriceDiscount,
    LineTotal
FROM SalesLT.SalesOrderDetail;

SELECT 
    SalesOrderID,
    SUM(LineTotal) AS OrderTotal
FROM SalesLT.SalesOrderDetail
GROUP BY SalesOrderID;

SELECT *
FROM SalesLT.SalesOrderHeader;

SELECT 
    SalesOrderID,
    SalesOrderNumber,
    OrderDate,
    DueDate,
    TotalDue
FROM SalesLT.SalesOrderHeader;

SELECT 
    SalesOrderID,
    OrderDate,
    OnlineOrderFlag,
    TotalDue
FROM SalesLT.SalesOrderHeader
WHERE OrderDate >= DATEADD(month, -1, GETDATE());


/*
Below is a set of sample T‑SQL UPDATE statements—each demonstrating a different style of updating data using values already present in the tables. In these examples, we use techniques such as applying built‑in functions, using a self‑join or a correlated subquery, or simply performing a “trivial” update (one that recalculates the same value). Although each statement reassigns data that is already there, the techniques illustrate various update patterns that you might mix and match depending on your needs. (Always test these in a non‑production environment before applying them anywhere sensitive.)
*/

UPDATE SalesLT.Address
SET City = UPPER(City);

UPDATE a
SET a.PostalCode = b.PostalCode
FROM SalesLT.Address AS a
JOIN SalesLT.Address AS b ON a.AddressID = b.AddressID;

UPDATE SalesLT.Address
SET ModifiedDate = (
    SELECT MAX(a2.ModifiedDate)
    FROM SalesLT.Address AS a2
    WHERE a2.AddressID = SalesLT.Address.AddressID
);

UPDATE SalesLT.Customer
SET LastName = UPPER(LastName);

UPDATE SalesLT.Customer
SET FirstName = SUBSTRING(FirstName, 1, LEN(FirstName));

UPDATE c
SET c.EmailAddress = c2.EmailAddress
FROM SalesLT.Customer AS c
JOIN SalesLT.Customer AS c2 ON c.CustomerID = c2.CustomerID;

UPDATE SalesLT.CustomerAddress
SET AddressType = CONCAT(AddressType, '');

UPDATE SalesLT.CustomerAddress
SET ModifiedDate = (
    SELECT ca2.ModifiedDate
    FROM SalesLT.CustomerAddress AS ca2
    WHERE ca2.CustomerID = SalesLT.CustomerAddress.CustomerID
      AND ca2.AddressID = SalesLT.CustomerAddress.AddressID
);

UPDATE SalesLT.Product
SET Name = UPPER(Name);

UPDATE SalesLT.Product
SET ListPrice = ListPrice * 1.0;

UPDATE p
SET p.ProductNumber = t.ProductNumber
FROM SalesLT.Product AS p
JOIN SalesLT.Product AS t ON p.ProductID = t.ProductID;

UPDATE SalesLT.ProductCategory
SET Name = LOWER(Name);

UPDATE pc
SET pc.ParentProductCategoryID = sc.ParentProductCategoryID
FROM SalesLT.ProductCategory AS pc
JOIN SalesLT.ProductCategory AS sc ON pc.ProductCategoryID = sc.ProductCategoryID;

UPDATE SalesLT.ProductDescription
SET Description = LEFT(Description, LEN(Description));

UPDATE pd
SET pd.rowguid = p2.rowguid
FROM SalesLT.ProductDescription AS pd
JOIN SalesLT.ProductDescription AS p2 ON pd.ProductDescriptionID = p2.ProductDescriptionID;

UPDATE SalesLT.ProductModel
SET Name = CONCAT(Name, '');

UPDATE SalesLT.ProductModel
SET CatalogDescription = CatalogDescription.query('/*')
WHERE CatalogDescription IS NOT NULL;

UPDATE SalesLT.ProductModelProductDescription
SET Culture = UPPER(Culture);

UPDATE SalesLT.ProductModelProductDescription
SET ModifiedDate = (
    SELECT pmpd2.ModifiedDate
    FROM SalesLT.ProductModelProductDescription AS pmpd2
    WHERE pmpd2.ProductModelID = SalesLT.ProductModelProductDescription.ProductModelID
      AND pmpd2.ProductDescriptionID = SalesLT.ProductModelProductDescription.ProductDescriptionID
      AND pmpd2.Culture = SalesLT.ProductModelProductDescription.Culture
);

UPDATE SalesLT.SalesOrderDetail
SET OrderQty = OrderQty * 1;

UPDATE sod
SET UnitPrice = (
    SELECT sod2.UnitPrice
    FROM SalesLT.SalesOrderDetail AS sod2
    WHERE sod2.SalesOrderDetailID = sod.SalesOrderDetailID
)
FROM SalesLT.SalesOrderDetail AS sod;

UPDATE sod
SET sod.UnitPriceDiscount = sod2.UnitPriceDiscount
FROM SalesLT.SalesOrderDetail AS sod
JOIN SalesLT.SalesOrderDetail AS sod2 ON sod.SalesOrderDetailID = sod2.SalesOrderDetailID;

UPDATE SalesLT.SalesOrderHeader
SET ShipMethod = CONCAT(ShipMethod, '');

UPDATE soh
SET soh.CreditCardApprovalCode = soh2.CreditCardApprovalCode
FROM SalesLT.SalesOrderHeader AS soh
JOIN SalesLT.SalesOrderHeader AS soh2 ON soh.SalesOrderID = soh2.SalesOrderID;

UPDATE SalesLT.SalesOrderHeader
SET OrderDate = (
    SELECT soh2.OrderDate 
    FROM SalesLT.SalesOrderHeader AS soh2 
    WHERE soh2.SalesOrderID = SalesLT.SalesOrderHeader.SalesOrderID
);

