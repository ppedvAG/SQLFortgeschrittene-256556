/*
1.  Problem: größer werdende Tabellen

Idee: Salamitaktiv.. statt einer großen Tabelle viele kleine



1) part. Sicht
2) Partitionierung


zu 1)
statt einer Tabelle viele kleinere Tabellen
Aber: --Die Anwendung braucht aber "UMSATZ"

Lösung:
Sicht die alle Tabellen mit UNION ALL zusammenfasst
damit wir einen Vorteil haben: CHECK Einschränkungen zB jahr=2020
--das hilft dem Plan um genau eine der Tabellen der Sicht herauszupicken

negativ: hilft nur wenn die entspr Spalte auch im where abgefragt
         umständllich

		 das geht nicht: identity, PK FK muss angepasst-- Referentielle Integrität

zu 2)
	es bleibt die Tabelle

	man braucht:

		-Dateigruppen 

		-function
		
			create partition function fname (datentyp)
			as
			RANGE LEFT |RIGHT for Values(Grenzwert1, Grenzwert2,..)

		--Returnwert: 1 , 2, 3, 4...

		-Part-Schema

			create partition scheme SchName
			as
			partition fname to (Dgruppe1, Dgruppe2, ...)
		---                       1      2

				Tabelle  liegt auf Schema

			create table tabellename (id int, ...) ON SchName(Spalte)

		+ Flexibel
			 Grenze dazu : 
			 alter partition scheme schName next used Dgruppe

			 alter partition function fname() split range (grenzwert)
		 

		 Grenze entfernen
			 alter partition function fName merge range (grenzwert)

			 einz. Part. können komprimiert

		 Archivieren

			 alter table tabName switch partition ZAHL to ArchivTab
			 aber es muss gelten: Archivschema  muss exakt aussehen wir OrgTabelle
									allerdings identity nein, aber trotzdem not null

			Archiv muss auf selber Dgruppe sein wie partition ZAHL

			Daten werden nicht verschoben, sondern part wird in Tabe umgewandelt


	best Tabelle, die auf einer Dgruppen oder Schema liegen, können nur mit einem Löschen 
	auf andere Dgruppen oder Schemas verschoben werden
	---Ausnahme best Index



Daten seit dem Jahr 2000 .. Tab Umsatz

TAB A  10000
TAB B  100000

Abfrage, mit 10 zeilen Ergebnis
--welche Tab ist schneller:  A

*/

-----------------------------------------------------------
--			partitionierte Sicht					-------
-----------------------------------------------------------

