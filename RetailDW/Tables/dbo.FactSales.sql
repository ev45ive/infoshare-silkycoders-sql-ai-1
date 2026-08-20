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
    [GrossAmount]    DECIMAL (18, 4) NOT NULL,
    [VatRate]        DECIMAL (5, 4)  NOT NULL,
    [SourceSystem]   NVARCHAR (20)   NOT NULL,
    [SnapshotID]     INT             NULL,
    [LoadId]         INT             NOT NULL,
    [ValidFrom]      DATETIME2 (7)   GENERATED ALWAYS AS ROW START NOT NULL,
    [ValidTo]        DATETIME2 (7)   GENERATED ALWAYS AS ROW END   NOT NULL,
    CONSTRAINT [PK_FactSales] PRIMARY KEY CLUSTERED ([SalesKey] ASC),
    CONSTRAINT [UQ_FactSales_OrderLine] UNIQUE NONCLUSTERED ([SalesOrderNo] ASC, [SalesLineNo] ASC),
    CONSTRAINT [FK_FactSales_DimProduct] FOREIGN KEY ([ProductKey]) REFERENCES [dbo].[DimProduct] ([ProductKey]),
    CONSTRAINT [FK_FactSales_DimStore] FOREIGN KEY ([StoreKey]) REFERENCES [dbo].[DimStore] ([StoreKey]),
    CONSTRAINT [FK_FactSales_LoadLog] FOREIGN KEY ([LoadId]) REFERENCES [dbo].[LoadLog] ([LoadId]),
    PERIOD FOR SYSTEM_TIME ([ValidFrom], [ValidTo])
)
WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[FactSalesHistory], DATA_CONSISTENCY_CHECK = ON));
GO

CREATE NONCLUSTERED INDEX [IX_FactSales_SalesDate]
    ON [dbo].[FactSales] ([SalesDate] ASC)
    INCLUDE ([ProductKey], [StoreKey], [GrossAmount]);
