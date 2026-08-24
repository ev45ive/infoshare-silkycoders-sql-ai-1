# Top 10 Best-Selling Products by Revenue

Objects used:
- [dbo.FactSales.sql](../RetailDW/Tables/dbo.FactSales.sql)
- [dbo.DimProduct.sql](../RetailDW/Tables/dbo.DimProduct.sql)

## SQL

```sql
SELECT TOP 10
    p.ProductCode,
    p.ProductName,
    SUM(f.GrossAmount) AS TotalRevenue, -- revenue = GrossAmount (Quantity * UnitPrice - DiscountAmount); no NetAmount column exists in FactSales
    SUM(f.Quantity) AS TotalQuantitySold
FROM dbo.FactSales AS f
JOIN dbo.DimProduct AS p ON p.ProductKey = f.ProductKey
GROUP BY p.ProductCode, p.ProductName
ORDER BY TotalRevenue DESC;
```

## Results (8 rows returned, all shown)

| ProductCode | ProductName | TotalRevenue | TotalQuantitySold |
|---|---|---|---|
| P-1001 | Espresso Beans 1kg | 174.98 | 2.0 |
| P-3002 | French Press 1L | 119.00 | 1.0 |
| P-2002 | Earl Grey 100g | 90.00 | 5.0 |
| P-4001 | Oat Milk 1L | 67.40 | 10.0 |
| P-2001 | Green Tea 100g | 45.00 | 3.0 |
| P-1002 | Filter Coffee 500g | 42.00 | 1.0 |
| P-3001 | Ceramic Mug | 24.50 | 1.0 |
| P-5001 | Chocolate Bar 90g | 18.00 | 4.0 |

## Summary / Insights

- Only 8 distinct products appear in `FactSales` (small seeded/staged dataset), so all are shown.
- Espresso Beans 1kg leads by revenue (174.98) despite low quantity (2 units), indicating high unit price.
- Oat Milk 1L has the highest quantity sold (10) but ranks 4th in revenue, reflecting its lower unit price.
