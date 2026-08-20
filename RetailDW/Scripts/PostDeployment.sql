/*
Post-deployment script
----------------------
Runs AFTER the schema diff is applied.

Responsibilities:
  1. Seed / refresh reference (dimension) data.
  2. Run data migrations for this release.
  3. Append one row to [dbo].[DeploymentHistory].

Keep every statement idempotent - this script runs on every publish.
*/
PRINT N'[PostDeployment] start';
GO

:r .\Seed\DimProduct.sql
GO

:r .\Seed\DimStore.sql
GO

-- ---------------------------------------------------------------------------
-- Deployment audit
-- ---------------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM [dbo].[DeploymentHistory] WHERE [ScriptName] = N'baseline')
BEGIN
    INSERT INTO [dbo].[DeploymentHistory] ([ScriptName], [Notes])
    VALUES (N'baseline', N'Initial RetailDW schema: dimensions, temporal FactSales, staging, ETL.');
END
GO

PRINT N'[PostDeployment] end';
GO
