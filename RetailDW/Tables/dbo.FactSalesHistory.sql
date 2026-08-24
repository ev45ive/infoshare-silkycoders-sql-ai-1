/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-23
    Description: History table for the temporal table [dbo].[FactSales]. Kept as
                 an explicit object so schema changes are reviewable in source
                 control. IMPORTANT: column list and data types must stay in sync
                 with [dbo].[FactSales].

    Change log:
    - 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Add SnapshotID (NOT NULL) to stay in sync with dbo.FactSales; existing rows backfilled in PreDeployment.sql before this constraint is enforced
*/
CREATE TABLE [dbo].[FactSalesHistory]
(
    [SalesKey]       BIGINT          NOT NULL,
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
    [LoadId]         INT             NOT NULL,
    [SnapshotID]     INT             NOT NULL,
    [ValidFrom]      DATETIME2 (7)   NOT NULL,
    [ValidTo]        DATETIME2 (7)   NOT NULL
);
GO

CREATE CLUSTERED INDEX [IX_FactSalesHistory_Period]
    ON [dbo].[FactSalesHistory] ([ValidTo] ASC, [ValidFrom] ASC);
