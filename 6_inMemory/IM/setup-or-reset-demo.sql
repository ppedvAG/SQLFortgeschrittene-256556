-- setup script for the TicketReservations In-Memory OLTP perf demo
--
-- Requires a database with the name TicketReservations
--
-- Applies To: SQL Server 2014 (or higher); Azure SQL Database
-- Author: Jos de Bruijn (Microsoft)
-- Last Updated: 2016-06-06
create database [TicketReservations]
GO
USE [TicketReservations]
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;



-- 1. validate that In-Memory OLTP is supported
IF SERVERPROPERTY(N'IsXTPSupported') = 0 
BEGIN                                    
    PRINT N'Error: In-Memory OLTP is not supported for this server edition or database pricing tier.';
END 
IF DB_ID() < 5
BEGIN                                    
    PRINT N'Error: In-Memory OLTP is not supported in system databases. Connect to a user database.';
END 
ELSE 
BEGIN 
	BEGIN TRY;
-- 2. add MEMORY_OPTIMIZED_DATA filegroup when not using Azure SQL DB
	IF SERVERPROPERTY('EngineEdition') != 5 
	BEGIN
		DECLARE @SQLDataFolder nvarchar(max) = cast(SERVERPROPERTY('InstanceDefaultDataPath') as nvarchar(max))
		DECLARE @MODName nvarchar(max) = DB_NAME() + N'_mod';
		DECLARE @MemoryOptimizedFilegroupFolder nvarchar(max) = @SQLDataFolder + @MODName;

		DECLARE @SQL nvarchar(max) = N'';

		-- add filegroup
		IF NOT EXISTS (SELECT 1 FROM sys.filegroups WHERE type = N'FX')
		BEGIN
			SET @SQL = N'
ALTER DATABASE CURRENT 
ADD FILEGROUP ' + QUOTENAME(@MODName) + N' CONTAINS MEMORY_OPTIMIZED_DATA;';
			EXECUTE (@SQL);

		END;

		-- add container in the filegroup
		IF NOT EXISTS (SELECT * FROM sys.database_files WHERE data_space_id IN (SELECT data_space_id FROM sys.filegroups WHERE type = N'FX'))
		BEGIN
			SET @SQL = N'
ALTER DATABASE CURRENT
ADD FILE (name = N''' + @MODName + ''', filename = '''
						+ @MemoryOptimizedFilegroupFolder + N''') 
TO FILEGROUP ' + QUOTENAME(@MODName);
			EXECUTE (@SQL);
		END
	END

	-- 3. set compat level to 130 if it is lower
	IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()) < 130
		ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 130 

	-- 4. enable MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT for the database
	ALTER DATABASE CURRENT SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT = ON;


    END TRY
    BEGIN CATCH
        PRINT N'Error enabling In-Memory OLTP';
		IF XACT_STATE() != 0
			ROLLBACK;
        THROW;
    END CATCH;
END
GO

DROP PROCEDURE IF EXISTS dbo.ReadMultipleReservations
DROP PROCEDURE IF EXISTS dbo.BatchInsertReservations
DROP PROCEDURE IF EXISTS [dbo].[InsertReservationDetails]
DROP SEQUENCE IF EXISTS [dbo].[TicketReservationSequence]
DROP TABLE IF EXISTS [dbo].[TicketReservationDetail]
GO

CREATE SEQUENCE [dbo].[TicketReservationSequence] 
 AS [int]
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE  50000 
GO

CREATE TABLE [dbo].[TicketReservationDetail]
(
	[TicketReservationID] [bigint] NOT NULL,
	[TicketReservationDetailID] [bigint] IDENTITY(1,1) NOT NULL,
	[Quantity] [int] NOT NULL,
	[FlightID] [int] NOT NULL,
	[Comment] [nvarchar](1000) NULL,

		CONSTRAINT [PK_TicketReservationDetail]  PRIMARY KEY 
	(
		[TicketReservationDetailID] ASC
	)
)
GO

CREATE PROCEDURE InsertReservationDetails
		(@TicketReservationID int, 
		@LineCount int, 
		@Comment NVARCHAR(1000), @FlightID int)
AS
BEGIN 
	DECLARE @loop int = 0;
	while (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment) 
			VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END
GO

CREATE PROCEDURE BatchInsertReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN
	DECLARE @tranCount int = 0;
	DECLARE @TS Datetime2;
	DECLARE @Char_TS NVARCHAR(23);
	DECLARE @CurrentSeq int = 0;

	SET @TS = SYSDATETIME();
	SET @Char_TS = CAST(@TS AS NVARCHAR(23));
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			BEGIN TRAN
			SET @CurrentSeq = NEXT VALUE FOR TicketReservationSequence ;
			EXEC InsertReservationDetails  @CurrentSeq, @RowsPerTransaction, @Char_TS, @ThreadID;
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
GO
		
CREATE PROCEDURE ReadMultipleReservations(@ServerTransactions int, @RowsPerTransaction int, @ThreadID int)
AS
BEGIN 
	DECLARE @tranCount int = 0;
	DECLARE @CurrentSeq int = 0;
	DECLARE @Sum int = 0;
	DECLARE @loop int = 0;
	WHILE (@tranCount < @ServerTransactions)	
	BEGIN
		BEGIN TRY
			SELECT @CurrentSeq = RAND() * IDENT_CURRENT(N'dbo.TicketReservationDetail')
			SET @loop = 0
			BEGIN TRAN
			WHILE (@loop < @RowsPerTransaction)
			BEGIN
				SELECT @Sum += FlightID from dbo.TicketReservationDetail where TicketReservationDetailID = @CurrentSeq - @loop;
				SET @loop += 1;
			END
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			IF XACT_STATE() = -1
				ROLLBACK TRAN
			;THROW
		END CATCH
		SET @tranCount += 1;
	END
END
GO
