-- Raw landing zone. Everything is nullable on purpose: the source system
-- is not trusted and validation happens in [etl].[LoadFactSales].
CREATE TABLE [stg].[Sales]
(
    [StagingRowId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderNo]   NVARCHAR (30)   NULL,
    [SalesLineNo]    INT             NULL,
    [SalesDate]      DATE            NULL,
    [ProductCode]    NVARCHAR (20)   NULL,
    [StoreCode]      NVARCHAR (20)   NULL,
    [Quantity]       DECIMAL (18, 4) NULL,
    [UnitPrice]      DECIMAL (18, 4) NULL,
    [DiscountAmount] DECIMAL (18, 4) NULL,
    [SourceSystem]   NVARCHAR (20)   NULL,
    [SnapshotID]     INT             NULL,
    [LoadedAt]       DATETIME2 (3)   NOT NULL CONSTRAINT [DF_stg_Sales_LoadedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_stg_Sales] PRIMARY KEY CLUSTERED ([StagingRowId] ASC)
);
