-- ============================================================================
-- DDL-Trigger in SQL Server
-- ============================================================================
-- 
-- Ein DDL-Trigger reagiert automatisch auf DDL-Ereignisse (Data Definition Language)
-- wie CREATE, ALTER, DROP von Datenbankobjekten.
--
-- DDL-Trigger:
--    - Reagieren auf Schemaänderungen (CREATE, ALTER, DROP)
--    - Wirken auf Datenbank- oder Server-Ebene
--    - Haben Zugriff auf EVENTDATA() Funktion
--
-- ============================================================================
-- GELTUNGSBEREICHE
-- ============================================================================
--
-- 1. DATABASE-Scope (Datenbank-Ebene)
--    - Reagiert auf DDL-Ereignisse innerhalb einer Datenbank
--    - CREATE, ALTER, DROP von Tabellen, Views, Prozeduren, etc.
--    - Syntax: CREATE TRIGGER ... ON DATABASE
--
-- 2. SERVER-Scope (Server-Ebene)
--    - Reagiert auf DDL-Ereignisse auf dem gesamten Server
--    - CREATE, ALTER, DROP von Datenbanken, Logins, etc.
--    - Syntax: CREATE TRIGGER ... ON ALL SERVER
--
-- ============================================================================
-- EVENTDATA() Funktion
-- ============================================================================
--
-- EVENTDATA() gibt XML-Daten über das ausgelöste Ereignis zurück:
--    - EventType: Art des Ereignisses (CREATE_TABLE, DROP_PROCEDURE, etc.)
--    - LoginName: Wer hat die Aktion ausgeführt
--    - TSQLCommand: Das ausgeführte T-SQL Statement
--    - DatabaseName: In welcher Datenbank
--    - SchemaName: Schema des betroffenen Objekts
--    - ObjectName: Name des betroffenen Objekts
--    - ObjectType: Typ des Objekts (TABLE, PROCEDURE, etc.)
--
-- ============================================================================
-- HÄUFIGE DDL-EREIGNISSE
-- ============================================================================
--
-- Tabellen-Ereignisse:
--    - CREATE_TABLE, ALTER_TABLE, DROP_TABLE
--
-- View-Ereignisse:
--    - CREATE_VIEW, ALTER_VIEW, DROP_VIEW
--
-- Prozedur-Ereignisse:
--    - CREATE_PROCEDURE, ALTER_PROCEDURE, DROP_PROCEDURE
--
-- Index-Ereignisse:
--    - CREATE_INDEX, ALTER_INDEX, DROP_INDEX
--
-- Datenbank-Ereignisse:
--    - CREATE_DATABASE, ALTER_DATABASE, DROP_DATABASE
--
-- ============================================================================
-- VORTEILE von DDL-Triggern
-- ============================================================================
--
-- + Überwachung von Schemaänderungen (Audit-Trail)
-- + Verhindern unerwünschter Strukturänderungen
-- + Durchsetzung von Namenskonventionen
-- + Automatische Dokumentation von Änderungen
-- + Benachrichtigungen bei kritischen Änderungen
-- + Compliance und Sicherheitsanforderungen erfüllen
--
-- ============================================================================
-- NACHTEILE von DDL-Triggern
-- ============================================================================
--
-- - Können legitime Wartungsarbeiten blockieren
-- - Erhöhen Komplexität der Datenbankverwaltung
-- - Können Performance bei vielen DDL-Operationen beeinträchtigen
-- - Müssen bei Migrationen beachtet werden
-- - Können Deployment-Prozesse behindern
--
-- ============================================================================
-- PSEUDOCODE für DDL-Trigger
-- ============================================================================
--
-- -- Datenbank-Ebene:
-- CREATE TRIGGER trigger_name
-- ON DATABASE
-- FOR DDL_EVENT_TYPE
-- AS
-- BEGIN
--     DECLARE @EventData XML = EVENTDATA();
--     
--     --Informationen aus EVENTDATA() extrahieren
--     DECLARE @EventType NVARCHAR(100) =  @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)');
--     DECLARE @ObjectName NVARCHAR(255) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)');
--     
--     -- Ihre Logik hier
--     -- Optional: ROLLBACK TRANSACTION (um Änderung zu verhindern)
-- END;
-- GO
--
-- -- Server-Ebene:
-- CREATE TRIGGER trigger_name
-- ON ALL SERVER
-- FOR DDL_EVENT_TYPE
-- AS
-- BEGIN
--     -- Analog zu Datenbank-Ebene
-- END;
-- GO
--
-- ============================================================================
-- EINFACHE BEISPIELE: Northwind-Datenbank
-- ============================================================================

-- ============================================================================
-- Beispiel 1: Protokollierung von Schemaänderungen (DATABASE-Scope)
-- ============================================================================



--Einfachste DEMO
CREATE TRIGGER trgDemo on DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
select eventdata()


create table #t(id int);
GO  --:-)


create  table t1    (id int);
alter   table t1    add sp2 int;
drop    table t1;


--Fieser Trigger
CREATE TRIGGER trg_LMAA on DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
print 'Dumm gelaufen'
rollback;
GO


CREATE TABLE TEST(id int);
GO

DROP TRIGGER trg_LMAA ON DATABASE;
GO


