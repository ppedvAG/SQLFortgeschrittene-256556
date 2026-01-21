-- ============================================================================
-- DML-Trigger in SQL Server
-- ============================================================================
-- 
-- Ein DML-Trigger ist eine spezielle gespeicherte Prozedur, die automatisch
-- ausgeführt wird, wenn ein DML-Ereignis (INSERT, UPDATE, DELETE) auf einer
-- Tabelle auftritt.
--
-- ============================================================================
-- TRIGGER-TYPEN
-- ============================================================================
--
-- 1. AFTER-Trigger (oder FOR-Trigger)
--    - Wird NACH der DML-Operation ausgeführt
--    - Die Datenänderung ist bereits in der Tabelle gespeichert
--    - FOR und AFTER sind synonym verwendbar
--    - Kann auf Tabellen, aber NICHT auf Views angewendet werden
--
-- 2. INSTEAD OF-Trigger
--    - Wird ANSTELLE der DML-Operation ausgeführt
--    - Die ursprüngliche Operation wird NICHT durchgeführt
--    - Muss die gewünschte Aktion selbst implementieren
--    - Kann auf Tabellen UND Views angewendet werden
--
-- ============================================================================
-- SPEZIELLE TABELLEN: INSERTED und DELETED
-- ============================================================================
--
-- INSERTED-Tabelle:
--    - Enthält die neuen Datensätze bei INSERT
--    - Enthält die geänderten Datensätze (neue Werte) bei UPDATE
--    - Ist leer bei DELETE
--
-- DELETED-Tabelle:
--    - Ist leer bei INSERT
--    - Enthält die alten Werte bei UPDATE
--    - Enthält die gelöschten Datensätze bei DELETE
--
-- Beide Tabellen haben die gleiche Struktur wie die Basis-Tabelle
--
-- ============================================================================
-- VORTEILE von DML-Triggern
-- ============================================================================
--
-- + Automatische Durchsetzung von Geschäftsregeln
-- + Zentrale Logik (nicht in jeder Anwendung separat)
-- + Protokollierung von Änderungen (Audit-Trail)
-- + Komplexe Validierungen über mehrere Tabellen hinweg
-- + Referentielle Integrität über mehrere Datenbanken
-- + Automatische Berechnung abgeleiteter Werte
--
-- ============================================================================
-- NACHTEILE von DML-Triggern
-- ============================================================================
--
-- - Versteckte Logik (nicht sofort ersichtlich für Entwickler)
-- - Performance-Einbußen bei großen Datenmengen
-- - Debugging ist komplexer
-- - Können zu unerwarteten Nebeneffekten führen
-- - Trigger-Kaskaden können schwer nachvollziehbar sein
-- - Keine Rückgabewerte möglich
--
-- ============================================================================
-- PSEUDOCODE für Trigger-Erstellung
-- ============================================================================
--
-- CREATE TRIGGER trigger_name
-- ON tabelle
-- AFTER | INSTEAD OF INSERT, UPDATE, DELETE
-- AS
-- BEGIN
--    CODE
-- END;
-- GO
--
-- ============================================================================
-- PRAKTISCHES BEISPIEL: Northwind-Datenbank
-- ============================================================================

-- ============================================================================
-- Beispiel 1: AFTER INSERT Trigger
-- Protokolliert neue Kunden
-- ============================================================================

-- Protokoll-Tabelle erstellen
IF OBJECT_ID('dbo.CustomerLog', 'U') IS NOT NULL
    DROP TABLE dbo.CustomerLog;
GO

CREATE TABLE dbo.CustomerLog (
    CustomerID NCHAR(5),
    CompanyName NVARCHAR(40),
    LogDate DATETIME DEFAULT GETDATE()
);
GO

-- Trigger erstellen
IF OBJECT_ID('trg_Customers_AfterInsert', 'TR') IS NOT NULL
    DROP TRIGGER trg_Customers_AfterInsert;
GO

CREATE TRIGGER trg_Customers_AfterInsert
ON dbo.Customers
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Neue Kunden in Log-Tabelle speichern
    INSERT INTO dbo.CustomerLog (CustomerID, CompanyName)
    SELECT CustomerID, CompanyName
    FROM inserted;
