-- ============================================================================
-- Beispiel 3: Durchsetzung von Namenskonventionen
-- ============================================================================

IF EXISTS (SELECT 1 FROM sys.triggers WHERE name = 'trg_EnforceNamingConvention' AND parent_class = 0)
    DROP TRIGGER trg_EnforceNamingConvention ON DATABASE;
GO

CREATE TRIGGER trg_EnforceNamingConvention
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ObjectName NVARCHAR(255) = @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(255)');
    
    -- Prüfen: Tabellennamen müssen mit "tbl" beginnen
    IF @ObjectName NOT LIKE 'tbl%'
    BEGIN
        INSERT INTO dbo.DDLChangeLog (EventType, ObjectName, TSQLCommand, LoginName)
        VALUES (
            'CREATE_TABLE (NAMENSKONVENTION VERLETZT)',
            @ObjectName,
            'Tabellenname muss mit "tbl" beginnen',
            SUSER_SNAME()
        );
        
        PRINT 'FEHLER: Tabellennamen müssen mit "tbl" beginnen!';
        ROLLBACK TRANSACTION;
    END;
END;
GO

-- Test (wird fehlschlagen)
CREATE TABLE dbo.BadTableName (ID INT);  -- Fehler!
GO

-- Test (wird funktionieren)
CREATE TABLE dbo.tblGoodTableName (ID INT);  -- OK!
GO

-- Aufräumen
DROP TABLE dbo.tblGoodTableName;
GO

-- Ergebnis
SELECT * FROM dbo.DDLChangeLog;
GO