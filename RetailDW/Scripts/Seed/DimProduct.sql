PRINT N'  seeding [dbo].[DimProduct]';

MERGE [dbo].[DimProduct] AS tgt
USING (VALUES
    (1,  N'P-1001', N'Espresso Beans 1kg',   N'Coffee',     0.2300, 1),
    (2,  N'P-1002', N'Filter Coffee 500g',   N'Coffee',     0.2300, 1),
    (3,  N'P-2001', N'Green Tea 100g',       N'Tea',        0.2300, 1),
    (4,  N'P-2002', N'Earl Grey 100g',       N'Tea',        0.2300, 1),
    (5,  N'P-3001', N'Ceramic Mug',          N'Accessories',0.2300, 1),
    (6,  N'P-3002', N'French Press 1L',      N'Accessories',0.2300, 1),
    (7,  N'P-4001', N'Oat Milk 1L',          N'Dairy',      0.0500, 1),
    (8,  N'P-4002', N'Whole Milk 1L',        N'Dairy',      0.0500, 1),
    (9,  N'P-5001', N'Chocolate Bar 90g',    N'Snacks',     0.2300, 1),
    (10, N'P-5002', N'Almond Cookies 200g',  N'Snacks',     0.2300, 0)
) AS src ([ProductKey], [ProductCode], [ProductName], [CategoryName], [VatRate], [IsActive])
    ON tgt.[ProductKey] = src.[ProductKey]
WHEN MATCHED THEN UPDATE
    SET tgt.[ProductCode]  = src.[ProductCode],
        tgt.[ProductName]  = src.[ProductName],
        tgt.[CategoryName] = src.[CategoryName],
        tgt.[VatRate]      = src.[VatRate],
        tgt.[IsActive]     = src.[IsActive]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([ProductKey], [ProductCode], [ProductName], [CategoryName], [VatRate], [IsActive])
    VALUES (src.[ProductKey], src.[ProductCode], src.[ProductName], src.[CategoryName], src.[VatRate], src.[IsActive]);
