# Ticket DPO-1204

**Reported by:** Data Platform team
**Priority:** Medium
**Component:** `dbo.FactSales`, `dbo.FactSalesHistory` (auto, via system versioning), `stg.Sales`, `etl.LoadFactSales`
**Sign-off by:** Mateusz Kulesza

## Why

`SnapshotID` identifies which version of the source data a `FactSales` row reflects,
independent of which ETL run wrote it (`LoadId` already tracks that). It is sourced
from a version/batch id the POS system sends. Not needed for reporting yet —
optionally queryable/filterable in views/reports later, out of scope for this ticket.

## Description

Add `SnapshotID INT NOT NULL` to `dbo.FactSales`, sourced from a new
`SnapshotID INT NULL` column on `stg.Sales` (nullable at staging, like the other
untrusted source columns), populated from the POS extract. `etl.LoadFactSales`
carries the value through `#FtData` and the `MERGE` into `dbo.FactSales`.
`dbo.FactSalesHistory` picks it up automatically since it's the system-versioning
history table for `dbo.FactSales` — no separate change needed there.

Existing rows (in both `dbo.FactSales` and `dbo.FactSalesHistory`) have no real
snapshot value, so they are backfilled with `SnapshotID = LoadId`.

## Acceptance criteria

- [ ] `dbo.FactSales` has `SnapshotID INT NOT NULL` (no default).
- [ ] `stg.Sales` has `SnapshotID INT NULL`, populated from the POS extract.
- [ ] `etl.LoadFactSales` passes `SnapshotID` through `#FtData` and both the
      `INSERT` and `UPDATE` branches of the `MERGE` into `dbo.FactSales`.
- [ ] The `MERGE`'s `WHEN MATCHED AND (...)` change-detection condition includes
      `SnapshotID`, so a row whose only change is a new snapshot value still
      produces an `UPDATE` (and thus a new `dbo.FactSalesHistory` row).
- [ ] Staging rows with a `NULL SnapshotID` are rejected and counted in
      `RowsRejected`, same as the existing required-field validation
      (`ProductCode`, `StoreCode`, `SalesDate`, `Quantity`, `UnitPrice`).
- [ ] `dbo.FactSalesHistory` carries `SnapshotID` for old row versions
      (inherited automatically from system versioning on `dbo.FactSales`).
- [ ] Existing rows in `dbo.FactSales` and `dbo.FactSalesHistory` are backfilled
      with `SnapshotID = LoadId`.
- [ ] `reporting.*` views/procedures are unchanged — surfacing `SnapshotID` in
      reports is out of scope for this ticket.

## Edge cases

- Staging row with `NULL SnapshotID`: rejected, same bucket as other required-field
  validation failures.
- Existing `FactSales`/`FactSalesHistory` rows predating this change: backfilled
  with `SnapshotID = LoadId`.
- Same business key (`SalesOrderNo`/`SalesLineNo`) reloaded with a different
  `SnapshotID` but otherwise identical values: must still trigger an `UPDATE` and a
  new history row (see `MERGE` acceptance criterion above).

## Rollback / reversibility

Drop `SnapshotID` from `dbo.FactSales` (temporal-safe `ALTER TABLE`, since system
versioning must be handled) and from `stg.Sales`; revert the `etl.LoadFactSales`
changes. Historical `dbo.FactSalesHistory` rows already written with `SnapshotID`
are not retroactively cleaned up.

## Original verbatim request

> We need a SnapshotID on FactSales so we can tell loads apart later. Add the column
> and make sure it's there when we look at history too.

(Superseded by the clarified "Why"/"Description" above — the original request said
"tell loads apart", but the confirmed intent is distinguishing data versions, which
`LoadId` does not already cover.)

