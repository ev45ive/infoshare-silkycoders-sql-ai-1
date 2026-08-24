# Schema Change Workflow Plan — DPO-1204

## Ticket
- Source: [exercises/ticket-DPO-1204-snapshot-id.md](../exercises/ticket-DPO-1204-snapshot-id.md)

## Phase status
- [x] Clarification
- [x] Impact analysis
- [ ] Implementation
- [ ] Test coverage
- [ ] Docs
- [ ] PR prep

## Artifacts
- Impact analysis: [analyses/impact-analysis-DPO-1204.md](../analyses/impact-analysis-DPO-1204.md)
- Seed: data/DPO-1204-seed.sql
- Regression test: tests/DPO-1204-regression.sql

## Open questions
- Resolved by user decision (2026-08-24): proceed to implementation without a
  separate scratch-table verification step. The implementation subagent (which
  has execute access) will discover real `SYSTEM_VERSIONING` ADD/ALTER COLUMN
  behavior when it runs `./scripts/dw.sh build`/`publish` against the live
  container, and adjust the DDL sequence (and, if it needed disabling/enabling
  versioning, note that as a deviation) based on what actually happens — not
  from assumption. If real evidence is produced, it should also populate the
  currently-missing `docs/reference/temporal-restrictions.md` referenced by
  [.claude/rules/sql-conventions.md](../.claude/rules/sql-conventions.md).
- **[NEW — blocking, 2026-08-24]** This implementation session had no
  terminal/execute tool available (no way to run `dw.sh build`/`publish`/
  `seed`/`etl`/`smoke`, or any ad-hoc SQL), despite being asked to run them.
  All six files were edited per the impact analysis, but **none of it has been
  built, published, or run** — the `SYSTEM_VERSIONING`/NOT-NULL sequencing in
  `PreDeployment.sql` is an unverified design, not an observed result.
  `docs/reference/temporal-restrictions.md` was deliberately NOT created,
  since no real command was run to observe its content. Needs: either a
  session with execute access to run the baseline and report back, or the
  user to run `./scripts/dw.sh build && ./scripts/dw.sh publish && ./scripts/dw.sh seed && ./scripts/dw.sh etl && ./scripts/dw.sh smoke`
  themselves and share the output so this can be fixed forward and the plan/
  doc updated with real evidence.

## Log
- 2026-08-24 — plan created — starting phase 1 (clarification)
- 2026-08-24 — clarification — ticket-quality checklist satisfied (owner,
  why, priority, sign-off, testable acceptance criteria, edge cases, scope,
  rollback all present). Initial reviewer flagged 6 questions; cross-checked
  against repo conventions (stg.Sales.sql, 01-staging-batch-1.sql,
  etl.LoadFactSales.sql, dbo.FactSales.sql) — all resolved as mechanical or
  already decided by the ticket. No temporal NOT-NULL-column backfill
  precedent exists in this repo yet, so implementation phase will need to
  design that ALTER TABLE / backfill sequence from scratch. Proceeding to
  phase 2 (impact analysis).
- 2026-08-24 — implementation (file edits only, NOT verified) — edited
  RetailDW/Tables/stg.Sales.sql, RetailDW/Tables/dbo.FactSales.sql,
  RetailDW/Tables/dbo.FactSalesHistory.sql,
  RetailDW/Procedures/etl.LoadFactSales.sql,
  RetailDW/Scripts/PreDeployment.sql, RetailDW/Scripts/PostDeployment.sql,
  data/01-staging-batch-1.sql. Designed the NOT-NULL migration as: add
  SnapshotID NULL to both FactSales and FactSalesHistory in
  PreDeployment.sql (SYSTEM_VERSIONING OFF, since history-table UPDATE is
  blocked while ON — per sql-conventions.md), backfill SnapshotID = LoadId,
  ALTER COLUMN NOT NULL, SYSTEM_VERSIONING back ON, guarded by
  `COL_LENGTH('dbo.FactSales','SnapshotID') IS NULL` for idempotency — all
  before the schema diff runs, so the diff (which applies the NOT NULL
  model files) is a no-op for this column. **This session had no
  terminal/execute tool, so build/publish/seed/etl/smoke were NOT run** —
  this design is unverified. Did not create
  docs/reference/temporal-restrictions.md (would require fabricating
  "observed" behavior). Phase 3 left unchecked pending a session/user that
  can actually execute and report real results.
- 2026-08-24 — impact analysis — data flow, files touched, MERGE
  change-detection location, and reporting-consumer no-impact (no SELECT *
  views) confirmed and written to
  analyses/impact-analysis-DPO-1204.md. One blocking open question
  remains re: temporal ALTER mechanics vs. SYSTEM_VERSIONING — see Open
  Questions above. Paused at gate for user confirmation before phase 3.
- 2026-08-24 — gate — user chose to verify temporal ALTER behavior during
  implementation rather than as a separate pre-step. Proceeding to phase 3.
- 2026-08-24 — implementation review (orchestrator) — reviewed all 7 edited
  files against the impact analysis; mechanically correct throughout. Found
  and fixed one issue: the implementation subagent had invented a fake ticket
  number ("Ticket: DPO-1102*", with a footnote admitting it was "invented for
  illustration") in a **pre-existing** change-log line in
  dbo.FactSales.sql, instead of leaving that line untouched — reverted to the
  original `Ticket: N/A`. This is exactly the kind of fabrication
  AGENTS.md/sql-conventions.md forbid ("never invent a ticket number for a
  real change"). Confirmed: no other files show similar fabrication.
  Phase 3 remains open pending an actual build/publish/seed/etl/smoke run —
  see blocking open question above.
