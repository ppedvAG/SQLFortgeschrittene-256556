select * into ku2 from ku1

dbcc showcontig('ku2') -- 40455

alter table ku2 add id int identity

dbcc showcontig('ku2') -- 41092

set statistics io, time on
select * from ku2 where id =  100 --  57210,  vs  41092

select * from sys.dm_db_index_physical_stats(db_id(), object_id('ku2'),NULL,NULL, 'detailed')

--forward record counts muss NULL sein
--wenn man einen HEAP kann das passieren (neue Spalten)
--ID sind im "Anhang gelandet" und verbrauchen deutlich mehr Platz als notwendig
--CL IX = Lösung


alter table ku1 add id int identity


--CL IX auf Orderdate ist fix

--Welcher Plan? -- T SCAN
select id from ku1 where id = 100  --57206
--Tab Scan

--besser durch: NIX_ID  --IX SEEK
select id from ku1 where id = 100  --3
--Plan   IX Seek + Lookup       Seiten: 4

select id, freight from ku1 where id = 100
--Nun kommt ein Lookup dazu... = teuer. Je mehr Lookups desto teuerer
--Lookup unbedingt vermeiden!!!!
select id, freight from ku1 where id < 10500 --ab 11500 ca Table scan


--besser mit: NIX_ID_FR (zusammengesetzter IX)
select id, freight from ku1 where id < 900500 --ab 10500 ca Table scan

--Achtung: nun haben wir mehrer Indizes , die gleiches leisten
-- das bedeutet nicht nur überflüssig, sondern extra Kosten bei INS UP DEL
-- I U D ist erst dann "zu Ende" , wenn alle betroffenen IX aktualisiert wurden


select * from ku1
where country = 'USA' and freight < 1
--NIX_CYFR


select country, city,Sum(UnitPrice*quantity)
from ku1
where employeeid = 2
group by country, city
--NIX_EID_inkl_cy_ci_up_qu

--where  = Schlüsselspalte
--select = eingeschlossene Spalten



--NIX_EMPID_SCY_incl_CnameLname_Pname
select companyname, lastname, productname
from ku1
where EmployeeID= 2 and Shipcountry = 'USA'

--kein Vorschlag mehr, aber es sollten 2 sein
select companyname, lastname, productname
from ku1
where EmployeeID= 2 or Shipcountry = 'USA'


--Ind. Sicht

select country, count(*) from ku1
group by country


create view vdemo
as
select country, count(*) as ANz from ku1
group by country

select * from vdemo

select country, count(*) from ku1
group by country

create or alter view vdemo  with schemabinding
as
select country, count_big(*) as ANz from dbo.ku1
group by country


--COLUMNSTORE
select * into ku3 from ku


select Companyname, avg(quantity), min(quantity)
from ku1
where
		country = 'germany'
group by CompanyName


select Companyname, avg(quantity), min(quantity)
from ku3
where
		country = 'germany'
group by CompanyName


--Warum schneidet die KU3 bei jeder Abfrage , gleich oder besser ab

--Größe der KU und Größe der KU3
-- 600MB vs 4 MB
--Stimmt das oder nicht?

--es stimmt!!!!
--und das genauso im RAM



select Companyname, avg(quantity), min(quantity)
from ku3
where
		city = 'Berlin'
group by CompanyName


--INDIZES müssen gewartet werden
