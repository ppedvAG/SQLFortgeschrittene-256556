---------------------- ---------------------------
-------          Transactions         ------------
--------------------------------------------------

/*
Transaktionen (TX) sind das Herzstück der Datenintegrität in SQL Server. Ohne sie wäre keine Datenbank verlässlich.


Eine Transaktion fasst mehrere Befehle zu einer einzigen logischen Arbeitseinheit zusammen.

Code:

BEGIN TRAN --TRansaction wird gestartet

COMMIT --wird in der DB fstgeschrieben

ROLLBACK -- Rückgängig

ROLLBACK: sämtliche Änderungen der TRansaction werden rückgängig gemacht

Auch ohne BEGIN TRAN ist jede Änderung eine Transaction, die aber nach Ende keine Möglichkeit bietet
einen Rollback zu machen  --implizite TX

TX sollten so kurz wie möglich sein. #Sperren
keine TX, die Benutzerinteraktionen erforden (eingabe von ...)


*/

--explizite TX
begin transaction
	ins orders.. sperre auf orders
	up  customers --sperren auf customers
	del
	del
	ins
	up
commit-- wird das ganze bestätigt--fix
rollback --macht alles rückgämgig


--DEMO TX mit ROLLBACK
select * from orders
begin tran
update orders set freight = 100
	where orderid = 10248

	select * from orders
--commit
rollback
select * from orders


--Sperrniveau: Zeile (nur wenn IX vorliegt), Seite 


-------------------------------------
----   MARK -------------------------
-------------------------------------

--MIT MARK läßt sich ein Rollback antattf auf Sekunden auch den Zeitpunkt vor Beginn einer bestimmten TX
--ein Restore durchführen

-- 1. Der Entwickler startet das Update mit Markierung
BEGIN TRANSACTION KritischesUpdate WITH MARK 'Preisanpassung Q1';
    UPDATE Produkte SET Preis = Preis * 100; -- Hoppla, Fehler! Viel zu teuer!
COMMIT TRANSACTION;

-- ... Später merkt man den Fehler ...

-- 2. Der DBA rettet die Situation (Restore)
-- Er muss keine Uhrzeit wissen, nur den Namen 'KritischesUpdate'
RESTORE LOG MeineDatenbank 
FROM DISK = 'Z:\Backups\LogBackup.trn'
WITH STOPBEFOREMARK = 'KritischesUpdate';



-------------------------------------
----   VERSCHACHTELUNG --------------
-------------------------------------

begin transaction t1
	update customers set city = 'X'
	select * from customers

		begin transaction M1 with MARK --- eine Art Lesezeichen: 
		update customers set city = 'Y'
		select * from customers
		
		--rollback  macht zunächst alle rückgangig

	save transaction InnerSave
	select * from customers

		begin transaction M2 with Mark
		update customers set city = 'Z'
		select * from customers



		commit --bestätigt nur die letzte TX 
		select * from customers

rollback tran Innersave
rollback





rollback







