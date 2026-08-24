/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-24
    Description: Products ranked by total revenue (GrossAmount), all-time,
                 for ad-hoc/BI consumers. No TOP N in the view; consumers
                 apply their own limit.

    Change log:
    - 2026-08-24 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Create view
*/
CREATE VIEW [reporting].[vw_TopProductsByRevenue]
AS
SELECT  p.[ProductCode],
        p.[ProductName],
        SUM(f.[GrossAmount]) AS [TotalRevenue],
        SUM(f.[Quantity])    AS [TotalQuantitySold]
FROM    [dbo].[FactSales]  AS f
JOIN    [dbo].[DimProduct] AS p ON p.[ProductKey] = f.[ProductKey]
WHERE   p.[IsActive] = 1
GROUP BY p.[ProductCode], p.[ProductName];
