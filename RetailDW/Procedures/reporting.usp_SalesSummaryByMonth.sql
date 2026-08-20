-- Monthly sales summary consumed by the Excel refresh job.
-- @YearMonth is passed as 'YYYY-MM' by the caller.
CREATE PROCEDURE [reporting].[usp_SalesSummaryByMonth]
    @YearMonth NVARCHAR (7)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT  st.[Region],
            p.[CategoryName],
            SUM(f.[Quantity])       AS [Quantity],
            SUM(f.[GrossAmount])    AS [GrossAmount],
            SUM(f.[DiscountAmount]) AS [DiscountAmount],
            COUNT_BIG(*)            AS [LineCount]
    FROM    [dbo].[FactSales]  AS f
    JOIN    [dbo].[DimProduct] AS p  ON p.[ProductKey] = f.[ProductKey]
    JOIN    [dbo].[DimStore]   AS st ON st.[StoreKey]  = f.[StoreKey]
    WHERE   CONVERT(NVARCHAR (7), f.[SalesDate], 126) = @YearMonth
    GROUP BY st.[Region], p.[CategoryName]
    ORDER BY st.[Region], p.[CategoryName];
END
