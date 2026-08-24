/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-24
    Description: Weekly rollup. Week number comes from [dbo].[fn_SalesWeek] so that
                 the business definition of a week lives in exactly one place.

    Change log:
    - 2026-08-24 | Ticket: DPO-1187 | Mateusz Kulesza | Claude Sonnet 5 | Add NetAmount (GrossAmount / (1 + VatRate)), computed per row then summed
*/
CREATE VIEW [reporting].[vw_WeeklySales]
AS
SELECT  DATEPART(YEAR, f.[SalesDate])   AS [SalesYear],
        [dbo].[fn_SalesWeek](f.[SalesDate]) AS [SalesWeek],
        st.[Region],
        SUM(f.[Quantity])    AS [Quantity],
        SUM(f.[GrossAmount]) AS [GrossAmount],
        CAST(SUM(f.[GrossAmount] / (1 + f.[VatRate])) AS DECIMAL(18, 4)) AS [NetAmount], -- per-row VAT back-out, summed within the group
        COUNT_BIG(*)         AS [LineCount]
FROM    [dbo].[FactSales] AS f
JOIN    [dbo].[DimStore]  AS st ON st.[StoreKey] = f.[StoreKey]
GROUP BY DATEPART(YEAR, f.[SalesDate]),
         [dbo].[fn_SalesWeek](f.[SalesDate]),
         st.[Region];
