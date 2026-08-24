# Deployment / publish / test steps

Reference for the RetailDW project lifecycle. All steps are wrapped by
[scripts/dw.sh](../scripts/dw.sh); run them in order, or run
`./scripts/dw.sh baseline` to do all of them at once.

1. **`up`** — starts the SQL Server container (`docker compose up -d`), polls
   with `sqlcmd -Q "SELECT 1"` until ready.
2. **`build`** — `dotnet build RetailDW/RetailDW.sqlproj` → produces
   [RetailDW.dacpac](../RetailDW/bin/Debug/RetailDW.dacpac).
3. **`publish`** — `sqlpackage /Action:Publish` deploys the dacpac to the
   `RetailDW` database on the local container (`127.0.0.1,14330`).
4. **`seed`** — truncates + loads staging batch 1 via
   [data/01-staging-batch-1.sql](../data/01-staging-batch-1.sql) into
   `stg.Sales`.
5. **`etl`** — runs `EXEC etl.LoadFactSales @SourceSystem = N'POS'`, prints the
   resulting [dbo.LoadLog](../RetailDW/Tables/dbo.LoadLog.sql) row.
6. **`smoke`** — runs [tests/smoke-test.sql](../tests/smoke-test.sql), which
   `RAISERROR`s and exits non-zero on the first failed assertion. It checks:
   - all expected objects exist (tables, procs, views, function)
   - `dbo.FactSales` is system-versioned into `dbo.FactSalesHistory`
   - dimensions are seeded (`DimProduct` ≥10 rows, `DimStore` ≥5 rows)
   - baseline load result (exactly 8 rows in `FactSales`, ≥1 succeeded load,
     `RowsRejected = 3` on last load)
   - de-duplication logic picked the newest staged row
   - NULL discounts coerced to 0
   - reporting views/proc are queryable

## Other related commands

- **`diff`** — dacpac-vs-target script, no changes applied.
- **`reset`** — drop + rebuild the database from scratch. Destructive, needs
  confirmation per [AGENTS.md](../AGENTS.md).
- **`sql "..."`** — run an ad-hoc query against the `RetailDW` database.
- **`wsl-memory [GB]`** — ensure WSL2 has enough memory for SQL Server
  (default 3GB).
