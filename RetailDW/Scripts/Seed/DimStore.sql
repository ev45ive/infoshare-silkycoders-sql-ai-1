PRINT N'  seeding [dbo].[DimStore]';

MERGE [dbo].[DimStore] AS tgt
USING (VALUES
    (1, N'S-WAW-01', N'Warszawa Centrum',  N'Mazowieckie'),
    (2, N'S-WAW-02', N'Warszawa Mokotow',  N'Mazowieckie'),
    (3, N'S-KRK-01', N'Krakow Rynek',      N'Malopolskie'),
    (4, N'S-GDA-01', N'Gdansk Wrzeszcz',   N'Pomorskie'),
    (5, N'S-WRO-01', N'Wroclaw Stare Miasto', N'Dolnoslaskie')
) AS src ([StoreKey], [StoreCode], [StoreName], [Region])
    ON tgt.[StoreKey] = src.[StoreKey]
WHEN MATCHED THEN UPDATE
    SET tgt.[StoreCode] = src.[StoreCode],
        tgt.[StoreName] = src.[StoreName],
        tgt.[Region]    = src.[Region]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([StoreKey], [StoreCode], [StoreName], [Region])
    VALUES (src.[StoreKey], src.[StoreCode], src.[StoreName], src.[Region]);
