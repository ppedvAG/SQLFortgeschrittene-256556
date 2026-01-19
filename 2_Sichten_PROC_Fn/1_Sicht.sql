--Sichten.. und waorauf man aufapssen muss

/*
ideal für Berechtigungen, da Originaltablle jem. verweigert werden könnten, 
aber über ine Sicht Zugriff gewäht werden könnten

Sicht enthält keine Daten, sondern nur die Abfrage

ist gleich schnell wie die Ad-hoc Abfrage selbst

wird gerne verwedent um komplexerer Abfragen recyclbar zu machen


*/



create view KundenUmsatz
as
SELECT        Customers.CustomerID, Customers.CompanyName, Customers.ContactName, Customers.ContactTitle, Customers.City, Customers.Country, Orders.EmployeeID, Orders.OrderDate, Orders.ShipVia, Orders.Freight, 
                         Orders.ShipCity, Orders.ShipCountry, Employees.LastName, Employees.FirstName, [Order Details].OrderID, [Order Details].ProductID, [Order Details].UnitPrice, [Order Details].Quantity, Products.ProductName, 
                         Products.UnitsInStock
FROM            Customers INNER JOIN
                         Orders ON Customers.CustomerID = Orders.CustomerID INNER JOIN
                         Employees ON Orders.EmployeeID = Employees.EmployeeID INNER JOIN
                         [Order Details] ON Orders.OrderID = [Order Details].OrderID INNER JOIN
                         Products ON [Order Details].ProductID = Products.ProductID

select * from KundenUmsatz





--Wie hoch sind die Lieferkosten in Austria
--Freight und country  27000

--VORSICHT: Die Sicht führt immer die komplette Abfrage aus und reduziert 
-- nicht auf die tats. benötigten Tabellen --> falsches Ertebnis möglich


select sum(freight) from orders




drop table if exists  slf
drop view if exists  vslf

create table slf(id int, stadt int, land int)

insert into slf
select 1,10,100
UNION ALL
Select 2,20,200
UNION ALL
select 3,30,300

--Sicht soll alle Spalten mit * abrufen
create view vslf -- with schemabinding
as
select id, stadt , land from dbo.slf


select * from vslf



--Fluss fehlt, obwohl * 
alter table slf add fluss int

update slf set fluss = id *1000

--geht..
alter table slf drop column land

--und das Ergebnis liefert die gelöschte Spalte Land mit Werten von Fluss

---Das läßt sich vermeiden , in man Sichten  WITH SCHEMABINDING schreibt












