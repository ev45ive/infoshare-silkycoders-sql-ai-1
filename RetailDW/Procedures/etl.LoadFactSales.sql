/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-23
    Description: Loads validated rows from [stg].[Sales] into the temporal fact
                 table [dbo].[FactSales] and records the outcome in
                 [dbo].[LoadLog].

    Change log:
    - 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Carry SnapshotID through #FtData, reject NULL SnapshotID, include it in the MERGE INSERT/UPDATE branches and change-detection
*/
-- =============================================================================
-- etl.LoadFactSales
--
-- Loads validated rows from [stg].[Sales] into the temporal fact table
-- [dbo].[FactSales] and records the outcome in [dbo].[LoadLog].
--
-- Flow: stg.Sales -> #FtData -> MERGE -> dbo.FactSales (-> dbo.FactSalesHistory)
-- =============================================================================
CREATE PROCEDURE [etl].[LoadFactSales]
    @SourceSystem NVARCHAR (20) = N'POS',
    @LoadId       INT           = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @RowsInserted INT = 0,
            @RowsUpdated  INT = 0,
            @RowsRejected INT = 0;

    -- Open the load log entry outside the transaction so that a failed load
    -- still leaves an auditable trace.
    INSERT INTO [dbo].[LoadLog] ([PackageName], [SourceSystem])
    VALUES (N'etl.LoadFactSales', @SourceSystem);

    SET @LoadId = CAST(SCOPE_IDENTITY() AS INT);

    BEGIN TRY
        CREATE TABLE #FtData
        (
            [SalesKey]       BIGINT          NULL,
            [SalesOrderNo]   NVARCHAR (30)   NOT NULL,
            [SalesLineNo]    INT             NOT NULL,
            [SalesDate]      DATE            NOT NULL,
            [ProductKey]     INT             NOT NULL,
            [StoreKey]       INT             NOT NULL,
            [Quantity]       DECIMAL (18, 4) NOT NULL,
            [UnitPrice]      DECIMAL (18, 4) NOT NULL,
            [DiscountAmount] DECIMAL (18, 4) NOT NULL,
            [GrossAmount]    DECIMAL (18, 4) NOT NULL,
            [VatRate]        DECIMAL (5, 4)  NOT NULL,
            [SourceSystem]   NVARCHAR (20)   NOT NULL,
            [SnapshotID]     INT             NOT NULL,
            PRIMARY KEY CLUSTERED ([SalesOrderNo], [SalesLineNo])
        );

        -- Validate, resolve dimension keys and de-duplicate staging rows.
        -- The latest staged row per business key wins.
        WITH [Ranked] AS
        (
            SELECT  s.[SalesOrderNo],
                    s.[SalesLineNo],
                    s.[SalesDate],
                    p.[ProductKey],
                    st.[StoreKey],
                    s.[Quantity],
                    s.[UnitPrice],
                    ISNULL(s.[DiscountAmount], 0) AS [DiscountAmount],
                    p.[VatRate],
                    s.[SourceSystem],
                    s.[SnapshotID],
                    ROW_NUMBER() OVER (PARTITION BY s.[SalesOrderNo], s.[SalesLineNo]
                                       ORDER BY s.[LoadedAt] DESC, s.[StagingRowId] DESC) AS [RowRank]
            FROM    [stg].[Sales]      AS s
            JOIN    [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
            JOIN    [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
            WHERE   s.[SourceSystem] = @SourceSystem
                AND s.[SalesOrderNo] IS NOT NULL
                AND s.[SalesLineNo]  IS NOT NULL
                AND s.[SalesDate]    IS NOT NULL
                AND s.[Quantity]     IS NOT NULL
                AND s.[UnitPrice]    IS NOT NULL
                AND s.[SnapshotID]   IS NOT NULL
        )
        INSERT INTO #FtData
        (
            [SalesOrderNo], [SalesLineNo], [SalesDate], [ProductKey], [StoreKey],
            [Quantity], [UnitPrice], [DiscountAmount], [GrossAmount], [VatRate], [SourceSystem], [SnapshotID]
        )
        SELECT  [SalesOrderNo],
                [SalesLineNo],
                [SalesDate],
                [ProductKey],
                [StoreKey],
                [Quantity],
                [UnitPrice],
                [DiscountAmount],
                ([Quantity] * [UnitPrice]) - [DiscountAmount] AS [GrossAmount],
                [VatRate],
                [SourceSystem],
                [SnapshotID]
        FROM    [Ranked]
        WHERE   [RowRank] = 1;

        SELECT @RowsRejected = COUNT(*)
        FROM   [stg].[Sales]      AS s
        LEFT   JOIN [dbo].[DimProduct] AS p  ON p.[ProductCode] = s.[ProductCode]
        LEFT   JOIN [dbo].[DimStore]   AS st ON st.[StoreCode]  = s.[StoreCode]
        WHERE  s.[SourceSystem] = @SourceSystem
           AND (p.[ProductKey]   IS NULL
             OR st.[StoreKey]    IS NULL
             OR s.[SalesOrderNo] IS NULL
             OR s.[SalesLineNo]  IS NULL
             OR s.[SalesDate]    IS NULL
             OR s.[Quantity]     IS NULL
             OR s.[UnitPrice]    IS NULL
             OR s.[SnapshotID]   IS NULL);

        BEGIN TRANSACTION;

        -- Reuse existing surrogate keys; mint new ones only for new business keys.
        UPDATE  t
        SET     t.[SalesKey] = f.[SalesKey]
        FROM    #FtData          AS t
        JOIN    [dbo].[FactSales] AS f
                ON  f.[SalesOrderNo] = t.[SalesOrderNo]
                AND f.[SalesLineNo]  = t.[SalesLineNo];

        UPDATE  #FtData
        SET     [SalesKey] = NEXT VALUE FOR [dbo].[SalesKeySequence]
        WHERE   [SalesKey] IS NULL;

        DECLARE @MergeActions TABLE ([MergeAction] NVARCHAR (10) NOT NULL);

        MERGE [dbo].[FactSales] WITH (HOLDLOCK) AS tgt
        USING #FtData AS src
            ON  tgt.[SalesOrderNo] = src.[SalesOrderNo]
            AND tgt.[SalesLineNo]  = src.[SalesLineNo]
        WHEN MATCHED AND (   tgt.[SalesDate]      <> src.[SalesDate]
                          OR tgt.[ProductKey]     <> src.[ProductKey]
                          OR tgt.[StoreKey]       <> src.[StoreKey]
                          OR tgt.[Quantity]       <> src.[Quantity]
                          OR tgt.[UnitPrice]      <> src.[UnitPrice]
                          OR tgt.[DiscountAmount] <> src.[DiscountAmount]
                          OR tgt.[GrossAmount]    <> src.[GrossAmount]
                          OR tgt.[VatRate]        <> src.[VatRate]
                          OR tgt.[SnapshotID]     <> src.[SnapshotID])
            THEN UPDATE
                SET tgt.[SalesDate]      = src.[SalesDate],
                    tgt.[ProductKey]     = src.[ProductKey],
                    tgt.[StoreKey]       = src.[StoreKey],
                    tgt.[Quantity]       = src.[Quantity],
                    tgt.[UnitPrice]      = src.[UnitPrice],
                    tgt.[DiscountAmount] = src.[DiscountAmount],
                    tgt.[GrossAmount]    = src.[GrossAmount],
                    tgt.[VatRate]        = src.[VatRate],
                    tgt.[SourceSystem]   = src.[SourceSystem],
                    tgt.[SnapshotID]     = src.[SnapshotID],
                    tgt.[LoadId]         = @LoadId
        WHEN NOT MATCHED BY TARGET
            THEN INSERT ([SalesKey], [SalesOrderNo], [SalesLineNo], [SalesDate],
                         [ProductKey], [StoreKey], [Quantity], [UnitPrice],
                         [DiscountAmount], [GrossAmount], [VatRate], [SourceSystem], [SnapshotID], [LoadId])
                 VALUES (src.[SalesKey], src.[SalesOrderNo], src.[SalesLineNo], src.[SalesDate],
                         src.[ProductKey], src.[StoreKey], src.[Quantity], src.[UnitPrice],
                         src.[DiscountAmount], src.[GrossAmount], src.[VatRate], src.[SourceSystem], src.[SnapshotID], @LoadId)
        OUTPUT $action INTO @MergeActions ([MergeAction]);

        COMMIT TRANSACTION;

        SELECT  @RowsInserted = SUM(CASE WHEN [MergeAction] = N'INSERT' THEN 1 ELSE 0 END),
                @RowsUpdated  = SUM(CASE WHEN [MergeAction] = N'UPDATE' THEN 1 ELSE 0 END)
        FROM    @MergeActions;

        UPDATE  [dbo].[LoadLog]
        SET     [FinishedAt]   = SYSUTCDATETIME(),
                [Status]       = N'SUCCEEDED',
                [RowsInserted] = ISNULL(@RowsInserted, 0),
                [RowsUpdated]  = ISNULL(@RowsUpdated, 0),
                [RowsRejected] = ISNULL(@RowsRejected, 0)
        WHERE   [LoadId] = @LoadId;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        UPDATE  [dbo].[LoadLog]
        SET     [FinishedAt]   = SYSUTCDATETIME(),
                [Status]       = N'FAILED',
                [ErrorMessage] = ERROR_MESSAGE()
        WHERE   [LoadId] = @LoadId;

        THROW;
    END CATCH
END