DISABLE TRIGGER trg_LMAA ON DATABASE;
GO

DROP TRIGGER trg_LMAA ON DATABASE;
GO

----------------------------------------------
--         Protokollierung     ---------------
----------------------------------------------

-- Protokoll-Tabelle erstellen
IF OBJECT_ID('dbo.DDLChangeLog', 'U') IS NOT NULL
    DROP TABLE dbo.DDLChangeLog;
GO

CREATE TABLE dbo.DDLChangeLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(255),
    TSQLCommand NVARCHAR(MAX),
    LoginName NVARCHAR(128),
    EventDate DATETIME DEFAULT GETDATE()
);
GO

-- DDL-Trigger erstellen
IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_LogDDLChanges' AND parent_class = 0)
    DROP TRIGGER trg_LogDDLChanges ON DATABASE;
GO

CREATE TRIGGER trg_LogDDLChanges
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    
    INSERT INTO dbo.DDLChangeLog (EventType, ObjectName, TSQLCommand, LoginName)
    VALUES (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)'),
        @EventData.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @EventData.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)')
    );
END;
GO

-- Test: Tabelle erstellen
CREATE TABLE dbo.TestTable (
    ID INT PRIMARY KEY,
    Name NVARCHAR(50)
);
GO

-- Test: Tabelle ändern
ALTER TABLE dbo.TestTable
ADD Description NVARCHAR(100);
GO

-- Test: Tabelle löschen
DROP TABLE dbo.TestTable;
GO

-- Ergebnis prüfen
SELECT * FROM dbo.DDLChangeLog;
GO

-- ============================================================================
-- Beispiel 2: Verhindern des Löschens von Tabellen
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_PreventTableDrop' AND parent_class = 0)
    DROP TRIGGER trg_PreventTableDrop ON DATABASE;
GO

CREATE TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName NVARCHAR(255) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)');
    
    -- Protokollieren
    INSERT INTO dbo.DDLChangeLog (EventType, ObjectName, TSQLCommand, LoginName)
    VALUES (
        'DROP_TABLE (VERHINDERT)',
        @ObjectName,
        'ROLLBACK durch Trigger',
        SUSER_SNAME()
    );
    
    -- Änderung verhindern
    PRINT 'FEHLER: Das Löschen von Tabellen ist nicht erlaubt!';
    ROLLBACK TRANSACTION;
END;
GO








-- ============================================================================
-- EVENTDATA() Struktur - Beispiel
-- ============================================================================

/*
<EVENT_INSTANCE>
  <EventType>CREATE_TABLE</EventType>
  <PostTime>2025-01-15T10:30:00</PostTime>
  <SPID>52</SPID>
  <ServerName>THEBEAST</ServerName>
  <LoginName>sa</LoginName>
  <UserName>dbo</UserName>
  <DatabaseName>Northwind</DatabaseName>
  <SchemaName>dbo</SchemaName>
  <ObjectName>TestTable</ObjectName>
  <ObjectType>TABLE</ObjectType>
  <TSQLCommand>
    <SetOptions ANSI_NULLS="ON" QUOTED_IDENTIFIER="ON" />
    <CommandText>CREATE TABLE dbo.TestTable (ID INT)</CommandText>
  </TSQLCommand>
</EVENT_INSTANCE>
*/

-- ============================================================================
-- VERWALTUNG von DDL-Triggern
-- ============================================================================

-- Alle DDL-Trigger der aktuellen Datenbank anzeigen
SELECT 
    name AS TriggerName,
    CASE parent_class
        WHEN 0 THEN 'DATABASE'
        WHEN 1 THEN 'SERVER'
    END AS Scope,
    create_date AS CreatedDate,
    is_disabled AS IsDisabled
FROM sys.triggers
WHERE parent_class = 0;
GO

-- DDL-Trigger deaktivieren
-- DISABLE TRIGGER trg_LogDDLChanges ON DATABASE;

-- DDL-Trigger aktivieren
-- ENABLE TRIGGER trg_LogDDLChanges ON DATABASE;

-- DDL-Trigger löschen
-- DROP TRIGGER trg_LogDDLChanges ON DATABASE;

-- ============================================================================
-- ÜBERSICHT: DML vs. DDL Trigger
-- ============================================================================

/*
Merkmal          | DML-Trigger                | DDL-Trigger
-----------------|----------------------------|---------------------------
Ereignisse       | INSERT, UPDATE, DELETE     | CREATE, ALTER, DROP
Scope            | Tabelle/View               | DATABASE oder ALL SERVER
Spezielle Daten  | INSERTED, DELETED          | EVENTDATA()
Primärer Zweck   | Datenvalidierung/-audit    | Schema-Überwachung/Schutz
ROLLBACK         | Möglich                    | Möglich
*/

-- ============================================================================
-- Aufräumen (Optional)
-- ============================================================================

/*
-- Trigger entfernen
DROP TRIGGER IF EXISTS trg_LogDDLChanges ON DATABASE;
DROP TRIGGER IF EXISTS trg_PreventTableDrop ON DATABASE;
DROP TRIGGER IF EXISTS trg_EnforceNamingConvention ON DATABASE;

-- Tabellen entfernen
DROP TABLE IF EXISTS dbo.DDLChangeLog;
*/