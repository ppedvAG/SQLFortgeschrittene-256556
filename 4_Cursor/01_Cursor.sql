
--Vorteile von Cursors
/*
Feinsteuerung: 
Du kannst Zeilen einzeln behandeln und 
komplexe Logik anwenden.

Notwendig bei bestimmten Algorithmen: 
Z. B. bei iterativen Berechnungen, die stark voneinander abhängen.

Gut bei Prototyping oder Ad-Hoc-Abfragen: 
Wenn du mal schnell Daten durchgehen willst.

Nachteile von Cursors
Performance-Probleme:

Cursors arbeiten zeilenweise → langsam bei großen Datenmengen.

Speicherintensiv, da SQL Server Zeilen puffern muss.

Komplexität: 
Mehr Code, mehr Fehlerpotenzial.

Set-Based-Ansatz fast immer schneller: 
Viele Cursor-Szenarien lassen sich mit Joins, 
Window Functions oder UPDATE ... FROM ... besser lösen.

Wann Cursors sinnvoll sind   :
Wenn jede Zeile abhängig von vorherigen Zeilen verarbeitet werden muss.
vs Window Functions

Wenn externe Aufrufe pro Zeile erforderlich sind 
(z. B. Prozeduraufrufe oder Logging).

Wenn du ein algorithmisches Problem hast,
das sich schwer in SQL-Mengenoperationen abbilden lässt.

*/

--Wie gehts?


-------------------------------------------------------
-- Aufbau eines eines Cursor
-------------------------------------------------------

--Schritt 1    CURSOR DEFINIEREN
DECLARE myCursor CURSOR FOR
	SELECT CustomerID, CompanyName 
	FROM Customers;


--Schritt 2      CURSOR ÖFFNEN
OPEN myCursor;

--Schritt 3       CURSOR STARTEN

--1. Werte eines DAtensatzes einer Variablen zurodnen

DECLARE @CustomerID NCHAR(5), @CompanyName NVARCHAR(40);

-- 2.Nächsten Datzensatz holen. 
FETCH NEXT FROM myCursor INTO @CustomerID, @CompanyName;

-- 3. So lange der Currsor nicht am Ende ist Code mit aktuellen Werten der Variablen arbeiten 
-- und mit FECTH_STATUS = 0 den nächsten holen
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'Kunde: ' + @CustomerID + ' - ' + @CompanyName;

    -- nächste Zeile abrufen
    FETCH NEXT FROM myCursor INTO @CustomerID, @CompanyName;
END


--Schritt 4        Cursor schließen und entfernen
--ist der Cursor am Ende angelangt schliessen und aus dem Speicher entfernen

CLOSE myCursor;
DEALLOCATE myCursor;



--Komplettes Beispiel

DECLARE @ProductID INT, @Price MONEY;

DECLARE priceCursor CURSOR FOR
SELECT ProductID, UnitPrice
FROM Products;

OPEN priceCursor;

FETCH NEXT FROM priceCursor INTO @ProductID, @Price;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Beispiel: Erhöhe alle Preise um 10 %
    --UPDATE Products
    --SET UnitPrice = @Price * 1.10
    --WHERE ProductID = @ProductID;
    select * from products where productid = @ProductID

    FETCH NEXT FROM priceCursor INTO @ProductID, @Price;
END

CLOSE priceCursor;
DEALLOCATE priceCursor;



-------------------------------------------------------
-- Navigieren im Cursor
-------------------------------------------------------
--Bewegungen im Cursor:
/*

SCROLL         → Bewegung im Cursor
STATIC         → Kopie der Daten, scrollen möglich  man sieht keine Änderungen
KEYSET         → Änderungen an Zeilen sind sichtbar, scrollen möglich
                 Zeilenmenge fix, Updates sichtbar, 
                 Inserts nicht, Deletes bleiben als „Lücken
DYNAMIC        → immer aktuelle Daten, scrollen möglich
                 Immer live, alle Änderungen
                 (Insert, Update, Delete) sofort sichtbar, 
                 Reihenfolge kann sich ändern.
FORWARD_ONLY   → (Standard) → nur vorwärts, kein Rückwärtsblättern


*/

