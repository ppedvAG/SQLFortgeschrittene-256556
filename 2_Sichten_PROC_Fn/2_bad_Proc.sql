--Benutzerfreundliche Prozeduren  :-(



--Prozeduren.. Warum?
--Plan wird beim ersten Aufruf erstellt und bleibt 
--auch über den Neustart erhalten--> keine weitere
--Anlayse und Kompilierungszeiten notwendig

--ähnlich wie Windows Batchdateien
--Proz kann INS UP DEL SEL .. enthalten

create proc gpName @par1 int, @par2 varchar(50)	 = 'default'
as
select * from tab where spx = @par1  and spy = @par2

exec gpName 100,'XY'


create procedure gp_kundenSuche @par1 char(5)
as
select * from northwind.dbo.customers where customerid like @par1 +'%'
GO


--exec gp_kundensuche 'A'
--bei der Vergabe des Datentyps für den Parameter 
-- ist nicht entscheidend, welchen Datentyp die Spalte besitzt
--sondern welche Werte der Parameter annehemen kann

--besser
alter procedure gp_kundenSuche @par1 varchar(5)
as
select * from northwind.dbo.customers where customerid like @par1 +'%'
GO

set statistics io on
set statistics time on

--exec gp_kundensuche 'A'

--exec gp_kundensuche '%'
select * from northwind.dbo.customers where customerid like '%'

set statistics io, time on

--Prozeduren erzegen Pläne, die wiederverwendet werden können
--so weit so gut...

select * from kundeumsatz where id < 2
--ix seek 4 Seiten

select * from kundeumsatz where id < 14000
--Tab Scan 52000  

--Prozeduren erstellen einen Plan auf der Basis der ersten Ausführung. Der Parameter ist also 
--entscheidend, welcher Plan erstellt wird.
--Dieser Pan wird auch über den Neustart hinaus immer weider verwendet
--... auch wenn dies nicht optimal sein sollte

create proc gpdemo @par1 int
as
select * from kundeumsatz where id < @par1
Go

exec gpdemo 2
--Plan mit Seek
exec gpdemo 900000 --Plan mit Seek???
--Vergleich mit Tab Scan
---, CPU-Zeit = 2813 ms, verstrichene Zeit = 19711 ms. >52000 Seiten
--, CPU-Zeit  = 5453 ms, verstrichene Zeit = 21383 ms. >900000 Seiten


dbcc freeproccache

exec gpdemo 900000
--Plan mit Scan
exec gpdemo 2 --Plan mit Scan???


--BSP 2: benutzerfreundlichen Prozeduren

--Customers

exec gpSucheKunde 'ALFKI'  
exec gpSucheKunde 'A'  -- alle mit A beginnend
exec gpSucheKunde '%'  -- alle 


create or alter proc gpSucheKunden 
		@custid nvarchar(15) = '%'
as
select	* 
from	customers 
where	customerid 
		like	@custid + '%'
GO

exec gpSucheKunden 'ALFKI'
exec gpSucheKunden  'A'
exec gpSucheKunden 








--schlecht  
create  procedure gp_kundenSuche2 @par1 varchar(10)
as
IF @par1 = '%'
select Country,city from Kunden2 where ID like @par1 
ELSE
select Country,city from Kunden2 where ID = @par1
GO
--besser wäre in der Prozedur auf anderen Prozeduren zu verweisen
-- die den idealen Plan bereits besitzten
--exec gp_kundensucheAlle2 '*'
--exec gp_kundensucheWenige '1'

