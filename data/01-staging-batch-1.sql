/*
Sample staging batch #1 for RetailDW.

Deliberately contains rows that must be rejected or de-duplicated so that the
baseline load exercises the validation logic in [etl].[LoadFactSales]:

  * 8 clean rows            -> loaded
  * 1 unknown ProductCode   -> rejected
  * 1 unknown StoreCode     -> rejected
  * 1 NULL Quantity         -> rejected
  * 1 duplicate business key with a newer LoadedAt -> de-duplicated (newest wins)
  * DiscountAmount NULL     -> treated as 0

Change log:
- 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Add a
  SnapshotID value to every existing row so rows stay loadable now that
  stg.Sales.SnapshotID is validated (rejected if NULL) by etl.LoadFactSales.
  No new NULL-SnapshotID scenario added here - that's the test-coverage phase.
*/
SET NOCOUNT ON;

DELETE FROM [stg].[Sales];

INSERT INTO [stg].[Sales]
    ([SalesOrderNo], [SalesLineNo], [SalesDate], [ProductCode], [StoreCode],
     [Quantity], [UnitPrice], [DiscountAmount], [SnapshotID], [SourceSystem], [LoadedAt])
VALUES
    -- clean rows -------------------------------------------------------------
    (N'SO-2026-0001', 1, '2026-01-05', N'P-1001', N'S-WAW-01',  2.0000,  89.9900,  5.0000, 1, N'POS', '2026-01-06T02:00:00'),
    (N'SO-2026-0001', 2, '2026-01-05', N'P-3001', N'S-WAW-01',  1.0000,  24.5000,  NULL,   1, N'POS', '2026-01-06T02:00:00'),
    (N'SO-2026-0002', 1, '2026-01-05', N'P-2001', N'S-KRK-01',  3.0000,  15.0000,  0.0000, 1, N'POS', '2026-01-06T02:00:00'),
    (N'SO-2026-0003', 1, '2026-01-06', N'P-4001', N'S-GDA-01', 10.0000,   6.9900,  2.5000, 2, N'POS', '2026-01-07T02:00:00'),
    (N'SO-2026-0003', 2, '2026-01-06', N'P-5001', N'S-GDA-01',  4.0000,   4.5000,  NULL,   2, N'POS', '2026-01-07T02:00:00'),
    (N'SO-2026-0004', 1, '2026-01-07', N'P-1002', N'S-WRO-01',  1.0000,  42.0000,  0.0000, 2, N'POS', '2026-01-08T02:00:00'),
    (N'SO-2026-0005', 1, '2026-01-07', N'P-3002', N'S-WAW-02',  1.0000, 129.0000, 10.0000, 2, N'POS', '2026-01-08T02:00:00'),
    (N'SO-2026-0006', 1, '2026-02-02', N'P-2002', N'S-KRK-01',  5.0000,  18.0000,  0.0000, 3, N'POS', '2026-02-03T02:00:00'),

    -- rejected: product code not present in DimProduct -----------------------
    (N'SO-2026-0007', 1, '2026-02-02', N'P-9999', N'S-KRK-01',  1.0000,  10.0000,  0.0000, 3, N'POS', '2026-02-03T02:00:00'),

    -- rejected: store code not present in DimStore ---------------------------
    (N'SO-2026-0008', 1, '2026-02-02', N'P-1001', N'S-ZZZ-99',  1.0000,  89.9900,  0.0000, 3, N'POS', '2026-02-03T02:00:00'),

    -- rejected: mandatory measure missing ------------------------------------
    (N'SO-2026-0009', 1, '2026-02-02', N'P-1001', N'S-WAW-01',  NULL,    89.9900,  0.0000, 3, N'POS', '2026-02-03T02:00:00'),

    -- duplicate business key: the newer row must win -------------------------
    (N'SO-2026-0002', 1, '2026-01-05', N'P-2001', N'S-KRK-01',  9.9900,  15.0000,  0.0000, 1, N'POS', '2026-01-05T22:00:00'),

    -- different source system: must be ignored by a POS load -----------------
    (N'WEB-2026-0001', 1, '2026-01-05', N'P-1001', N'S-WAW-01', 1.0000,  89.9900,  0.0000, 1, N'WEB', '2026-01-06T02:00:00');

PRINT N'stg.Sales loaded with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' rows (last statement).';
SELECT [TotalStagedRows] = COUNT(*) FROM [stg].[Sales];
