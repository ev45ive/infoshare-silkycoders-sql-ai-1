---
description: SQL team conventions
applyTo: *.sql
---

## Naming

- **Schemas:** `dbo` (core warehouse), `stg` (staging, always disposable), `etl` (load procedures), and `reporting` (read-only consumer-facing objects).
- **Tables:** `PascalCase`; dimensions are prefixed with `Dim`, and facts are prefixed with `Fact`.
- **Constraints:** `PK_`, `FK_`, `UQ_`, `DF_` (default), `CK_` (check), and `IX_`/`UX_` (index).
- Every object name is wrapped in brackets (`[brackets]`) in DDL to match the existing style.

## Migration & deployment rules

- Schema changes go through the `.sqlproj` model, never a hand-run `ALTER` outside `PostDeployment.sql` or a reviewed migration script.
- Every deployment that backfills or migrates existing data appends exactly one row to `dbo.DeploymentHistory`.
- **Temporal tables (`dbo.FactSales` / `dbo.FactSalesHistory`): do not claim an operation requires disabling `SYSTEM_VERSIONING` unless you have run a query that proves it.** See `docs/reference/temporal-restrictions.md`; most schema changes (`ADD`/`ALTER`/`DROP COLUMN`) work with versioning ON and propagate to the history table automatically. Only `UPDATE`/`DELETE` directly against the history table and `TRUNCATE` on the current table are blocked.

## Testing requirements

- Every change ships with a test in `tests/`.
- A test must fail loudly — no silent pass, no swallowed errors.
- It is acceptable for a test to fail because an object or column does not exist yet, as long as the failure message says so clearly.

