# Ticket DPO-1187

**Reported by:** Jane Kowalski (Finance / Reporting team)
**Priority:** Medium
**Component:** `reporting.vw_DailySales`
**Sign-off by:** Jane Kowalski

## Why

Finance runs a monthly VAT reconciliation and needs a net-of-discount amount
per day/region/category so they stop recomputing it manually in Excel from
`GrossAmount` and `DiscountAmount`.

## Description

Add a computed `NetAmount` column to `reporting.vw_DailySales`, equal to
`GrossAmount - DiscountAmount`, aggregated at the same grain as the existing
columns (`SalesDate`, `Region`, `CategoryName`).

## Acceptance criteria

- [ ] `reporting.vw_DailySales` returns a new column `NetAmount` of type `DECIMAL(18,2)`.
- [ ] `NetAmount = SUM(GrossAmount) - SUM(DiscountAmount)` for each existing group (`SalesDate`, `Region`, `CategoryName`).
- [ ] No existing column is renamed, removed, or reordered.
- [ ] `reporting.vw_WeeklySales` is unaffected (out of scope for this ticket).

## Edge cases

- Rows where `DiscountAmount` is `NULL`: treated as `0` (no discount), not excluded from the aggregate.
- A day/region/category with zero matching sales rows: no row is produced, same as today — `NetAmount` is never a row of zeros.
- `DiscountAmount` greater than `GrossAmount` (over-discounted line): `NetAmount` is allowed to be negative; not clamped to zero.

## Rollback / reversibility

View-only change, no stored data is modified. Rollback is dropping/reverting
the column in the view definition — no backfill or history impact.