--Ausgangssituation: Tabelle Umsatz (ständig wachsend
--Split in mehrere (kleinere) Tabelle (Kalenderwoche, Monat, Jahresweise..


create table u2020(id int identity, jahr int, spx int)
create table u2019(id int identity, jahr int, spx int)
create table u2018(id int identity, jahr int, spx int)
create table u2017(id int identity, jahr int, spx int)

--Dennoch soll die ANwendung UMSATZ als Objekt vorfinden

-->View

create view Umsatz
as
select * from u2020
UNION ALL
select * from u2019
UNION ALL
select * from u2018
UNION ALL
select * from u2017


--Messen:
--Kann man nun einen Vorteil messen?

select * from umsatz where jahr = 2019
select * from umsatz where id = 2019



--besser durch: Check Constraints
ALTER TABLE dbo.u2017 ADD CONSTRAINT CK_u2017 CHECK (jahr=2017)
ALTER TABLE dbo.u2018 ADD CONSTRAINT CK_u2018 CHECK (jahr=2018)
ALTER TABLE dbo.u2019 ADD CONSTRAINT CK_u2019 CHECK (jahr=2019)
ALTER TABLE dbo.u2020 ADD CONSTRAINT CK_u2020 CHECK (jahr=2020)


--INS UP DEL auf Sichten möglich?
---ja, aber ...

insert into umsatz (id,jahr, spx) values(1,2017, 100)

--fordert einen PK für alle Tabellen.. 
--Der DS muss auf die Sicht eindeutig sein
--Identity muss raus
--!! und ab jetzt muss der ID Wert manuell gefüllt werden

--> problematisch für die Anwendung!!

--Lösung für eindeutige IDs über mehrere Tabelle stellen Sequenzen dar:

USE [testdb]

CREATE SEQUENCE [dbo].[UID] 
 START WITH 2
 INCREMENT BY 1

select next value for UID


insert into umsatz (id,jahr, spx) values(next value for UID,2018, 100)


select * from umsatz


-----------------------------------------------------------------
-----   physikalische Partitionierung                    --------
-----------------------------------------------------------------

--deutlich flexibler
--transparent für die Anwendung
--einfach administrierbar
--in jeder Edition vorhanden
--großer Vorteil: große Tabellen in kleinere verwaltungstechnische Einheiten --> Wartungsarbeiten bzw Zeiten reduzieren (IX; Statistiken)


--Dateigruppe: Das miTtel schlechthin IO auf meherere Lauwerke zu verteilen


USE [master]
GO
ALTER DATABASE [testdb] ADD FILEGROUP [HOT]
GO
ALTER DATABASE [testdb] ADD FILE ( NAME = N'testhotdata', FILENAME = N'D:\_SQLDB\testhotdata.ndf' , SIZE = 8192KB , FILEGROWTH = 65536KB ) TO FILEGROUP [HOT]
GO



create table t2 (id int) ON HOT

--Lege Dateigruppe HOT mit Datei auf Northwind an.....
--verschiebe die Tabelle Orders auf HOT....??

--geht per Entwurfsansicht in Objektexplorer...  F4 Eigenschaften
--Vorsicht: Löscht Tabelle.. oder ein best IX  CL IX....


--Um uz partitionieren benötigt man 3 Dinge:
--Dateigruppen  wo sollen die Daten liegen
--Partitionsfunktion: wie verteilen wir die Daten
--Partitionsschema: Wer teilt der Tabelle mit, welche DAten wohin sollen.


---physikalische Part:

------------------100]----------------200]------------------- int
--            1                  2               3

--Die Funktion gibt nur die Partitionsnummer zurück: 1,2,3,4,5


create partition function fZahl(int)
as
RANGE LEFT FOR VALUES (100,200)

select $partition.fZahl(117) --> 2


--Das PartSchema bestimmt , welche Dateigruppe hinter welcher Partitionsnummer steckt

--Partschema: f() + Dgruppen
--bis100, bis200, rest, bis5000


--part Scheme

create partition scheme schZahl
as
partition fzahl to (bis100,bis200,rest)
----                  1      2      3
--- Reihenfolge bestimmt die Partitionsnummer



--Datensätze liegen immer dort wo sie lt Funktion und Schema sein müssen..
--insofern werden sie auch verschoben


--Testen

--Tabelle für Demo
create table ptab (id int identity, nummer int, spx char(4100))
		ON schZahl(nummer)

--Schleife für Insert: Keine Pläne anzeigen lassen und keine Statistik Messung
set statistics io, time off

declare @i as int = 0

while @i<=20000
	begin 
		insert into ptab values(@i, 'XY')
		set @i+=1
	end

--besser: Plan und stats
set statistics io, time on

---Messen der Lesitung und Vergleichen. Aber wie ?

select * from ptab where id = 117

select * from ptab where nummer = 117

-----------------Partition anpassen----------------------

--Grenzen:  .... neue Grenze einfügen

----------------100-----200-----------5000------------------
--  1                 2      3                 4


-- Zusätzliche Grenze = weiterer Bereich = Anspassen des Schemas
alter partition scheme schZahl next used bis5000

--aktuelle Verteilung feststellen
select $partition.fZahl(nummer), min(nummer), max(nummer), count(*)
from ptab group by $partition.fzahl(nummer)

