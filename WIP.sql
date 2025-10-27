-- MY SQL Notes and Examples 2


use AdventureWorksLT2022;

select top(100) 
    pr.ProductNumber,
    pr.Name,
    pr.Color,
    pr.ListPrice,
    pd.Description

from
    SalesLT.Product as pr
    inner join SalesLT.ProductModel as pm
        on pr.ProductModelID = pm.ProductModelID
        
    inner join SalesLT.ProductModelProductDescription as pmpd
        on pmpd.ProductModelID = pm.ProductModelID 

    inner join SalesLT.ProductDescription pd
        on pd.ProductDescriptionID = pmpd.ProductDescriptionID
    

where pmpd.Culture = 'en'
order by pr.Name        
        

-- Sales total by product
select top(100) 
    pr.ProductNumber,
    pr.Name,
    pr.Color,
    pd.Description,
    round( sum(sod.LineTotal * sod.OrderQty), 2 )

from
    SalesLT.Product as pr
    inner join SalesLT.ProductModel as pm
        on pr.ProductModelID = pm.ProductModelID
        
    inner join SalesLT.ProductModelProductDescription as pmpd
        on pmpd.ProductModelID = pm.ProductModelID 

    inner join SalesLT.ProductDescription pd
        on pd.ProductDescriptionID = pmpd.ProductDescriptionID
   
    inner join SalesLT.SalesOrderDetail sod
        on sod.ProductID = pr.ProductID

where 
    pmpd.Culture = 'en'
group by 
    pr.ProductNumber,
    pr.Name,
    pr.Color,
    pd.Description

order by pr.Name        
        

-- Products
drop view v_products;
go

create view SalesLT.v_Products as

select 
    pr.ProductID,
    pr.ProductNumber,
    pr.Name,
    pr.Color,
    pd.Description,
    pmpd.Culture
from
    SalesLT.Product as pr
    inner join SalesLT.ProductModel as pm
        on pr.ProductModelID = pm.ProductModelID
        
    inner join SalesLT.ProductModelProductDescription as pmpd
        on pmpd.ProductModelID = pm.ProductModelID 

    inner join SalesLT.ProductDescription pd
        on pd.ProductDescriptionID = pmpd.ProductDescriptionID
go

select * from SalesLT.v_Products
go           

-- Sales total by product
select top(100) 
    pv.ProductNumber,
    pv.Name,
    pv.Color,
    pv.Description,
    round( sum(sod.LineTotal * sod.OrderQty), 2 )

from
    SalesLT.v_Products as pv
   
    inner join SalesLT.SalesOrderDetail sod
        on sod.ProductID = pv.ProductID
where 
    pv.Culture = 'fr'
group by 
    pv.ProductNumber,
    pv.Name,
    pv.Color,
    pv.Description

order by pv.Name       

go


-- Create access log for trigger to insert into
drop table SalesLT.AccessLog
go

create table SalesLT.AccessLog (
   log_id int identity(1,1)  NOT FOR REPLICATION,
   log_timestamp datetime,
   log_message varchar(100),
   updated_by sysname
)

select * from  SalesLT.AccessLog
go

-- Trigger
USE AdventureWorksLT2022

IF EXISTS(
  SELECT *
    FROM sys.triggers
   WHERE name = N'trg_Customer_Update'
)
	DROP TRIGGER SalesLT.trg_Customer_Update
go

-- Create the trigger such that it will insert a row into
-- the log table for every row updated (delete+insert)
CREATE TRIGGER trg_Customer_Update
ON SalesLT.Customer
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO SalesLT.AccessLog
        (log_timestamp, log_message, updated_by)

    SELECT GETDATE(), 'updated', SYSTEM_USER

    FROM deleted AS d
    INNER JOIN inserted AS i
        ON d.CustomerID = i.CustomerID;
END;

update SalesLT.Customer set ModifiedDate = getdate()

Select * from SalesLT.AccessLog

delete from SalesLT.AccessLog

-- Get table metadata
sp_help 'SalesLT.AccessLog';

-- CTE
WITH cte_Products AS
(
    select * from SalesLT.v_Products
)
select top(100) 
    pv.ProductNumber,
    pv.Name,
    pv.Color,
    pv.Description,
    round( sum(sod.LineTotal * sod.OrderQty), 2 ) as Sales

from
    cte_Products as pv
   
    inner join SalesLT.SalesOrderDetail sod
        on sod.ProductID = pv.ProductID
where 
    pv.Culture = 'en'
group by 
    pv.ProductNumber,
    pv.Name,
    pv.Color,
    pv.Description

order by pv.Name       

-- Log table
delete from SalesLT.AccessLog
go


create view SalesLT.v_SalesByState
as
select adr.StateProvince, sum(TotalDue) as Total
from
SalesLT.Customer cu                             -- customers
inner join SALESlt.SalesOrderHeader soh         -- order headers
    on soh.CustomerID = cu.CustomerID
inner join SalesLT.Address adr                  -- customer address
    on adr.AddressID = soh.ShipToAddressID
group by
    adr.StateProvince
--order by adr.StateProvince
go


SELECT        SalesLT.SalesOrderHeader.ShipToAddressID, SalesLT.Customer.CustomerID, SalesOrderHeader_1.TotalDue, SalesLT.Customer.CompanyName
FROM          SalesLT.Customer 
INNER JOIN
    SalesLT.SalesOrderHeader ON SalesLT.Customer.CustomerID = SalesLT.SalesOrderHeader.CustomerID 
