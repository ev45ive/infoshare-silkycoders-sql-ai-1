-- Removes staging rows that were already processed by a successful load.
CREATE PROCEDURE [etl].[PurgeStaging]
    @SourceSystem   NVARCHAR (20) = N'POS',
    @RetentionHours INT           = 24
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM [stg].[Sales]
    WHERE [SourceSystem] = @SourceSystem
      AND [LoadedAt] < DATEADD(HOUR, -@RetentionHours, SYSUTCDATETIME());
END
