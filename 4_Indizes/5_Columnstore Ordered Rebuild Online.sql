USE WideWorldImporters; 
USE [master]
GO


ALTER DATABASE tempdb MODIFY FILE (NAME = N'tempdev', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED );
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp2', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp3', FILEGROWTH = 64 MB, MAXSIZE = UNLIMITED);
ALTER DATABASE tempdb MODIFY FILE (NAME = N'temp4', FILEGROWTH = 64 MB, MAXSIZE =UNLIMITED);

 
SET STATISTICS IO,TIME ON; 
 Drop table if exists dbo.salesordersbig

SELECT TOP 0 *  
INTO dbo.SalesOrdersBIG  
FROM Sales.Orders; 
 
ALTER TABLE dbo.SalesOrdersBIG ADD CONSTRAINT PK_SalesOrdersBIG PRIMARY KEY CLUSTERED  
(OrderID ASC); 
 
GO 
 
 
 
INSERT INTO dbo.SalesOrdersBIG  
(       OrderID, CustomerID, SalespersonPersonID, PickedByPersonID
    ,   ContactPersonID, BackorderOrderID, OrderDate, ExpectedDeliveryDate
    ,   CustomerPurchaseOrderNumber, IsUndersupplyBackordered, Comments
    ,   DeliveryInstructions, InternalComments, PickingCompletedWhen
    ,   LastEditedBy, LastEditedWhen) 
SELECT 
         Orders.OrderID + (ORDERS2.OrderID * 100000) AS OrderID, 
         Orders.CustomerID, Orders.SalespersonPersonID, Orders.PickedByPersonID, Orders.ContactPersonID, Orders.BackorderOrderID, Orders.OrderDate, Orders.ExpectedDeliveryDate, 
         Orders.CustomerPurchaseOrderNumber, Orders.IsUndersupplyBackordered, Orders.Comments, Orders.DeliveryInstructions, Orders.InternalComments, Orders.PickingCompletedWhen, 
         Orders.LastEditedBy, Orders.LastEditedWhen 
FROM Sales.Orders 
LEFT JOIN Sales.Orders ORDERS2 ON ORDERS2.OrderID <= 200;


SELECT OrderDate, COUNT(*) AS OrderCount, 
    AVG(DATEDIFF(HOUR, OrderDate, ExpectedDeliveryDate))AS AvgOrderDeliveryTimeHours, 
    SUM(CASE WHEN BackorderOrderID IS NOT NULL THEN 1 ELSE 0 END) AS BackorderCount 
FROM    dbo.SalesOrdersBIG 
WHERE   OrderDate >= '1/1/2016' 
    AND OrderDate <= '2/1/2016' 
GROUP BY OrderDate 
ORDER BY OrderDate;

select * from sys.dm_db_column_store_row_group_physical_stats
select * from sys.dm_db_column_store_row_group_operational_stats

--Messung 166580 Seiten  CPU time = 3578 ms,  elapsed time = 959 ms.

CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrdersBIG 
ON dbo.SalesOrdersBIG (OrderDate, ExpectedDeliveryDate, BackorderOrderID)


--Messung:   CPU time = 47 ms,  elapsed time = 65 ms.  16 Segmente Skipped 0



CREATE NONCLUSTERED COLUMNSTORE INDEX NCCI_SalesOrdersBIG
ON dbo.SalesOrdersBIG (OrderDate, ExpectedDeliveryDate, BackorderOrderID) 
ORDER  (OrderDate,ExpectedDeliveryDate, BackorderOrderID) 
WITH (DROP_EXISTING = ON,ONLINE = ON, MAXDOP = 1);--MAXDOP=1

--Messung:Table 'SalesOrdersBIG'. Segment reads 7, segment skipped 8.

ALTER INDEX NCCI_SalesOrdersBIG ON dbo.SalesOrdersBIG REBUILD;
--Abfrage in zweitem Fenster starten.. läuft und läuft

ALTER INDEX NCCI_SalesOrdersBIG ON dbo.SalesOrdersBIG
REBUILD WITH (ONLINE = ON); -- Online-Option ermöglicht gleichzeitigen Zugriff

--Abfrage im zweitem Fenster