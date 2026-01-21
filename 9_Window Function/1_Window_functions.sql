------------------------------------------------------------
----- WINDOWS FUNCTION -------------------------------------
------------------------------------------------------------


--Berechnungen über eine bestimmte Menge an Zeilen 
--ohne diese zu gruppieren
--M;an muss diese mit Group by vergleichen:
--Group by reduziert die Zeilenzahl eine Window Fn() nicht.

Grundliegender CODE:



FUNKTION() OVER 
(
    PARTITION BY spalte1    -- Optional: Untergruppen bilden
    ORDER BY spalte2        -- Sortierung innerhalb der Partition
    ROWS/RANGE ...          -- Optional: Frame-Spezifikation
)


/*
-------------------------------
Ranking-Funktionen (Rangfolgen)
-------------------------------
Hiermit man Platzierungen vergeben.

- ROW_NUMBER(): Durchnummerieren (1, 2, 3, 4...).

- RANK(): Platzierung (1, 2, 2, 4...) – bei Gleichstand wird eine Nummer übersprungen.

- DENSE_RANK(): Platzierung (1, 2, 2, 3...) – keine Lücken bei Gleichstand.

-----------------------------------------------------------------
--DEMO 1 : Welche 3 Produkte sind die teuersten einer Kategorie
-----------------------------------------------------------------
*/
WITH CTE AS
(
select 
        c.CategoryName, ProductName, p.UnitPrice,
        RANK() over (partition by c.categoryname order by UnitPrice desc)
        AS RANG
from Products p inner join Categories c
    on p.CategoryID=p.CategoryID
)
select * from cte where RANG <= 3

-----------------------------------------------------------------
--DEMO : Berechnung die fortlaufenden Lieferkosten pro Kunde
-----------------------------------------------------------------

select 
    customerid, 
    sum(freight) over 
                (partition by customerid order by orderdate)
    , orderdate
from orders order by customerid, orderdate






-----------------------------------------------------------------
--Aufgabe  : Aggregate: Wie hoch ist der Anteil in 5 eines Produkts 
--                    an der Rechnungssumme
-----------------------------------------------------------------

SELECT 
orderid , 
sum (unitprice*quantity)  over
            (partition by orderid order by orderid),
(convert(decimal (3,2),
(unitprice*quantity) / sum (unitprice*quantity)  over
            (partition by orderid order by orderid))*100)
as[%-Anteil]
from [Order Details] 


-----------------------------------------------------------
---DEMO:   LAG() und LEAD() - Zugriff auf vorherige 
--                      oder nächste Zeile

--      LAG/LEAD (Spalte oder Berechnung, Versatz (immer +), DefaultWert, wenn NULL)
-----------------------------------------------------------

SELECT 
    OrderID,
    OrderDate AS Aktuelles_Datum,    
    -- LAG: Wann war die Bestellung VOR dieser?
    LAG(OrderDate) OVER (
        PARTITION BY CustomerID  ORDER BY OrderDate) AS Vorherige_Bestellung,

    -- LEAD: Wann ist die NÄCHSTE Bestellung?
    LEAD(OrderDate) OVER 
         (PARTITION BY CustomerID ORDER BY OrderDate) AS Naechste_Bestellung
FROM Orders
WHERE CustomerID = 'ALFKI';

-----------------------------------------------------------
---AUFGABE:  Frachtkosten pro Jahr und Mitarbeiter
--           mit Vorjahresvergleich
-----------------------------------------------------------
WITH CTE AS
(
    select 
    year(orderdate) as Jahr,employeeid,
    sum(freight) as AktUmsatz,
    LAG(sum(freight),1,0) over 
            (Partition by employeeid order by year( orderdate))   
            as VorherigerUmsatz
    from orders
    group by year(orderdate), employeeid
 
)
select Jahr, Employeeid , AktUmsatz, VorherigerUmsatz,
    CASE WHEN
            (AktUmsatz -VorherigerUmsatz) <=0 then '!! RÜCKGANG !!'
            ELSE    'OK'
    END
