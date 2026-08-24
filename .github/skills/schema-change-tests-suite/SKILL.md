---
name: schema-change-tests-suite
description: 'Use after a RetailDW schema/data-model change has been implemented, to verify and build out its test coverage. Confirms an analysis/ticket with business rationale and risks exists, confirms at least a smoke-test assertion covers the change, helps discover non-happy-path scenarios (NULL, type/precision, conversion, business-rule violations), designs seed data for those cases, and creates a dedicated per-change seed + regression test beyond the smoke test. Also checks whether the base data/01-staging-batch-1.sql seed needs updating. Trigger keywords: test coverage, regression test, seed data design, non-happy-path, edge cases, smoke test verification, schema-change-tests-suite.'
argument-hint: 'Reference the ticket ID / implemented change to build test coverage for'
---

# Schema Change Test Suite

Verifies and builds out test coverage for a RetailDW schema/data-model change
**after** it has been implemented: confirms the business case is documented,
confirms the smoke test actually asserts on the change, elicits non-happy-path
scenarios from the human, designs seed rows for them, and produces a
dedicated per-change seed + regression test. This skill does not implement
schema changes — see `schema-change-impact-analysis` and
`schema-change-implementation` for that.

## When to Use

- Right after `schema-change-implementation` finishes applying a change, as
  the last step before the change is considered done.
- When a ticket/PR is missing test coverage beyond "it builds and publishes."
- When someone asks to add edge-case/regression coverage for an existing
  change that only has a smoke test today.

## Prerequisite: the change must already be implemented

This skill does not design or implement schema changes. If the change hasn't
landed yet, stop and point to `schema-change-impact-analysis` (plan) and
`schema-change-implementation` (apply) first.

## Procedure

### 1. Confirm the business case is documented

Find the ticket, plan, or analysis for this change (`exercises/ticket-*.md`,
`analyses/impact-analysis-*.md`, or equivalent) and confirm it states:

- the business rationale (why the change exists),
- any pitfalls/risks already called out (temporal/MERGE impact, type
  conversions, migration/backfill).

If none exists, stop and say so — do not write tests for an undocumented
change. Point back to `ticket-clarification` or
`schema-change-impact-analysis` instead of inventing a rationale.

### 2. Verify smoke-test coverage exists

Check [tests/smoke-test.sql](../../../tests/smoke-test.sql) for an assertion
that actually exercises the new/changed behavior — not just "the object
exists," a concrete check tied to the change (e.g. a new column has a
non-NULL/expected value on a known row, a new view returns the right
computed result). If the change added a column/object with no matching
assertion, add **one basic** check here (proves the change didn't break the
baseline load/report) — a smoke test is the minimum bar, not optional. Keep
it lightweight: detailed edge-case assertions belong in the per-change
regression test from step 5, not here.

### 3. Discover non-happy-path scenarios

Walk the human through a checklist scoped to what actually changed (columns,
types, new business rules) — do not assume which apply, ask:

- **NULL / missing values** — is the new/changed column nullable? What
  should happen if the source sends NULL?
- **Type, precision, rounding** — does a cast/conversion risk truncation,
  overflow, or a rounding difference (e.g. `DECIMAL` precision, VAT/rate
  math)?
- **Unit / currency / format conversion** — any conversion between the
  staging representation and the warehouse representation?
- **Referential integrity** — can the value reference a dimension row that
  doesn't exist yet (unknown product/store code, like the existing
  rejected-row cases in
  [data/01-staging-batch-1.sql](../../../data/01-staging-batch-1.sql))?
- **Duplicates / dedup** — does the change affect which row wins on a
  duplicate business key?
- **Out-of-range / business-rule violations** — negative quantity, discount
  greater than price, out-of-range dates, disallowed source systems.
- **Source-system filtering** — should the new behavior apply to every
  `SourceSystem`, or only some (mirrors the existing `WEB` row ignored by a
  `POS` load)?

Record which scenarios the human confirms apply. Anything not explicitly
confirmed goes to **open questions**, never a silent assumption.

### 4. Design seed rows for the confirmed scenarios

Follow the manifest style of
[data/01-staging-batch-1.sql](../../../data/01-staging-batch-1.sql): a
top-of-file comment block enumerating each case in one line (e.g. "1 NULL
`<NewColumn>` -> rejected/coerced to X"), then one INSERT row per case with
an inline comment stating exactly what it exercises. One row (or the minimal
set) per confirmed scenario — don't pad with unrelated rows.

### 5. Create a dedicated per-change seed + regression test

Per-change regression files are separate from both the base batch and
`tests/smoke-test.sql` (see
[docs/schema-dev-workflow.md](../../../docs/schema-dev-workflow.md) §2).
Naming convention:

- `data/<ticket-id>-seed.sql` — the seed rows from step 4, following the
  `01-staging-batch-1.sql` header/comment style. Self-contained: it truncates
  `stg.Sales` itself (like the base batch does) so the ETL run that follows
  it only sees this ticket's rows.
- `tests/<ticket-id>-regression.sql` — assertions for each scenario,
  following the `smoke-test.sql` style (`RAISERROR`, non-zero exit, numbered
  `PRINT` sections, no silent pass). Assumes ETL has already run against the
  seed above (rows land in `dbo.FactSales` / get rejected per `dbo.LoadLog`).

Both files start with the standard doc-comment header from
[sql-conventions.instruction.md](../../instructions/sql-conventions.instruction.md)
(`Author`, `AI model`, `Created`, `Description`, `Change log`) — same as any
other `.sql` file in the repo, with `Description` stating which scenarios the
file covers and `Change log`'s `Ticket:` field set to the real ticket id
(never `N/A` for a generated file tied to a specific change).

Run it with `./scripts/dw.sh regression <ticket-id>` (loads the seed file,
runs `etl.LoadFactSales`, then runs the regression test file).

### 6. Check whether the base batch also needs updating

Explicitly verify — don't skip silently — whether
[data/01-staging-batch-1.sql](../../../data/01-staging-batch-1.sql) and/or
[tests/smoke-test.sql](../../../tests/smoke-test.sql) need a matching update
because of this change, e.g.:

- a new `NOT NULL` column breaks the existing `INSERT` column list,
- a new computed/reporting column changes an existing row-count or
  value assertion in the smoke test,
- the change alters shared reference/dimension data
  (`RetailDW/Scripts/Seed/*`) — per `AGENTS.md`, do not touch that folder
  unless the ticket explicitly requires new reference data; if it does, say
  so as an open question rather than deciding it here.

State the answer (yes/no) and the reason either way; do not leave it
unaddressed.

## Core Rule

Never silently decide which non-happy-path scenarios matter or whether the
base seed needs updating — ask, and list anything unresolved as an open
question before any file-count summary. This skill verifies and extends test
coverage; it does not change business logic.

## Design Decisions

Decisions made when this skill was created (2026-08-24), which reverse an
earlier decision recorded in
[docs/schema-dev-workflow.md](../../../docs/schema-dev-workflow.md):

- Each schema change gets its **own** seed + regression test file
  (`data/<ticket-id>-seed.sql` + `tests/<ticket-id>-regression.sql`), not one
  combined adversarial batch shared across all changes.
- `./scripts/dw.sh regression <ticket-id>` runs that pair; wiring it into any
  CI/CD schedule is out of scope for this skill.
