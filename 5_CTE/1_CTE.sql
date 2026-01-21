--------------------------------------------------------------------
----			CTE									----------------
--------------------------------------------------------------------

/*
Lesbarkeit (Spaghetti-Code vermeiden)
Ohne CTEs muss man oft Subqueries (Unterabfragen) verschachteln. Das wird schnell unübersichtlich. 
Mit einer CTE definieren Sie die Daten zuerst und nutzen sie danach.

Sie können aber auch zur Auflösung Hierarchien verwendet werden
- CTE vergleichbar mit temporärer View

Einfacher Aufbau einer CTE

WITH CTENAME (Spalte1, Spalte2, Spalte3,...)
AS
(
Abfrage für Daten der CTE
)
Abfrage auf CTE

*/

--DEMO 1  --einfache CTE 

with cte (AngID, Famname)
as
(
select employeeid as Angid, lastname as FamName from employees
)
select * from cte

--Aufgabe: Wie hoch ist der Durchschnitt der MAX Frachtkosten pro Kunde

--DEMO 2: Referenz auf sich selbst möglich
USE Northwind

WITH JahresUmsatz AS (
    -- Komplexe Logik hier...
    SELECT year(orderdate) as Jahr, SUM(freight) as Total FROM orders GROUP BY year(orderdate)
)
SELECT 
    J1.Jahr, 
    (J1.Total) AS UmsatzDiesesJahr,
    (J2.Total) AS UmsatzVorjahr
FROM        JahresUmsatz J1
LEFT JOIN   JahresUmsatz J2 ON J1.Jahr = J2.Jahr + 1 -- CTE wird 2x genutzt!
order by Jahr




--Wieviele Angestellte managed jeder ..
With myEmps (lastname, firstname, Knechte, Chef)
as
(select lastname,firstname, (select count(1) from employees e2 
                            where  e1.EmployeeID=e2.ReportsTo)
	    ,reportsto
from employees e1)
Select Lastname, firstname, knechte,  Chef from myEmps 


--Liste ergänzen um:
--zu jedem Ang den manager und die Anzahl der Knechte

;WITH EmployeeSubordinatesReport (EmployeeID, LastName, FirstName, NumberOfSubordinates, ReportsTo) AS
(
   SELECT
      EmployeeID,
      LastName,
      FirstName,
      (SELECT COUNT(1) FROM Employees e2
       WHERE e2.ReportsTo = e.EmployeeID) as NumberOfSubordinates,
      ReportsTo
   FROM Employees e
)

SELECT Employee.LastName, Employee.FirstName, Employee.NumberOfSubordinates,
   Manager.LastName as ManagerLastName, Manager.FirstName as ManagerFirstName, Manager.NumberOfSubordinates as ManagerNumberOfSubordinates
FROM EmployeeSubordinatesReport Employee
   LEFT JOIN EmployeeSubordinatesReport Manager ON
      Employee.ReportsTo = Manager.EmployeeID



---DEMO: Hierarchie

/*
WITH CTE (Spalten..)
AS
(
    SELECT :: Anker auf den referenziert wird
    
    UNION ALL

    SELECT :: Refrenz auf Anker
)
SELECT * from CTE

*/

with CTE (empid, reportsto)
as 
(
select employeeid as empid, reportsto from employees where reportsto is null --= CHEF
UNION ALL
select e.employeeid, e.reportsto  from employees e inner join cte on cte.empid = e.reportsto
)
select * from cte


--Aufgabe : Zeige die Herarchiestufe an (1,2) und die Namen der Angestellten und den Namen des jeweiligen Cheffs


with CTE (empid,Lastname, reportsto, Stufe, Boss)
as 
(
select employeeid as empid, lastname, reportsto,  1 as Stufe,convert(nvarchar(20),'Cheff') as Boss  from employees where reportsto is null --= CHEF
UNION ALL
select e.employeeid, e.lastname, e.reportsto,  Stufe +1,CTE.Lastname    from employees e inner join cte on cte.empid = e.reportsto
)
select * from CTE
