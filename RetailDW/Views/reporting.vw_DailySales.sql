-- Daily sales aggregate used by the operational reporting layer.
-- TODO (DPO-1187): reporting asked for a net amount column.
CREATE VIEW [reporting].[vw_DailySales]
AS
SELECT  f.[SalesDate],
        st.[Region],
        p.[CategoryName],
        SUM(f.[Quantity])       AS [Quantity],
        SUM(f.[GrossAmount])    AS [GrossAmount],
        SUM(f.[DiscountAmount]) AS [DiscountAmount],
        COUNT_BIG(*)            AS [LineCount]
FROM    [dbo].[FactSales]   AS f
JOIN    [dbo].[DimProduct]  AS p  ON p.[ProductKey] = f.[ProductKey]
JOIN    [dbo].[DimStore]    AS st ON st.[StoreKey]  = f.[StoreKey]
GROUP BY f.[SalesDate], st.[Region], p.[CategoryName];
