--Seiten und Blöcke

--Seiten und Blöcke

-->  8192 -96 Header(Infos zur Seiten - 36 mind Systemoverhead (+2bytes pro Zeile für Soltarray. Wo beginnt ein Datensatz..)
/*
1  Seiten = 8192bytes
max 8072 bytes Datenvolumen
1 DS mit fixen Längen max 8060byts und muss in Seite passen
max 700 DS pro Seite

8 zusammenhängende Seiten = Block

Seite = Page 
Block = Extent .. auf Effizienzgründen werden immer Extents reserviert

Mixed Extents: verschiedene Tabellen und Indizes in einem Block
Uniform Extents: alle Seiten gehören zu einem Objekt

SQL kann mur mit einem Thread eine Seite lesen. 
Zwei Zugriffe auf die selbe Seiten ergeben einen Latch oder auch Spinocks
Latch = supended, Spinlocks sind aktiv

in-row data:
Normale Daten (wie INT, DATETIME, CHAR) müssen zusammen in diese 8.060 Bytes passen. 
Eine einzelne Zeile kann also nicht "breiter" als eine Seite sein.
also alle DAtentypen , mit fixen Längen

row-overflow data
Wenn du Spalten wie VARCHAR(8000) nutzt und die Summe der Daten 8.060 Bytes überschreitet,
verschiebt SQL Server die überschüssigen Daten auf eine neue Seite. Genauer gsagt werden nur die Spalten verschoben, die var. sind
In der ursprünglichen Zeile bleibt nur ein 24-Byte-Zeiger (Pointer) zurück.


LOB Data
Datentypen wie VARCHAR(MAX), NVARCHAR(MAX) oder VARBINARY(MAX) werden standardmäßig komplett
"out-of-row" gespeichert, wenn sie groß sind. In der Hauptseite belegen sie dann fast keinen Platz. Ansonsten in-row.
Man kann aber LOB Daten explizit auslagern:

EXEC sp_tableoption 'DeineTabelle', 'large value types out of row', 1;

Performance: Liest man Tabellendaten un dbeötigt die LOB DAten nicht, hat man den Vorteil, das deutlich mehr Datensätze in einer 
in-row Seite passen und geraten dadurcuh auch nicht in den RAM

Prüfung

SELECT index_id, index_level,
    alloc_unit_type_desc, 
    page_count, 
    avg_page_space_used_in_percent, 
    record_count
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('SalesLT.Product'), NULL, NULL, 'DETAILED');



dbcc showcontig('Tabelle')

*/

use northwind;
GO


create table t1 (id int identity, spx char(4100));
GO


insert into t1 
select 'XY'
GO 20000
--Zeit Messen


dbcc shwocontig('')



select * from sys.dm_db_index_physical_stats(db_id(), object_id(''), NULL, NULL, 'detailed')
GO



use northwind;
GO


create table t1 (id int identity, spx char(4100));
GO


insert into t1 
select 'XY'
GO 20000
--Zeit Messen

--veraltet
dbcc showcontig('')


--besser
select * from sys.dm_db_index_physical_stats(db_id(), object_id(''), NULL, NULL, 'detailed')
GO



--Warum hat die Tabelle t1 160MB , bei ca 80MB Daten
--Warum liest man aus der Tabelle KU 57000, wenn der dbcc nur 41000 Seiten angibt