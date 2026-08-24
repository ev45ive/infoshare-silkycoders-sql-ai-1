/*
RetailDW smoke test
-------------------
Fast confidence check that the deployed database is usable.
Fails loudly (RAISERROR severity 16) on the first broken assertion.

Run AFTER:
  1. sqlpackage publish
  2. data\01-staging-batch-1.sql
  3. EXEC etl.LoadFactSales @SourceSystem = N'POS'
*/
SET NOCOUNT ON;

DECLARE @Failures INT = 0;

-- ---------------------------------------------------------------------------
PRINT N'--- 1. objects exist -------------------------------------------------';

DECLARE @Expected TABLE ([ObjectName] SYSNAME NOT NULL);

INSERT INTO @Expected ([ObjectName])
VALUES (N'dbo.DimProduct'), (N'dbo.DimStore'), (N'dbo.FactSales'),
       (N'dbo.FactSalesHistory'), (N'dbo.LoadLog'), (N'dbo.DeploymentHistory'),
       (N'stg.Sales'), (N'etl.LoadFactSales'), (N'etl.PurgeStaging'),
       (N'reporting.vw_DailySales'), (N'reporting.vw_WeeklySales'),
       (N'reporting.vw_TopProductsByRevenue'),
       (N'reporting.usp_SalesSummaryByMonth'), (N'dbo.fn_SalesWeek');

SELECT @Failures = @Failures + COUNT(*)
FROM   @Expected AS e
WHERE  OBJECT_ID(e.[ObjectName]) IS NULL;

SELECT N'MISSING OBJECT' AS [Problem], e.[ObjectName]
FROM   @Expected AS e
WHERE  OBJECT_ID(e.[ObjectName]) IS NULL;

-- ---------------------------------------------------------------------------
PRINT N'--- 2. FactSales is system-versioned ---------------------------------';

IF NOT EXISTS (
    SELECT 1
    FROM   sys.tables AS t
    JOIN   sys.tables AS h ON h.[object_id] = t.[history_table_id]
    WHERE  t.[object_id] = OBJECT_ID(N'dbo.FactSales')
      AND  t.[temporal_type] = 2                    -- SYSTEM_VERSIONED_TEMPORAL_TABLE
      AND  h.[name] = N'FactSalesHistory')
BEGIN
    PRINT N'FAIL: dbo.FactSales is not system-versioned into dbo.FactSalesHistory';
    SET @Failures += 1;
END

-- ---------------------------------------------------------------------------
PRINT N'--- 3. dimensions are seeded -----------------------------------------';

IF (SELECT COUNT(*) FROM [dbo].[DimProduct]) < 10
BEGIN PRINT N'FAIL: dbo.DimProduct has fewer than 10 rows'; SET @Failures += 1; END

IF (SELECT COUNT(*) FROM [dbo].[DimStore]) < 5
BEGIN PRINT N'FAIL: dbo.DimStore has fewer than 5 rows'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 4. baseline load result ------------------------------------------';

DECLARE @FactRows     INT = (SELECT COUNT(*) FROM [dbo].[FactSales]),
        @Succeeded    INT = (SELECT COUNT(*) FROM [dbo].[LoadLog] WHERE [Status] = N'SUCCEEDED'),
        @RowsRejected INT = (SELECT TOP (1) [RowsRejected] FROM [dbo].[LoadLog]
                             WHERE [Status] = N'SUCCEEDED' ORDER BY [LoadId] DESC);

PRINT N'  dbo.FactSales rows          : ' + CAST(@FactRows AS NVARCHAR(10));
PRINT N'  successful loads in LoadLog : ' + CAST(@Succeeded AS NVARCHAR(10));
PRINT N'  rejected rows (last load)   : ' + CAST(ISNULL(@RowsRejected, -1) AS NVARCHAR(10));

IF @FactRows <> 8
BEGIN PRINT N'FAIL: expected 8 rows in dbo.FactSales'; SET @Failures += 1; END

IF @Succeeded < 1
BEGIN PRINT N'FAIL: no successful load recorded in dbo.LoadLog'; SET @Failures += 1; END

IF ISNULL(@RowsRejected, -1) <> 3
BEGIN PRINT N'FAIL: expected RowsRejected = 3 on the last successful load'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 5. de-duplication picked the newest staged row -------------------';

