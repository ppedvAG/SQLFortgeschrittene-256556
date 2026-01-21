WITH CTE_KDBEST AS (
    SELECT 
        CustomerID, 
        OrderDate, 
        OrderID,
        --  Nummerierung pro Kunde, sortiert nach Datum (neueste zuerst)
        ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY OrderDate DESC) as rn
    FROM dbo.Orders
)
SELECT 
    c.CustomerID,
    c.CompanyName,
    cte.OrderDate AS LetzteBestellung,
    cte.OrderID
FROM dbo.Customers c
LEFT JOIN CTE_KDBEST cte
    ON c.CustomerID = cte.CustomerID 
    AND cte.rn = 1; -- Wir wollen nur die Nr. 1 (die neueste)

--Durchsuchen der gesamten Orders




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

--eigtl ein Loop Join..wäre ein WHERE c.City = 'London' enthalten, wäre es dramatisch schneller

/*
OUTER APPLY: 
Funktioniert am besten, wenn ein Index auf Orders(CustomerID, OrderDate) existiert. 
Ohne diesen Index muss SQL Server für jeden Kunden einen teuren Table Scan machen 
(was die Performance töten würde).


Nimm die CTE, wenn du das Ergebnis über den gesamten
Datenbestand benötigt wird .

Achtung jeder JOIN mit der CTE muss die CTE erneut abrufen

Nimm OUTER APPLY, 
wenn du nur eine Teilmenge der Kunden abfragst 
(z. B. mit WHERE auf der Kundentabelle) oder wenn die Tabelle Orders riesig ist, 
aber pro Kunde nur wenige Einträge existieren.

*/