INNER JOIN
    SalesLT.Address ON SalesLT.SalesOrderHeader.ShipToAddressID = SalesLT.Address.AddressID AND SalesLT.SalesOrderHeader.BillToAddressID = SalesLT.Address.AddressID 
INNER JOIN
    SalesLT.SalesOrderHeader AS SalesOrderHeader_1 ON SalesLT.Customer.CustomerID = SalesOrderHeader_1.CustomerID AND SalesLT.Address.AddressID = SalesOrderHeader_1.ShipToAddressID

-- Create access log for trigger to insert into
drop table SalesLT.AccessLog
create table SalesLT.AccessLog (
   log_id int identity(1,1)  NOT FOR REPLICATION,
   log_timestamp datetime,
   log_message varchar(100),
   updated_by sysname
)
select * from  SalesLT.AccessLog
-- Trigger
USE AdventureWorksLT2022


IF EXISTS(
  SELECT *
    FROM sys.triggers
   WHERE name = N'trg_Customer_Update'
)
create view SalesLT.v_SalesByState
as
select adr.StateProvince, sum(TotalDue) as Total
from
SalesLT.Customer cu                             -- customers
inner join SALESlt.SalesOrderHeader soh         -- order headers
    on soh.CustomerID = cu.CustomerID
inner join SalesLT.Address adr                  -- customer address
    on adr.AddressID = soh.ShipToAddressID
group by
    adr.StateProvince

select top(100) * from SalesLT.v_SalesByState


-- Creating a scalar function
DROP FUNCTION IF EXISTS dbo.fn_GetFullName;
go

CREATE FUNCTION dbo.fn_GetFullName(@FirstName NVARCHAR(50), @LastName NVARCHAR(50))
RETURNS NVARCHAR(101)
AS
BEGIN
    RETURN @FirstName + ' ' + @LastName;
END;
go


SELECT  dbo.fn_GetFullName(cust.FirstName, cust.LastName),  -- Call the scalar function
        sohd.ShipToAddressID, cust.CustomerID, cust.CompanyName, cust.FirstName, cust.LastName, cust.SalesPerson, sohd.AccountNumber, addr.AddressLine1, addr.AddressLine2, addr.City, addr.StateProvince, 
                         addr.CountryRegion, addr.PostalCode
FROM            SalesLT.Customer AS cust INNER JOIN
                         SalesLT.SalesOrderHeader AS sohd ON cust.CustomerID = sohd.CustomerID INNER JOIN
                         SalesLT.Address AS addr ON sohd.ShipToAddressID = addr.AddressID



-- Create an iTVF (table value functions = returns a table)
-- Consider this a parameterized view. However, more logic can be added.

DROP FUNCTION IF EXISTS dbo.fn_GetOrdersByCustomer;
go

CREATE FUNCTION dbo.fn_GetOrdersByCustomer(@CustomerID INT)
RETURNS TABLE
AS
RETURN (
SELECT  dbo.fn_GetFullName(cust.FirstName, cust.LastName) as FullName,  -- Call the scalar function
        sohd.ShipToAddressID, cust.CustomerID, cust.CompanyName, cust.FirstName, cust.LastName, cust.SalesPerson, sohd.AccountNumber, addr.AddressLine1, addr.AddressLine2, addr.City, addr.StateProvince, 
                         addr.CountryRegion, addr.PostalCode
FROM            SalesLT.Customer AS cust INNER JOIN
                         SalesLT.SalesOrderHeader AS sohd ON cust.CustomerID = sohd.CustomerID INNER JOIN
                         SalesLT.Address AS addr ON sohd.ShipToAddressID = addr.AddressID
WHERE cust.CustomerID = @CustomerID

)
go

-- Using the output of the iTVF in a CROSS APPLY join
select cust.CustomerID, orders.*
from SalesLT.Customer as cust
cross apply dbo.fn_GetOrdersByCustomer(cust.CustomerID) as orders

-- Multi-table value functions mTVF
go
DROP FUNCTION IF EXISTS dbo.fn_GetHighValueOrders;

go
CREATE FUNCTION dbo.fn_GetHighValueOrders(@MinAmount DECIMAL(10,2))
RETURNS @Orders TABLE (
    OrderID INT,
    CustomerID INT,
    TotalDue DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @Orders
    
    SELECT SalesOrderID, CustomerID, TotalDue
    FROM SalesLT.SalesOrderHeader as sohd 
    WHERE TotalDue >= @MinAmount;

    RETURN;
END;

go

-- Use DECLAREd var as a parameter
DECLARE @minAmount decimal(10,2)
SET @minAmount = 0

select * from dbo.fn_GetHighValueOrders(@minAmount)
order by TotalDue asc

-- CASE statements

select OrderID, CustomerID, TotalDue,
    case 
        when TotalDue >=0 and TotalDue < 50000 THEN 'Low'
        when TotalDue >=50000 THEN 'High'
    end as SalesLevel
from dbo.fn_GetHighValueOrders(@minAmount)
order by TotalDue asc


-- Computed columns
ALTER TABLE SalesLT.SalesOrderHeader
DROP COLUMN SubTotalBeforeFreight

-- Not PERSISTED
ALTER TABLE SalesLT.SalesOrderHeader
ADD SubTotalBeforeFreight AS (SubTotal + TaxAmt);  -- Calculate on the fly from base columns

-- or

-- PERSISTED
ALTER TABLE SalesLT.SalesOrderHeader
ADD SubTotalBeforeFreight AS (SubTotal + TaxAmt) PERSISTED;  -- Calculate on the fly from base columns PERSISTED; -- Calc and store in table - updating the value from the base columns if needed















