/*
Post-deployment script
----------------------
Runs AFTER the schema diff is applied.

Responsibilities:
  1. Seed / refresh reference (dimension) data.
  2. Run data migrations for this release.
  3. Append one row to [dbo].[DeploymentHistory].

Keep every statement idempotent - this script runs on every publish.

Change log:
- 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Record the
  SnapshotID backfill in DeploymentHistory. NOTE: the actual ADD/backfill/NOT NULL
  work for SnapshotID runs in Scripts/PreDeployment.sql, not here - it must
  complete before the schema diff enforces NOT NULL, which happens between Pre-
  and PostDeployment.
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

IF NOT EXISTS (SELECT 1 FROM [dbo].[DeploymentHistory] WHERE [ScriptName] = N'DPO-1204-backfill-snapshotid')
BEGIN
    INSERT INTO [dbo].[DeploymentHistory] ([ScriptName], [Notes])
    VALUES (N'DPO-1204-backfill-snapshotid', N'Added SnapshotID to dbo.FactSales/dbo.FactSalesHistory (NOT NULL, no default); existing rows backfilled with SnapshotID = LoadId in Scripts/PreDeployment.sql.');
END
GO

PRINT N'[PostDeployment] end';
GO
