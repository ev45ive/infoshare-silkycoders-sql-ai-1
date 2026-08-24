---
description: SQL team conventions
applyTo: *.sql
paths:
  - "*.sql"
---

## Naming

- **Schemas:** `dbo` (core warehouse), `stg` (staging, always disposable), `etl` (load procedures), and `reporting` (read-only consumer-facing objects).
- **Tables:** `PascalCase`; dimensions are prefixed with `Dim`, and facts are prefixed with `Fact`.
- **Constraints:** `PK_`, `FK_`, `UQ_`, `DF_` (default), `CK_` (check), and `IX_`/`UX_` (index).
- Every object name is wrapped in brackets (`[brackets]`) in DDL to match the existing style.

## File header doc comment

- Every object file (`Tables/`, `Views/`, `Procedures/`, `Functions/`) starts with a top-of-file `/* ... */` block comment.
- Required fields: `Author` (name + email; get from `git config user.name`/`user.email` if unknown), `AI model` (if AI-assisted), `Created` date, a business-facing `Description`, and a `Change log`.
- `Change log` is a flat bullet list, one entry per change, in the form: `date | Ticket: <id or N/A> | author | model | description/commit message`. Newest entry last (append-only).
- Never invent a ticket number for a real change — use `N/A` if none exists.
- Add short (one line) inline comments next to columns/clauses whose intent isn't obvious from the code itself (e.g. a computed-elsewhere value, a non-obvious default, a temporal/system column). Don't restate what a line already says.

### Template

```sql
/*
    Author:      <Name> <email>
    AI model:    <model name, or omit if not AI-assisted>
    Created:     <YYYY-MM-DD>
    Description: <business usage — why this object exists, who consumes it>

    Change log:
    - <YYYY-MM-DD> | Ticket: <id|N/A> | <author> | <model|N/A> | <description/commit message>
*/
```

### Filled example

```sql
/*
    Author:      Mateusz Kulesza <ev45ive@gmail.com>
    AI model:    Claude Sonnet 5
    Created:     2026-08-23
    Description: System-versioned (temporal) fact table holding one row per sold
                 order line. Source of truth for revenue/VAT reporting views and
                 the monthly Excel summary refresh job.

    Change log:
    - 2026-08-23 | Ticket: N/A | Mateusz Kulesza | Claude Sonnet 5 | Remove Snapshot - will be added in next exercise
*/
CREATE TABLE [dbo].[FactSales]
(
    ...
);
```

## Migration & deployment rules

- Schema changes go through the `.sqlproj` model, never a hand-run `ALTER` outside `PostDeployment.sql` or a reviewed migration script.
- Every deployment that backfills or migrates existing data appends exactly one row to `dbo.DeploymentHistory`.
- **Temporal tables (`dbo.FactSales` / `dbo.FactSalesHistory`): do not claim an operation requires disabling `SYSTEM_VERSIONING` unless you have run a query that proves it.** See `docs/reference/temporal-restrictions.md`; most schema changes (`ADD`/`ALTER`/`DROP COLUMN`) work with versioning ON and propagate to the history table automatically. Only `UPDATE`/`DELETE` directly against the history table and `TRUNCATE` on the current table are blocked.

## Testing requirements

- Every change ships with a test in `tests/`.
- A test must fail loudly — no silent pass, no swallowed errors.
- It is acceptable for a test to fail because an object or column does not exist yet, as long as the failure message says so clearly.