USE Northwind;
GO

DECLARE @CustomerID NCHAR(5), @CompanyName NVARCHAR(40);

DECLARE custCursor CURSOR SCROLL FOR ---
	SELECT CustomerID, CompanyName FROM Customers
	ORDER BY CustomerID;

OPEN custCursor;

-- Erste Zeile
FETCH FIRST FROM custCursor INTO @CustomerID, @CompanyName;
PRINT 'FIRST: ' + @CustomerID + ' - ' + @CompanyName;

-- 5. Zeile direkt
FETCH ABSOLUTE 5 FROM custCursor INTO @CustomerID, @CompanyName;
PRINT 'ABSOLUTE 5: ' + @CustomerID + ' - ' + @CompanyName;

-- Eine Zeile zurück
FETCH PRIOR FROM custCursor INTO @CustomerID, @CompanyName;
PRINT 'PRIOR: ' + @CustomerID + ' - ' + @CompanyName;

-- Drei Zeilen vorwärts relativ
FETCH RELATIVE 3 FROM custCursor INTO @CustomerID, @CompanyName;
PRINT 'RELATIVE +3: ' + @CustomerID + ' - ' + @CompanyName;

CLOSE custCursor;
DEALLOCATE custCursor;


----------------------------------------------


--Wollen wir mal Alle Zaheln einer Tabellenspalte addieren

--Tabelle erstellen
use northwind
go
drop table t1

create table T1(
		id int identity not null primary key,
		x decimal(8,2) not null default 0,
		spalten char(100) not null default '#'
		)
go

drop table numbers
create table numbers (id int identity , x int)


insert into numbers
select 1
go 20000
--select * from t1
--select abs(checksum(NEWID()))*0.01%20000
insert T1(x)
	select 	0.01 *ABS(checksum(newid()) %20000) from Numbers
		where x<= 20000
		

	-- select CHECKSUM(200.09)
	-- select checksum(*) from Northwind..Customers


--select * from t1
--Errechnen der laufenden Summe


select * from t1


select t1.id,t1.x, sum(t2.x) from t1 inner join t1 t2 on t2.id <= t1.id
group by t1.id,t1.x order by 3


select   T1.id, SUM(t2.x) as rt 
from T1 	inner join T1 as t2 on T2.id <= t1.id
	group by T1.id


	
-- Alternative
select T1.id, (select SUM (t2.x) from T1 as t2 where t2.id <= T1.id) as rt
from t1

--Cursor
-- errechnete Werte in eine temp Tabelle wegschreiben
-- fast forward zum schnellen durchlauf

--Temp Tabelle #t
create table #t(id int not null primary key, s decimal (16,2) not null)

--Variablen mit Spalten der T1 und Spalte @s für Summen
declare @id int, @x decimal(8,2), @s decimal (16,2)
set @s= 0

--Cursor deklarieren
declare #c cursor fast_forward for
	select id, x from t1 order by id
	
--Cursor öffnen
open #c
	-- solange durchlaufen und füllen  bis Ende
	while (1=1)
		begin
		fetch next from #c into @id, @x
		if (@@FETCH_STATUS != 0) break 
		set @s=@s+@x
		
		if @@TRANCOUNT = 0		
			begin tran
			insert #t values (@id,@s)
		
		if (@id %1000) = 0
			commit
	end	
if @@trancount >0
	commit
	close #c
	deallocate #c
	
select * from #t order by id

drop table #t


-- Cursor dann ok, wenn keine mengenbasierende Lösung 


select * from t1

select id, sum(x) over ( order by id  ROWS UNBOUNDED PRECEDING) 
from t1

--oder

select id, x,sum(x) over (order by id) from t1--20000	2001809.82




