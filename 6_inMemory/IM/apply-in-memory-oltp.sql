USE [TicketReservations]
GO

DROP PROCEDURE IF EXISTS [dbo].[InsertReservationDetails]
GO
DROP TABLE IF EXISTS [dbo].[TicketReservationDetail]
GO

CREATE TABLE [dbo].[TicketReservationDetail]
(
	[TicketReservationID] [bigint] NOT NULL,
	[TicketReservationDetailID] [bigint] IDENTITY(1,1) NOT NULL,
	[Quantity] [int] NOT NULL,
	[FlightID] [int] NOT NULL,
	[Comment] [nvarchar](1000) NULL,

 CONSTRAINT [PK_TicketReservationDetail]  PRIMARY KEY NONCLUSTERED HASH
(
	[TicketReservationDetailID] 
) WITH (BUCKET_COUNT=1000000)
)WITH ( MEMORY_OPTIMIZED = ON , DURABILITY = SCHEMA_AND_DATA )

GO

DROP PROCEDURE IF EXISTS [dbo].[InsertReservationDetails]
GO
CREATE PROCEDURE InsertReservationDetails(@TicketReservationID int, @LineCount int, @Comment NVARCHAR(1000), @FlightID int)
WITH NATIVE_COMPILATION, SCHEMABINDING
AS
BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL=SNAPSHOT, LANGUAGE=N'English')
	DECLARE @loop int = 0;
	while (@loop < @LineCount)
	BEGIN
		INSERT INTO dbo.TicketReservationDetail (TicketReservationID, Quantity, FlightID, Comment) 
		    VALUES(@TicketReservationID, @loop % 8 + 1, @FlightID, @Comment);
		SET @loop += 1;
	END
END
GO