from CTE
   order by employeeid,jahr


-----------------------------------------------------------
---NTILE:  NTILE()
--          
-----------------------------------------------------------

select 
p.productname, CategoryName, Unitprice,
NTILE(3) over (partition by Categoryname order by UnitPrice),
CASE
        WHEN NTILE(3) over (partition by Categoryname order by UnitPrice) =1 THEN 'Budget'
        WHEN NTILE(3) over (partition by Categoryname order by UnitPrice) =2 THEN 'STANDARD'
        ELSE 'PREMIUM'
END
from products p inner join Categories c on c.CategoryID=p.CategoryID


---------------------------------------------------------------------
-- WINDOW - seit SQL 2022 Vereindachung

--  verwendet man eine Windowfn() öfters, kann man diese
--  zur besser Lesbarkeit eine Kürzel statt dem Code verwenden
--  die Definition des Kürzels und der Code stehen am Ende der Abfrage
----------------------------------------------------------------------
SELECT 
    p.ProductName,     c.CategoryName,     p.UnitPrice,   
    NTILE(3) OVER w AS Gruppe,
    CASE 
        WHEN NTILE(3) OVER w = 1 THEN 'Budget'
        WHEN NTILE(3) OVER w = 2 THEN 'STANDARD'
        ELSE 'PREMIUM'
    END AS Preissegment
FROM Products p 
INNER JOIN Categories c ON c.CategoryID = p.CategoryID
WINDOW w AS (PARTITION BY c.CategoryName ORDER BY p.UnitPrice);

------------------------------------------------------------------
-- Aufgabe: Optimiere die Aufgabe "Fortlaufende Rechnungssummen
------------------------------------------------------------------

SELECT 
orderid , 
sum (unitprice*quantity)  over  w (convert(decimal (3,2),
(unitprice*quantity) / sum (unitprice*quantity)  over  w)*100)
as [%-Anteil]
from [Order Details] 
WINDOW w AS (partition by orderid order by orderid)


-----------------------------------------------------------
--STATISTISCHE Fn()

-- CUME_DIST
-- PERCENT_RANK
-- PERCENTILE_CONT
-----------------------------------------------------------


-----------------------------------------------------------
--STATISTISCHE Fn()

-- CUME_DIST: Wieviele % der Werte sind gleich 
--            oder unter diesem Wert
-----------------------------------------------------------

select 
    Productname, Unitprice, CUME_DIST() over (order by Unitprice) as CDRang
from products
where CategoryID =1
order by CDRang desc

-----------------------------------------------------------
--STATISTISCHE Fn()

-- PERCENT_RANK: Wo steht ich im Vergleich zu anderen . 
--               Beginnt bei 0 und endet mit 1
-----------------------------------------------------------

select 
    Productname, Unitprice, PERCENT_RANK() over (order by Unitprice) as PercRang
from products
where CategoryID =1
order by PercRang desc


-----------------------------------------------------------
--STATISTISCHE Fn()

-- PERCENTILE_CONT: Wo liegt der Median auch fiktiver Wert
-- PERCENTILE_DISC: Wo liegt der Median -- realer Wert

-----------------------------------------------------------

select 
        Productname, Unitprice,
        PERCENTILE_CONT(0.5) WITHIN GROUP (order by unitprice) over 
        (partition by Categoryid) as PCMedian,
          PERCENTILE_DISC(0.5) WITHIN GROUP (order by unitprice) over 
        (partition by Categoryid) as PDMedian
 from products


 
-----------------------------------------------------------
--STATISTISCHE Fn()

-- FIRST_VALUE(): Wo liegt der Median auch fiktiver Wert
-- LAST_VALUE(): Wo liegt der Median -- realer Wert

-----------------------------------------------------------
select 
Productname, Productid, unitprice,
FIRST_VALUE(UNITPRICE) over (partition by categoryid order by unitprice) as FV,
LAST_VALUE(UNITPRICE) 
    OVER (partition by categoryid order by unitprice
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as LV
from products