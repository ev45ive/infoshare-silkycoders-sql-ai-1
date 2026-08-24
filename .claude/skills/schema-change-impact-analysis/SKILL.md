---
name: schema-change-impact-analysis
description: 'Use before implementing any RetailDW schema/data-model change (new column, table, temporal or MERGE change, view/procedure edit). Produces an impact analysis mapping data flow, affected objects, temporal/MERGE risk, and open questions before code changes. Trigger keywords: impact analysis, dependency mapping, risk assessment, before implementing a multi-object change, what does this change touch.'
argument-hint: 'Reference a ticket-*.md file or describe the schema change'
---

# Schema Change Impact Analysis

Maps every object and data flow touched by a proposed RetailDW schema/data
change, and the risks (temporal versioning, MERGE, migration, sequencing)
before any code is written.

## When to Use

- Before implementing a change to any `RetailDW/` schema object (`Tables/`,
  `Views/`, `Procedures/`, `Functions/`, `Sequences/`) — new columns, temporal
  table changes, MERGE logic changes, view/procedure edits.
- Before touching `dbo.FactSales` / `dbo.FactSalesHistory` (system-versioned)
  or any MERGE-based ETL procedure (`etl.LoadFactSales`).
- When a ticket affects more than one object and needs every downstream
  consumer mapped before a plan is written.

## Prerequisite: the ticket must already be clarified

This skill does not gather requirements and does not ask clarifying questions
about the business ask itself.

1. Ask the user whether the ticket/request is already clarified and complete
   (testable acceptance criteria, owner, sign-off).
2. If they are not sure or say no, stop and tell them to clarify it first —
   run the `ticket-clarification` skill, or have them complete it — before
   continuing with this skill.

## Procedure

1. **Objects involved / changed** — enumerate every actual file path under
   `RetailDW/` that the change touches or reads from (Tables, Views,
   Procedures, Functions, Sequences). Cite real paths, not guesses.
2. **Trace consumers** — for each changed object, search the repo for every
   procedure/view/function that reads or writes it. List consumers even if
   they turn out to be unaffected; do not silently drop one.
3. **Required changes** — for each object in the impact matrix, state the
   concrete DDL/DML change needed.
4. **Risks** — evaluate explicitly, all four apply to every analysis:
   - **Temporal / Logging / MERGE impact** — does the object participate in
     `FactSales` system-versioning, write to `FactSalesHistory`, or appear in
     a `MERGE` statement (e.g. `etl.LoadFactSales`)? A new column on
     `FactSales` needs a default or backfill; changing a MERGE
     match/update/insert clause changes what gets versioned into history.
   - **Type, nullability, and source** — where does the data originate
     (staging column, computed expression, dimension lookup)? State the
     exact type/precision and where it's set.
   - **Schema vs data migration** — is this metadata-only (new nullable
     column, new view), or does it need a backfill in
     `Scripts/PostDeployment.sql`? State this explicitly as a **Change
     Shape** tag (`view-only` | `pipeline` | `migration`) in the template's
     "Schema vs Data Migration" section — this is the field the
     `schema-change-implementation` skill reads to decide which steps to
     run, so it must be handed off explicitly, not left for that skill to
     infer.
   - **Sequencing** — what deploy order is required (e.g. add column before
     ETL references it, seed reference data before FK, publish before ETL
     re-run)?
5. **Open questions** — anything not explicitly answered by the ticket goes
   here, never as a silent assumption.
6. **Validation / testing** — identify or propose the test(s) in `tests/`
   that will prove the change, plus a note to re-run `./scripts/dw.sh smoke`.

## Core Rule

Never silently decide a business question or mark an object "no change
needed" — add it to Open Questions instead. Present open questions **before**
any file-count or change-count summary. No code changes until the plan is
confirmed by a human.

## Output

Fill in [impact-analysis-template.md](./impact-analysis-template.md).

Save the completed document to `analyses/impact-analysis-<ticket-id>.md`
(alongside the existing `analyses/ANALYSIS_DataModel.md`).

## Design Decisions

Decisions made when this skill was created (2026-08-24):

- Completed impact-analysis documents are saved under `analyses/`, not `docs/` or `exercises/`.
- This skill assumes the ticket is already clarified; it asks the user to
  confirm that and defers to the `ticket-clarification` skill if not, instead
  of performing clarification itself.
