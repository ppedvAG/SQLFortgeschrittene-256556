USE [master]
GO

-- 1. Alten Loopback löschen (falls vorhanden)
IF EXISTS (SELECT * FROM sys.servers WHERE name = 'LOOPBACK')
BEGIN
    EXEC sp_dropserver 'LOOPBACK', 'droplogins';
END
GO

-- 2. Neu anlegen mit explizitem "Encrypt=no"
-- Hinweis: Wir nutzen @provstr (Provider String), um die Optionen zu setzen
EXEC sp_addlinkedserver 
    @server = N'LOOPBACK', 
    @srvproduct = N'', 
    @provider = N'MSOLEDBSQL', -- Oder 'SQLNCLI', falls du den alten Treiber nutzt
    @datasrc = @@SERVERNAME, 
    @provstr = N'Encrypt=no;'; -- <--- HIER IST DER ENTSCHEIDENDE TEIL
GO

-- 3. Wichtige Einstellungen setzen (RPC für Prozeduren, Data Access für Abfragen)
EXEC sp_serveroption @server = N'LOOPBACK', @optname = N'data access', @optvalue = N'true';
EXEC sp_serveroption @server = N'LOOPBACK', @optname = N'rpc', @optvalue = N'true';
EXEC sp_serveroption @server = N'LOOPBACK', @optname = N'rpc out', @optvalue = N'true';
-- Verhindert Distributed Transaction Fehler beim Loopback
EXEC sp_serveroption @server = N'LOOPBACK', @optname = N'remote proc transaction promotion', @optvalue = N'false'; 
GO


EXEC sp_serveroption 
    @server = 'LOOPBACK', 
    @optname = 'remote proc transaction promotion', 
    @optvalue = 'false'; -- Das ist der Schlüssel!

ALTER TRIGGER trg_PreventTableDrop
ON DATABASE
FOR DROP_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName NVARCHAR(255) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)');
    DECLARE @SQL NVARCHAR(MAX);

    -- Wir bauen einen dynamischen SQL String, der über den Linked Server ausgeführt wird
    -- WICHTIG: Ersetze 'DeineDatenbank' mit deinem echten DB-Namen
    SET @SQL = 'INSERT INTO LOOPBACK.northwind.dbo.DDLChangeLog (EventType, ObjectName, TSQLCommand, LoginName) 
                VALUES (''DROP_TABLE (VERHINDERT)'', ''' + @ObjectName + ''', ''ROLLBACK durch Trigger'', ''' + SUSER_SNAME() + ''')';

    -- Führe den Insert in einer separaten Transaktion aus
    EXEC (@SQL);

    -- Jetzt das eigentliche Event rückgängig machen
    PRINT 'FEHLER: Das Löschen von Tabellen ist nicht erlaubt!';
    ROLLBACK TRANSACTION;
END;
GO


--TABELLE FÜR LOGGING
CREATE TABLE dbo.DDLChangeLog (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    EventType NVARCHAR(100),
    ObjectName NVARCHAR(255),
    TSQLCommand NVARCHAR(MAX),
    LoginName NVARCHAR(128),
    EventDate DATETIME DEFAULT GETDATE()
);
GO