-->bisher noch kein physik. Änderung


--Funktion benötigt die neue Grenze

alter partition function fzahl() split range(5000)

--Jetzt entdeckenb wir Änderungen

select $partition.fZahl(nummer), min(nummer), max(nummer), count(*)
from ptab group by $partition.fzahl(nummer)

--Messung mit verschbiedenen Werten

select * from ptab where nummer = 6117


-----100!----------------200------------5000--------------


--Wie sieht die aktuelle Parttiionsfn und Schema aus?

/****** Object:  PartitionScheme [schZahl]    Script Date: 09.12.2020 14:17:10 ******/
CREATE PARTITION SCHEME [schZahl] AS
PARTITION [fZahl] TO ([bis100], [bis200], [bis5000], [rest])

/****** Object:  PartitionFunction [fZahl]    Script Date: 09.12.2020 14:17:31 ******/
CREATE PARTITION FUNCTION [fZahl](int)
AS 
RANGE LEFT FOR VALUES (100, 200, 5000)
GO


-----------Grenzen entfernen-------------------


--Nur Anpassung der Fn notwendig


alter partition function fzahl() merge range (100)


select * from ptab where nummer = 17

--Wie ist die Verteilung
select $partition.fZahl(nummer), min(nummer), max(nummer), count(*)
from ptab group by $partition.fzahl(nummer)



select * from ptab where nummer = 6401

--Was ist nun noch cool?
--Kompression pro Partition möglich


--auch Kompresssion pro Part
ALTER TABLE [dbo].[ptab]
REBUILD PARTITION = 3 
WITH(DATA_COMPRESSION = PAGE )


--oder INDIZES pro Partition
CREATE CLUSTERED INDEX PK_IhreTabelle
ON SchemaName.TabellenName (PartitionsSpalte, AndereSpalte)
ON NameDesPartitionSchemes (PartitionsSpalte);


--oder Statistiken +inkrementelle Statistiken

ALTER DATABASE DBNAME 
SET AUTO_CREATE_STATISTICS ON (INCREMENTAL = ON);


UPDATE STATISTICS Scheme.Tabelle (Spalte)
WITH RESAMPLE ON PARTITIONS (5);



-------------Archivieren------------------------
--Daten, die wir noch aufheben müssen, aber egtl nicht benötigen
--kosten Leistung (SCAN Vorgänge)

--Verschieben von Datensätze in andere Tabelle

create table archiv (id int not null,nummer int, spx char(4100))
	ON bis200 --muss auch die DGruppe, auf der die part liegt..


alter table ptab switch partition 1 to archiv

select * from archiv

select $partition.fZahl(nummer), min(nummer), max(nummer), count(*)
from ptab group by $partition.fzahl(nummer)

--Wie funktioniert das technisch und warum dauert das in der Regel imme rnur Millisekunden


--Tipps für die Praxis------------------------------------------

--Datentypen...

CREATE PARTITION FUNCTION [fZahl](datetime)
AS 
RANGE LEFT FOR VALUES ('','','')
GO ---------------------------korrekt               falsch

--A bis M     N bis R   S bis Z
CREATE PARTITION FUNCTION [fZahl](varchar(50))
AS 
RANGE LEFT FOR VALUES ('','') --kein Wildcards
GO

--nicht sinnvoll
CREATE PARTITION FUNCTION [fZahl](date)
AS 
RANGE LEFT FOR VALUES (Getdate()-30, getdate()+30)
GO


---Möglich??
CREATE PARTITION SCHEME [schZahl] AS
PARTITION [fZahl] TO ([PRIMARY], [PRIMARY], [PRIMARY], [PRIMARY])

--primary ja..geht. ..und macht Sinn, da wir es wie viele kleine Tabellen behandeln
--ab SQL 2016 Sp1 auch in Std oder sogar Express

