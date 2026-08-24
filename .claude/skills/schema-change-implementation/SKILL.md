---
name: schema-change-implementation
description: 'Use once a RetailDW schema/data-model change has an approved plan (from the schema-change-impact-analysis skill, or a confirmed simple ticket spec) and is ready to be implemented. Applies table, staging, ETL MERGE, history, logging, and pre/post-deployment changes for a given ticket. Trigger keywords: implement the plan, apply impact analysis, schema-change-implementation, add column to pipeline, propagate column through ETL, backfill existing rows.'
argument-hint: 'Reference a ticket ID (e.g. DPO-1204) and the approved analysis/plan'
---

# Schema Change Implementation

Implements an already-approved RetailDW schema/data-model change: table
definitions, the staging → ETL → fact pipeline, temporal history objects,
pre/post-deployment scripts, and file headers/changelogs. This skill
executes a plan; it does not decide scope.

## Prerequisite: the plan must already exist and be approved

This skill does not perform impact analysis or decide business scope.

1. Confirm you have: the ticket reference, and the approved analysis/plan
   stating which objects change, the field's type/nullability, its source
   of truth, and any temporal/migration note.
2. If no plan exists yet, or the change touches more than one object,
   `FactSales`, or a MERGE procedure, stop and run
   `schema-change-impact-analysis` first instead of guessing at scope here.
3. If the plan leaves a question open, stop and ask — do not decide it
   during implementation.

## Step 0: Read the change shape handed off by the plan

This skill does not classify the change itself. The plan's "Schema vs Data
Migration" section (produced by `schema-change-impact-analysis`) must state
an explicit **Change Shape** tag — read that tag, don't re-derive it from
the DDL:

- **`view-only`** (e.g. a computed column added to a view, no new stored
  column): do Step 4 (docs) and the object edit only. Skip Steps 1–3.
- **`pipeline`** (a new/changed stored column flows through staging and
  ETL): do Steps 1–4 in full.
- **`migration`** (existing rows need populating — e.g. a new `NOT NULL`
  column with historical data): also do Step 5.

If the plan doesn't carry an explicit Change Shape tag, that's a gap in the
plan, not something to infer here — stop and send it back to
`schema-change-impact-analysis` (or ask the human) rather than guessing.

## Procedure

1. **Update table definitions** — apply the column/type change to the base
   table(s) named in the plan.

2. **Propagate the value through the pipeline** (skip any object the plan
   doesn't call for changing):
   - `stg.<Table>`: land the raw value — staging stays nullable/untrusted,
     per the plan's source-of-truth note.
   - The load procedure's temp table (e.g. `#FtData` in
     `etl.LoadFactSales`): add the column to the `CREATE TABLE #...`
     definition and to the validating `SELECT`/CTE that populates it.
   - `MERGE` statement: add the column to
     - the `WHEN MATCHED AND (...)` change-detection predicate (otherwise
       updates on that column go undetected),
     - the `WHEN MATCHED THEN UPDATE SET` list,
     - the `WHEN NOT MATCHED BY TARGET THEN INSERT` column list and
       `VALUES` list.
   - Target fact table: confirm the new column lands only via the `MERGE`,
     not a separate statement outside it.

3. **Update history and logging objects**:
   - History table (e.g. `dbo.FactSalesHistory`): required whenever the
     temporal table's column list changes — `SYSTEM_VERSIONING` requires
     the history table shape to match the current table.
   - Audit/log tables (e.g. `dbo.LoadLog`): only if the plan explicitly
     says the field belongs at the load level, not the row level. If the
     plan didn't decide this, treat it as an open question instead of
     guessing.

4. **Add the doc header and changelog entry** to every object DDL file
   touched, per `sql-conventions.instruction.md` — real date, author,
   ticket number, and a one-line description of what changed in that file.

5. **Migration/backfill only** — if Step 0 classified this as a migration:
   - Add idempotent backfill logic to `Scripts/PreDeployment.sql` (if it
     must run before the schema diff) or `Scripts/PostDeployment.sql` (if
     after) — never a hand-run `ALTER`/`UPDATE` outside these scripts.
   - Append exactly one new guarded row to `dbo.DeploymentHistory`,
     following the existing `baseline` pattern (`IF NOT EXISTS ... INSERT`,
     unique `ScriptName` in `<ticket>-<short-desc-slug>` format, e.g.
     `DPO-1204-backfill-net-amount`).
   - Do not add a `DeploymentHistory` row for metadata-only changes (new
     nullable column, view/procedure edit) — that's Step 0's other branches.

## Review Before Finishing

- Diff the changed files against the plan: every touched file must trace
  back to a step in the plan; nothing extra.
- Do not touch `RetailDW/Scripts/Seed/*` or `RetailDW/Security/*` unless the
  ticket explicitly requires new schemas or reference data.
- Re-check every point the plan marked as an open question — implementation
  must not silently resolve it. Surface it back to the human instead.
- Confirm the test plan from the analysis has a matching change in
  `tests/`, and note that `./scripts/dw.sh smoke` should be re-run.

## Core Rule

This skill implements; it does not decide. Any question the plan didn't
answer stays open and goes back to the human, never a silent assumption
made during implementation.
