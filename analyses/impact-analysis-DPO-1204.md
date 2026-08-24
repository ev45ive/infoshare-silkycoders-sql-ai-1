# Impact Analysis — DPO-1204: Add `SnapshotID` to `dbo.FactSales`

**Ticket:** [exercises/ticket-DPO-1204-snapshot-id.md](../exercises/ticket-DPO-1204-snapshot-id.md)
**Date:** 2026-08-24
**Status:** Draft — one item below needs live verification before implementation starts.

## 1. Data flow and objects touched

```
stg.Sales (SnapshotID INT NULL, new)
    → etl.LoadFactSales
        - #FtData temp table (carries SnapshotID)
        - RowsRejected validation (add SnapshotID IS NULL check)
        - MERGE INSERT branch (write SnapshotID)
        - MERGE UPDATE branch (write SnapshotID)
        - MERGE WHEN MATCHED AND (...) change-detection (add SnapshotID comparison)
    → dbo.FactSales (SnapshotID INT NOT NULL, new)
        → dbo.FactSalesHistory (auto, system-versioned history — same column, no separate DDL needed beyond keeping the two table definitions in sync)
```

Files:
- [RetailDW/Tables/stg.Sales.sql](../RetailDW/Tables/stg.Sales.sql) — add `SnapshotID INT NULL`. All other data columns here are already nullable ("Everything is nullable on purpose... validation happens in etl.LoadFactSales" per existing header comment). No formal POS-extract-to-column mapping doc exists in this repo; the staging seed INSERTs *are* the mapping.
- [RetailDW/Tables/dbo.FactSales.sql](../RetailDW/Tables/dbo.FactSales.sql) — add `SnapshotID INT NOT NULL`, no default. System-versioned (`SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.FactSalesHistory, ...)`).
- [RetailDW/Tables/dbo.FactSalesHistory.sql](../RetailDW/Tables/dbo.FactSalesHistory.sql) — header comment states column list/types "must stay in sync with dbo.FactSales." Whether this file needs a manual edit or SQL Server keeps it in sync automatically on publish is the open item in §2.
- [RetailDW/Procedures/etl.LoadFactSales.sql](../RetailDW/Procedures/etl.LoadFactSales.sql):
  - `#FtData` temp table definition — add `SnapshotID INT`.
  - Reject-count query (LEFT JOIN + WHERE pattern, existing lines ~60–73) — add `OR s.[SnapshotID] IS NULL` alongside the existing `ProductCode`/`StoreCode`/`SalesDate`/`Quantity`/`UnitPrice` checks. Mechanical addition, same pattern.
  - `MERGE ... WHEN MATCHED AND (...)` change-detection condition — add `OR tgt.[SnapshotID] <> src.[SnapshotID]` so a snapshot-only change still produces an `UPDATE` (ticket's explicit edge case).
  - `MERGE ... WHEN NOT MATCHED THEN INSERT` — add `SnapshotID` to column list and VALUES.
  - `MERGE ... WHEN MATCHED ... THEN UPDATE SET` — add `SnapshotID = src.SnapshotID`.
- [RetailDW/Scripts/PostDeployment.sql](../RetailDW/Scripts/PostDeployment.sql) — one-time backfill of existing rows: `SnapshotID = LoadId` for both `dbo.FactSales` and `dbo.FactSalesHistory`. Must be idempotent (script runs on every publish) — a `WHERE SnapshotID <> LoadId` or a NULL-based guard (see §2) keeps repeat runs a no-op.
- [data/01-staging-batch-1.sql](../data/01-staging-batch-1.sql) — seed INSERTs need a `SnapshotID` column/value added (test-coverage phase, and needed for smoke test to keep passing).

**Not touched (confirmed, read-only check):** `reporting.vw_DailySales`, `reporting.vw_TopProductsByRevenue`, `reporting.vw_WeeklySales`, `reporting.usp_SalesSummaryByMonth` — all use explicit column lists / aggregates, none do `SELECT *` against `dbo.FactSales`, so none will silently pick up the new column. Matches the ticket's "reporting unchanged" requirement — no edit needed there.

## 2. Open questions (must be resolved before implementation)

1. **[BLOCKING — needs live verification, not yet tested]** Whether `dbo.FactSales` (system-versioned, explicit `HISTORY_TABLE = dbo.FactSalesHistory`) requires `SYSTEM_VERSIONING` to be turned OFF to:
   - (a) add a nullable column, and
   - (b) later `ALTER COLUMN ... NOT NULL` once backfilled.

   My understanding from SQL Server documentation (not verified by actually running it against this container) is that both operations are supported directly while `SYSTEM_VERSIONING = ON`, and SQL Server auto-propagates the same column to the history table — disabling versioning is normally only required for period-column changes or dropping the temporal relationship itself. **I have not run this against the live container** (no execute-capable tool was available in this session), so per this repo's rule against asserting unverified SQL Server behavior, this must be confirmed before the implementation phase writes the `ALTER TABLE` sequence. Two ways to close this:
   - You run a throwaway test (scratch temporal table, add nullable column, backfill, alter to NOT NULL, drop scratch table) and share the result, or
   - Authorize an execute-capable agent/session to run that scratch test.

2. Does `dbo.FactSalesHistory.sql` need a manual DDL edit in this repo (SDK-style DB project — schema is authored per file, not purely inferred from a live diff), or does the project's build/publish pipeline auto-generate the history table schema from `dbo.FactSales.sql`? Needs a check of how `dbo.FactSalesHistory.sql` is currently written (does it already fully enumerate matching columns, implying it must be manually kept in sync per the file's own header comment) before implementation.
3. Backfill idempotency pattern for `PostDeployment.sql`: since `SnapshotID` will not exist as NULL for long (backfilled once, then NOT NULL), what guard makes the backfill statement safe to re-run on every publish once the column is already NOT NULL? (e.g., `WHERE SnapshotID = 0` won't work since 0 is a valid id; a NULL-check only works before the NOT NULL constraint is applied). This affects how PreDeployment/PostDeployment staging of the ALTER sequence is ordered relative to when the NOT NULL constraint gets applied by the schema diff itself vs. a manual post-step.

## 3. Step-by-step change list (draft, pending §2 answers)

1. `RetailDW/Tables/stg.Sales.sql` — add `SnapshotID INT NULL`.
2. `RetailDW/Tables/dbo.FactSales.sql` — add `SnapshotID INT NOT NULL` (exact ALTER mechanics depend on §2.1/§2.2 answers).
3. `RetailDW/Tables/dbo.FactSalesHistory.sql` — update only if §2.2 confirms manual sync is required.
4. `RetailDW/Procedures/etl.LoadFactSales.sql` — `#FtData`, reject-count WHERE, MERGE INSERT/UPDATE/change-detection, per §1.
5. `RetailDW/Scripts/PostDeployment.sql` — backfill existing rows, pattern per §2.3 answer.
6. `data/01-staging-batch-1.sql` — add `SnapshotID` values to existing seed rows (test-coverage phase, but flagging here since it's required for the smoke test to keep passing after `stg.Sales`/`dbo.FactSales` change).

## 4. Test plan

- Smoke test: add assertion that no `dbo.FactSales`/`dbo.FactSalesHistory` row has `SnapshotID IS NULL` after publish + backfill.
- Regression test (`schema-change-tests-suite` skill, phase 4): NULL `SnapshotID` in staging → rejected + counted in `RowsRejected`; same business key reloaded with only `SnapshotID` changed → produces `UPDATE` + new history row; backfilled pre-existing rows have `SnapshotID = LoadId`.

## 5. Rollback / backfill note

Per ticket: drop `SnapshotID` from `dbo.FactSales` (temporal-safe `ALTER TABLE` — same unresolved mechanics as §2.1) and from `stg.Sales`; revert `etl.LoadFactSales` changes. Historical `dbo.FactSalesHistory` rows already written with `SnapshotID` are not retroactively cleaned up (ticket explicitly accepts this).
