/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-23
    Description: System-versioned (temporal) fact table holding one row per sold
                 order line. Source of truth for revenue/VAT reporting views and
                 the monthly Excel summary refresh job.

    Change log:
    - 2026-08-23 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Remove Snapshot - will be added in next exercise
    - 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Add SnapshotID (NOT NULL, no default); existing rows backfilled with SnapshotID = LoadId in PreDeployment.sql before this constraint is enforced
*/
CREATE TABLE [dbo].[FactSales]
(
    [SalesKey]       BIGINT          NOT NULL,
    [SalesOrderNo]   NVARCHAR (30)   NOT NULL,
    [SalesLineNo]    INT             NOT NULL,
    [SalesDate]      DATE            NOT NULL,
    [ProductKey]     INT             NOT NULL,
    [StoreKey]       INT             NOT NULL,
    [Quantity]       DECIMAL (18, 4) NOT NULL,
    [UnitPrice]      DECIMAL (18, 4) NOT NULL,
    [DiscountAmount] DECIMAL (18, 4) NOT NULL CONSTRAINT [DF_FactSales_DiscountAmount] DEFAULT (0),
    [GrossAmount]    DECIMAL (18, 4) NOT NULL, -- computed in ETL as (Quantity * UnitPrice) - DiscountAmount
    [VatRate]        DECIMAL (5, 4)  NOT NULL, -- per-row rate; products can differ, so NetAmount is derived per row, not per group
    [SourceSystem]   NVARCHAR (20)   NOT NULL,
    [LoadId]         INT             NOT NULL,
    [SnapshotID]     INT             NOT NULL, -- source-data version id (independent of LoadId); no default, see PreDeployment.sql for the backfill/NOT NULL migration
    [ValidFrom]      DATETIME2 (7)   GENERATED ALWAYS AS ROW START NOT NULL, -- system-versioning period; do not set manually
    [ValidTo]        DATETIME2 (7)   GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_FactSales] PRIMARY KEY CLUSTERED ([SalesKey] ASC),
    CONSTRAINT [UQ_FactSales_OrderLine] UNIQUE NONCLUSTERED ([SalesOrderNo] ASC, [SalesLineNo] ASC),
    CONSTRAINT [FK_FactSales_DimProduct] FOREIGN KEY ([ProductKey]) REFERENCES [dbo].[DimProduct] ([ProductKey]),
    CONSTRAINT [FK_FactSales_DimStore] FOREIGN KEY ([StoreKey]) REFERENCES [dbo].[DimStore] ([StoreKey]),
    CONSTRAINT [FK_FactSales_LoadLog] FOREIGN KEY ([LoadId]) REFERENCES [dbo].[LoadLog] ([LoadId]),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[FactSalesHistory], DATA_CONSISTENCY_CHECK = ON)); -- old row versions kept in FactSalesHistory
GO

CREATE NONCLUSTERED INDEX [IX_FactSales_SalesDate]
    ON [dbo].[FactSales] ([SalesDate] ASC)
    INCLUDE ([ProductKey], [StoreKey], [GrossAmount]);