END;
GO

-- Test
INSERT INTO dbo.Customers (CustomerID, CompanyName)
VALUES ('TEST1', 'Test Firma GmbH');

-- Ergebnis
SELECT * FROM dbo.CustomerLog;
GO

-- ============================================================================
-- Beispiel 2: AFTER UPDATE Trigger
-- Protokolliert Namensänderungen
-- ============================================================================

IF OBJECT_ID('trg_Customers_AfterUpdate', 'TR') IS NOT NULL
    DROP TRIGGER trg_Customers_AfterUpdate;
GO

CREATE TRIGGER trg_Customers_AfterUpdate
ON dbo.Customers
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nur wenn CompanyName geändert wurde
    IF UPDATE(CompanyName)
    BEGIN
        INSERT INTO dbo.CustomerLog (CustomerID, CompanyName)
        SELECT 
            i.CustomerID,
            'Alt: ' + d.CompanyName + ' -> Neu: ' + i.CompanyName
        FROM inserted i
        INNER JOIN deleted d ON i.CustomerID = d.CustomerID
        WHERE i.CompanyName <> d.CompanyName;
    END
END;
GO

-- Test
UPDATE dbo.Customers 
SET CompanyName = 'New COMP'
WHERE CustomerID = 'TEST1';

-- Ergebnis
SELECT * FROM dbo.CustomerLog;
GO

--Interessant:
UPDATE dbo.Customers 
SET CompanyName = CompanyName
WHERE CustomerID = 'TEST1';


SELECT * FROM dbo.CustomerLog;

-- ============================================================================
-- Beispiel 3: INSTEAD OF DELETE Trigger
-- Verhindert Löschen, markiert nur als gelöscht
-- ============================================================================

-- Spalte hinzufügen
IF COL_LENGTH('dbo.Customers', 'IsDeleted') IS NULL
BEGIN
    ALTER TABLE dbo.Customers 
    ADD IsDeleted BIT DEFAULT 0;
END;
GO

IF OBJECT_ID('trg_Customers_InsteadOfDelete', 'TR') IS NOT NULL
    DROP TRIGGER trg_Customers_InsteadOfDelete;
GO

CREATE TRIGGER trg_Customers_InsteadOfDelete
ON dbo.Customers
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Nur markieren, nicht löschen
    UPDATE c
    SET IsDeleted = 1
    FROM dbo.Customers c
    INNER JOIN deleted d ON c.CustomerID = d.CustomerID;
    
    -- In Log schreiben
    INSERT INTO dbo.CustomerLog (CustomerID, CompanyName)
    SELECT CustomerID, 'GELÖSCHT: ' + CompanyName
    FROM deleted;
END;
GO

-- Test
DELETE FROM dbo.Customers WHERE CustomerID = 'TEST1';

-- Ergebnis (Datensatz existiert noch!)
SELECT CustomerID, CompanyName, IsDeleted 
FROM dbo.Customers 
WHERE CustomerID = 'TEST1';

SELECT * FROM dbo.CustomerLog;
GO

-- ============================================================================
-- ÜBERSICHT: INSERTED und DELETED Tabellen
-- ============================================================================

/*
Aktion      | INSERTED Inhalt    | DELETED Inhalt
------------|-------------------|------------------
INSERT      | Neue Zeilen       | Leer
UPDATE      | Neue Werte        | Alte Werte
DELETE      | Leer              | Gelöschte Zeilen
*/

-- ============================================================================
-- Aufräumen (Optional)
-- ============================================================================

/*
DROP TRIGGER IF EXISTS trg_Customers_AfterInsert;
DROP TRIGGER IF EXISTS trg_Customers_AfterUpdate;
DROP TRIGGER IF EXISTS trg_Customers_InsteadOfDelete;
DROP TABLE IF EXISTS dbo.CustomerLog;
ALTER TABLE dbo.Customers DROP COLUMN IF EXISTS IsDeleted;
DELETE FROM dbo.Customers WHERE CustomerID = 'TEST1';
*/