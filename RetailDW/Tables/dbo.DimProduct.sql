CREATE TABLE [dbo].[DimProduct]
(
    [ProductKey]   INT            NOT NULL,
    [ProductCode]  NVARCHAR (20)  NOT NULL,
    [ProductName]  NVARCHAR (100) NOT NULL,
    [CategoryName] NVARCHAR (50)  NOT NULL,
    [VatRate]      DECIMAL (5, 4) NOT NULL CONSTRAINT [DF_DimProduct_VatRate] DEFAULT (0.2300),
    [IsActive]     BIT            NOT NULL CONSTRAINT [DF_DimProduct_IsActive] DEFAULT (1),
    CONSTRAINT [PK_DimProduct] PRIMARY KEY CLUSTERED ([ProductKey] ASC)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [UX_DimProduct_ProductCode]
    ON [dbo].[DimProduct] ([ProductCode] ASC);
