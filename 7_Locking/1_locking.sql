---------------------------------------------------------
-- SPERREN 
---------------------------------------------------------

/*
--------------------------------------------
Die wichtigsten Sperr-Arten (Lock Modes)
--------------------------------------------
SQL Server setzt Sperren automatisch, um die ACID-Regeln (Datenkonsistenz) zu wahren.

Es gitb folgende Sperrarten:

S (Shared Lock / Gemeinsame Sperre):
	Wann: Beim Lesen (SELECT).
	Effekt: Andere dürfen auch lesen, aber niemand darf schreiben/ändern.

X (Exclusive Lock / Exklusive Sperre):
	Wann: Beim Schreiben (INSERT, UPDATE, DELETE).
	Effekt: Niemand darf zugreifen (weder lesen noch schreiben), 
			bis die Transaktion beendet ist (COMMIT oder ROLLBACK).

U (Update Lock):
	Wann: Wenn SQL Server eine Zeile zum Ändern sucht, aber noch nicht sicher ist, ob er sie wirklich
			ändert.
	Effekt: Verhindert Deadlocks. Nur einer darf ein U-Lock haben. 
			Wenn die Änderung wirklich passiert, wird es zu X umgewandelt.

I (Intent Locks / Absichtssperren):
	Wann: Auf höheren Ebenen (Tabelle/Seite).
	Beispiel (IX): "Ich habe vor (Intent), weiter unten auf einer Zeile ein X-Lock zu setzen."
	Das signalisiert anderen Prozessen: "Lösche nicht die ganze Tabelle, ich arbeite da drin."

Sch (Schema Locks):
Sch-M: Bei DDL-Operationen (Tabelle ändern). Blockiert alles.

-----------------------------------------------------
--Sperrniveaus
-----------------------------------------------------

Die Hierarchie (Granularität)
SQL Server versucht immer, so "klein" wie möglich zu sperren, um Parallelität 
zu erlauben. Bei zu vielen kleinen Sperren (Memory Pressure) kann er 
aber "eskalieren" (Lock Escalation).

RID / Key: Einzelne Zeile (Row ID).
Page: Eine 8KB Datenseite (enthält mehrere Zeilen).
Partition: eine Partition
Object / Table: Die ganze Tabelle.
Database: Die ganze Datenbank.


---------------------------------------------------------------
Isolationsstufen (Transaction Isolation Level)
---------------------------------------------------------------


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED:
	Effekt: Ignoriert S-Sperren anderer. Du liest auch unbestätigte Daten ("Dirty Reads").
	Nutzen: Schnellstes Lesen, keine Blockaden, aber Risiko falscher Daten.

SET TRANSACTION ISOLATION LEVEL READ COMMITTED (Standard):
	Effekt: Du wartest, bis X-Sperren weg sind. Du liest nur bestätigte Daten. 
			S-Sperren werden nach dem Lesen der Zeile sofort wieder freigegeben.

SET TRANSACTION ISOLATION LEVEL REPEATABLE READ:
	Effekt: S-Sperren bleiben bis zum Ende der Transaktion erhalten. Verhindert, 
			dass sich Daten während deiner Transaktion ändern.

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE:
	Effekt: Härteste Stufe. Sperrt sogar Bereiche (Range Locks), 
			damit keine neuen Zeilen eingefügt werden können, die dein Ergebnis ändern würden.

SNAPSHOT:
	Effekt: Nutzt Versionierung (TempDB) statt Sperren. Leser blockieren Schreiber nicht.
	Auf der DB konfigurierebar:

*/

-- WICHTIG: 'WITH ROLLBACK IMMEDIATE' trennt alle anderen Verbindungen sofort!
ALTER DATABASE [DeineDatenbank]
SET READ_COMMITTED_SNAPSHOT ON
WITH ROLLBACK IMMEDIATE;
GO
ALTER DATABASE [DeineDatenbank]  --dann wird das Verhalten zum Standard
SET ALLOW_SNAPSHOT_ISOLATION ON;
GO



/*
---------------------------------------------------------------
Isolationsstufen (Tabellenhinweise)
---------------------------------------------------------------

WITH (NOLOCK): 
	Das Äquivalent zu Read Uncommitted.

WITH (ROWLOCK) / WITH (TABLOCK): 
	Zwingt SQL Server, auf Zeilen- oder Tabellenebene zu sperren (steuert Granularität).

WITH (UPDLOCK): 
	Setzt sofort ein Update-Lock beim Lesen, um sicherzustellen, 
	dass man die Daten später ändern kann (verhindert Deadlocks bei Read-then-Update Szenarien).

WITH (XLOCK): Setzt sofort eine exklusive Sperre (niemand darf lesen), 
			  auch wenn du nur liest.


*/
SELECT * FROM Users WITH (NOLOCK) WHERE ID = 1;