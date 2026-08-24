/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-24
    Description: Daily sales aggregate used by the operational reporting layer.

    Change log:
    - 2026-08-24 | Ticket: DPO-1187 | Mateusz Kulesza | Claude Sonnet 5 | Add NetAmount (GrossAmount / (1 + VatRate)), computed per row then summed
*/
CREATE VIEW [reporting].[vw_DailySales]
AS
SELECT  f.[SalesDate],
        st.[Region],
        p.[CategoryName],
        SUM(f.[Quantity])       AS [Quantity],
        SUM(f.[GrossAmount])    AS [GrossAmount],
        SUM(f.[DiscountAmount]) AS [DiscountAmount],
        CAST(SUM(f.[GrossAmount] / (1 + f.[VatRate])) AS DECIMAL(18, 4)) AS [NetAmount], -- per-row VAT back-out, summed within the group
        COUNT_BIG(*)            AS [LineCount]
FROM    [dbo].[FactSales]   AS f
JOIN    [dbo].[DimProduct]  AS p  ON p.[ProductKey] = f.[ProductKey]
JOIN    [dbo].[DimStore]    AS st ON st.[StoreKey]  = f.[StoreKey]
GROUP BY f.[SalesDate], st.[Region], p.[CategoryName];
