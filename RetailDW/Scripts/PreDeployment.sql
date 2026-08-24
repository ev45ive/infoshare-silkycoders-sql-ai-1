/*
Pre-deployment script
---------------------
Runs BEFORE the schema diff is applied.

Use it only for operations that must happen before SQLPackage touches the
schema, e.g. disabling SYSTEM_VERSIONING on temporal tables so that columns
can be added to both the current and the history table.

Keep every statement idempotent - this script runs on every publish.

Change log:
- 2026-08-24 | Ticket: DPO-1204 | Mateusz Kulesza | Claude Sonnet 5 | Add + backfill
  SnapshotID on dbo.FactSales/dbo.FactSalesHistory and enforce NOT NULL here, before
  the schema diff runs, so the diff sees an already-compliant column (see note below).
*/
PRINT N'[PreDeployment] start';

-- DPO-1204: dbo.FactSales.SnapshotID ships as NOT NULL with no default.
-- The schema diff (which applies the table model files) runs AFTER this script,
-- so a bare "ADD SnapshotID INT NOT NULL" in the model would fail against a
-- table that already has rows (no default to fill them). Instead: add the
-- column here as NULL, backfill it, then ALTER to NOT NULL here too - by the
-- time the diff runs, dbo.FactSales.sql / dbo.FactSalesHistory.sql already
-- match the live schema (NOT NULL) and the diff is a no-op for this column.
-- Guarded by COL_LENGTH so this migration only ever runs once.
IF COL_LENGTH('dbo.FactSales', 'SnapshotID') IS NULL
BEGIN
    PRINT N'[PreDeployment] DPO-1204: adding + backfilling SnapshotID';

    -- Direct UPDATE against the history table is blocked while
    -- SYSTEM_VERSIONING is ON, so it must be turned off for the backfill.
    ALTER TABLE [dbo].[FactSales] SET (SYSTEM_VERSIONING = OFF);

    ALTER TABLE [dbo].[FactSales] ADD [SnapshotID] INT NULL;
    ALTER TABLE [dbo].[FactSalesHistory] ADD [SnapshotID] INT NULL;

    UPDATE [dbo].[FactSales] SET [SnapshotID] = [LoadId] WHERE [SnapshotID] IS NULL;
    UPDATE [dbo].[FactSalesHistory] SET [SnapshotID] = [LoadId] WHERE [SnapshotID] IS NULL;

    ALTER TABLE [dbo].[FactSales] ALTER COLUMN [SnapshotID] INT NOT NULL;
    ALTER TABLE [dbo].[FactSalesHistory] ALTER COLUMN [SnapshotID] INT NOT NULL;

    ALTER TABLE [dbo].[FactSales] SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = [dbo].[FactSalesHistory], DATA_CONSISTENCY_CHECK = ON));
END
ELSE
BEGIN
    PRINT N'[PreDeployment] DPO-1204: SnapshotID already present, skipping';
END

PRINT N'[PreDeployment] end';
GO
