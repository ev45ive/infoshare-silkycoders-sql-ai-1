

## Naming

- **Schemas:** `dbo` (core warehouse), `stg` (staging, always disposable), `etl`
  (load procedures), and `reporting` (read-only consumer-facing objects).
- **Tables:** `PascalCase`; dimensions are prefixed with `Dim`, and facts are
  prefixed with `Fact`.
- **Constraints:** `PK_`, `FK_`, `UQ_`, `DF_` (default), `CK_` (check), and
  `IX_`/`UX_` (index).
- Every object name is wrapped in brackets (`[brackets]`) in DDL to match the
  existing style.

## Migration and deployment rules

- Schema changes go through the `.sqlproj` model. Never hand-write `ALTER`
  statements against a running database outside of `PostDeployment.sql` or a
  documented migration.
- `PreDeployment.sql` is for operations that must run before the schema diff.
- `PostDeployment.sql` is for seeding and backfills. It must remain idempotent
  because it runs on every publish.
- Every deployment that changes existing data appends exactly one row to
  `dbo.DeploymentHistory`.

## Testing rules

- Every change ships with a test in `tests/`.
- Tests must fail loudly (`RAISERROR`, non-zero exit); there must be no silent
  pass.
- A test that cannot run because a column or object does not exist yet is an
  acceptable failure mode, as long as the message is clear.

## Scope discipline for the agent

- Never silently decide a business question and mark an object as "no change
  needed." If scope is ambiguous, add it to an **open questions** list rather than making a silent
  assumption.
- Never quote an error message that has not actually been produced by running
  something. If unsure whether an operation fails, say so or test it.
- Present open questions **before** a file-change count or "total files: N"
  summary. A confident number is worthless if the scope is still undecided.
- Do not touch `RetailDW/Scripts/Seed/*` or `RetailDW/Security/*` unless the
  ticket explicitly requires new schemas or reference data.

## Required plan format before implementation

1. Data flow and objects touched (cite actual file paths).
2. Open questions (things that change the plan depending on the answer).
3. Step-by-step change list, in dependency order.
4. Test plan.
5. Rollback or backfill note if temporal or existing data is involved.

No code changes until this plan is confirmed by a human.

