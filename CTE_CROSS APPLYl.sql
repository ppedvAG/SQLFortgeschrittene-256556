WITH RankedOrders AS (
    SELECT 
        CustomerID, 
        OrderDate, 
        OrderID,
        -- Erstelle eine Nummerierung pro Kunde, sortiert nach Datum (neueste zuerst)
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) as rn
    FROM dbo.Orders
)
SELECT 
    c.CustomerID,
    c.CompanyName,
    r.OrderDate AS LetzteBestellung,
    r.OrderID
FROM dbo.Customers c
LEFT JOIN RankedOrders r 
    ON c.CustomerID = r.CustomerID 
    AND r.rn = 1; -- Wir wollen nur die Nr. 1 (die neueste)






SELECT 
    c.CustomerID,
    c.CompanyName,
    oa.OrderDate AS LetzteBestellung,
    oa.OrderID
FROM dbo.Customers c
--where c.city = 'London'
OUTER APPLY (
    -- Diese Query wird für JEDE Zeile der Customers-Tabelle ausgeführt
    SELECT TOP 1 
        OrderDate, 
        OrderID
    FROM dbo.Orders o
    WHERE o.CustomerID = c.CustomerID -- Die Korrelation (Verknüpfung)
    ORDER BY o.OrderDate DESC
) oa;