IF NOT EXISTS (SELECT 1 FROM [dbo].[FactSales]
               WHERE [SalesOrderNo] = N'SO-2026-0002' AND [SalesLineNo] = 1 AND [Quantity] = 3.0000)
BEGIN
    PRINT N'FAIL: SO-2026-0002/1 should carry Quantity = 3.0000 (newest staged row wins)';
    SET @Failures += 1;
END

-- ---------------------------------------------------------------------------
PRINT N'--- 6. NULL discount became 0 ----------------------------------------';

IF EXISTS (SELECT 1 FROM [dbo].[FactSales] WHERE [DiscountAmount] IS NULL)
BEGIN PRINT N'FAIL: dbo.FactSales contains NULL DiscountAmount'; SET @Failures += 1; END

-- ---------------------------------------------------------------------------
PRINT N'--- 7. reporting layer is queryable ----------------------------------';

BEGIN TRY
    DECLARE @Sink INT;
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_DailySales];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_WeeklySales];
    SELECT @Sink = COUNT(*) FROM [reporting].[vw_TopProductsByRevenue];
    EXEC [reporting].[usp_SalesSummaryByMonth] @YearMonth = N'2026-01';
END TRY
BEGIN CATCH
    PRINT N'FAIL: reporting layer raised: ' + ERROR_MESSAGE();
    SET @Failures += 1;
END CATCH

-- ---------------------------------------------------------------------------
-- SO-2026-0002/1 (Malopolskie/Tea, 2026-01-05) is the only fact row in its
-- daily and weekly grouping, so its expected NetAmount can be computed from
-- known seed values: GrossAmount = 3.0000 * 15.0000 - 0 = 45.0000,
-- VatRate (P-2001/Tea) = 0.2300.
PRINT N'--- 8. NetAmount is present and correct on vw_DailySales --------------';

DECLARE @ExpectedNetAmount DECIMAL(18, 4) = CAST(45.0000 / (1 + 0.2300) AS DECIMAL(18, 4));
DECLARE @DailyNetAmount DECIMAL(18, 4);

SELECT @DailyNetAmount = [NetAmount]
FROM   [reporting].[vw_DailySales]
WHERE  [SalesDate] = '2026-01-05' AND [Region] = N'Malopolskie' AND [CategoryName] = N'Tea';

IF @DailyNetAmount IS NULL
BEGIN PRINT N'FAIL: vw_DailySales.NetAmount missing for 2026-01-05/Malopolskie/Tea'; SET @Failures += 1; END
ELSE IF @DailyNetAmount <> @ExpectedNetAmount
BEGIN
    PRINT N'FAIL: vw_DailySales.NetAmount = ' + CAST(@DailyNetAmount AS NVARCHAR(20))
        + N', expected ' + CAST(@ExpectedNetAmount AS NVARCHAR(20));
    SET @Failures += 1;
END

-- ---------------------------------------------------------------------------
PRINT N'--- 9. NetAmount is present and correct on vw_WeeklySales -------------';

DECLARE @WeeklyNetAmount DECIMAL(18, 4);

SELECT @WeeklyNetAmount = [NetAmount]
FROM   [reporting].[vw_WeeklySales]
WHERE  [SalesYear] = DATEPART(YEAR, '2026-01-05')
   AND [SalesWeek] = [dbo].[fn_SalesWeek]('2026-01-05')
   AND [Region]    = N'Malopolskie';

IF @WeeklyNetAmount IS NULL
BEGIN PRINT N'FAIL: vw_WeeklySales.NetAmount missing for the 2026-01-05 week/Malopolskie'; SET @Failures += 1; END
ELSE IF @WeeklyNetAmount <> @ExpectedNetAmount
BEGIN
    PRINT N'FAIL: vw_WeeklySales.NetAmount = ' + CAST(@WeeklyNetAmount AS NVARCHAR(20))
        + N', expected ' + CAST(@ExpectedNetAmount AS NVARCHAR(20));
    SET @Failures += 1;
END

-- ---------------------------------------------------------------------------
PRINT N'======================================================================';
IF @Failures = 0
    PRINT N'SMOKE TEST PASSED';
ELSE
BEGIN
    DECLARE @Msg NVARCHAR (200) = N'SMOKE TEST FAILED: ' + CAST(@Failures AS NVARCHAR(10)) + N' assertion(s).';
    RAISERROR (@Msg, 16, 1);
END
