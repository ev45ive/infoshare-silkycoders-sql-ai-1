/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-23
    Description: Raw landing zone for POS sales extracts. Everything is nullable
                 on purpose: the source system is not trusted and validation
                 happens in [etl].[LoadFactSales].

    Change log:
    - 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Add SnapshotID (nullable, validated downstream in etl.LoadFactSales)
*/
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
    [SnapshotID]     INT             NULL, -- source-data version/batch id from the POS extract; required downstream, see etl.LoadFactSales
    [SourceSystem]   NVARCHAR (20)   NULL,
    [LoadedAt]       DATETIME2 (3)   NOT NULL CONSTRAINT [DF_stg_Sales_LoadedAt] DEFAULT (SYSUTCDATETIME()),
    CONSTRAINT [PK_stg_Sales] PRIMARY KEY CLUSTERED ([StagingRowId] ASC)
);
