# Ticket DPO-1187

**Reported by:** Finance / Reporting team
**Priority:** Medium
**Component:** `reporting.vw_DailySales`

## Description (verbatim from the ticket system)

> Reporting asked for a net amount column on the daily sales view. Finance needs it
> for the VAT reconciliation they run every month. Can we add column for it please, same view
> they already use.

That is the entire ticket.

## Clarification session — 2026-08-24

### Answers

| # | Question | Answer |
|---|---|---|
| 1 | What does "net amount" mean? | `NetAmount = GrossAmount / (1 + VatRate)` |
| 2 | Which view — `vw_DailySales` or `vw_WeeklySales`? | `vw_DailySales`, and also `vw_WeeklySales` |
| 3 | Does the formula also subtract `DiscountAmount`? (raised after finding `GrossAmount = (Quantity*UnitPrice) - DiscountAmount` in `etl.LoadFactSales.sql`) | No — formula stays `GrossAmount / (1 + VatRate)` as-is; discount is already baked into `GrossAmount` |
| 4 | Per-row or per-group VAT rate calculation? | Per-row — products can have different VAT rates, so it must be `SUM(GrossAmount / (1 + VatRate))` computed per `FactSales` row, then aggregated |
| 5 | Is `vw_WeeklySales` in scope for this ticket? | Yes, same ticket |
| 6 | Precision of `NetAmount`? | Same precision as `GrossAmount` (`DECIMAL(18,4)`) |
| 7 | Named owner/contact? | Mateusz Kulesza (ev45ive@gmail.com) |
| 8 | Sign-off? | Same person — Mateusz Kulesza |
| 9 | Is `reporting.usp_SalesSummaryByMonth` (Excel refresh job) in scope? | No — skip for now, leave as a follow-up |

### Decisions

- `NetAmount = GrossAmount / (1 + VatRate)`, computed **per `FactSales` row**, then `SUM()`'d within each view's existing `GROUP BY` (not summed-gross-then-divided).
- Discount is **not** subtracted again in this formula — `GrossAmount` already excludes `DiscountAmount` at ETL load time.
- Add `NetAmount` as a computed column to both `reporting.vw_DailySales` and `reporting.vw_WeeklySales`.
- `NetAmount` type: `DECIMAL(18,4)`, computed at query time (not stored/persisted).
- Owner and sign-off: Mateusz Kulesza (ev45ive@gmail.com).

### Open questions

- Should `VatRate = 0` (e.g. VAT-exempt products) be treated as a normal case (`NetAmount = GrossAmount`), or does it need special handling? — raised, not yet answered.
- Zero-row date/region/category groups: confirmed no special handling needed, but not explicitly signed off.
- Does this ticket need to account for historical `FactSalesHistory` data, or is it purely forward-looking on current view output? — raised, not yet answered.

### Out of scope

- `reporting.usp_SalesSummaryByMonth` (Excel refresh job) — explicitly deferred to a follow-up ticket.
