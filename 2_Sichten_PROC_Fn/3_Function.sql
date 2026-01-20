--Functions
--super praktisch, aber häufig ein fettes  Problem in der Performance


select f(wert), f(spalte) from f(wert) where f(Spalte) > f(wert)



select * from orders
select * from  [Order Details]

select sum(unitprice*quantity) from [Order Details]

--Aufgabe: Rechnhugsumme per Funktion
select fBestellID(10248) 


create function fRsumme(@bestid int) returns money
as
	begin
		return (
				select sum(unitprice*quantity) 
				from 
					[Order Details]
				where 
					orderid = @bestid
			)
	end

select dbo.frsumme(10248)--440


--Spiele mit den Kompabilitätsgraden 120 und 160. Wo ist der Unterschied?
--Vor SQL 2017: Tabelle Order Details erscheint werder im Plan noch in den Statistiken!!!
--Auch keine OPtimierung möglich

--Ab SQL 2017 können Skalarfunktionen im begrezten Maße optimiert werden.
--#IQP

select dbo.frsumme(orderid),* from orders
set statistics io, time on


alter table orders add Rsumme as dbo.frsumme(orderid)
--selbst SQL 2022 kann nun die Funktion nicht mehr in eine Unterabfrage auflösen
--und zeigt falsche Stst Werte und falschen Plan an

--nachzuvollziehen in SQL Profiler
-- SP:StmtCompletet in Aufzeichnung mit aufnehmen
--Tipp: gut filtern!

select * from orders

select * from employees
--Rente ab 65
--finde alle Ang, die jetzt in Rente sind

declare @var as datetime
select @var=dateadd(yy,-65, getdate())
select @var

select * from employees where birthdate < @var



--schnellste Weg
select * from employees where birthdate < dateadd(yy,-65, getdate())


select * from employees where datediff(yy, getdate(), birthdate) > 65
