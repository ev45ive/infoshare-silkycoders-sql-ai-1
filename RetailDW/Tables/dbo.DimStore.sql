CREATE TABLE [dbo].[DimStore]
(
    [StoreKey]  INT            NOT NULL,
    [StoreCode] NVARCHAR (20)  NOT NULL,
    [StoreName] NVARCHAR (100) NOT NULL,
    [Region]    NVARCHAR (50)  NOT NULL,
    CONSTRAINT [PK_DimStore] PRIMARY KEY CLUSTERED ([StoreKey] ASC)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_DimStore_StoreCode]
    ON [dbo].[DimStore] ([StoreCode] ASC);
