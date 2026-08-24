-- Weekly rollup. Week number comes from [dbo].[fn_SalesWeek] so that the
-- business definition of a week lives in exactly one place.
CREATE VIEW [reporting].[vw_WeeklySales]
AS
SELECT  DATEPART(YEAR, f.[SalesDate])   AS [SalesYear],
        [dbo].[fn_SalesWeek](f.[SalesDate]) AS [SalesWeek],
        st.[Region],
        SUM(f.[Quantity])    AS [Quantity],
        SUM(f.[GrossAmount]) AS [GrossAmount],
        COUNT_BIG(*)         AS [LineCount]
FROM    [dbo].[FactSales] AS f
JOIN    [dbo].[DimStore]  AS st ON st.[StoreKey] = f.[StoreKey]
GROUP BY DATEPART(YEAR, f.[SalesDate]),
         [dbo].[fn_SalesWeek](f.[SalesDate]),
         st.[Region];
