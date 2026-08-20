/*
Pre-deployment script
---------------------
Runs BEFORE the schema diff is applied.

Use it only for operations that must happen before SQLPackage touches the
schema, e.g. disabling SYSTEM_VERSIONING on temporal tables so that columns
can be added to both the current and the history table.

Keep every statement idempotent - this script runs on every publish.
*/
PRINT N'[PreDeployment] start';

PRINT N'[PreDeployment] nothing to do';

PRINT N'[PreDeployment] end';
GO
