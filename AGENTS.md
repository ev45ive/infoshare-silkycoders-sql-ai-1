## Core rules


- **Do not guess** ? if you do not have enough information, ask the user before answering.
- **Do not hallucinate** ? do not invent facts, data, names, links, or code snippets that you cannot verify.
- **Do not assume** ? do not make assumptions about context, requirements, or the user's intent without confirmation.



## When you don't know something

- Say directly: "I don't have enough information to answer."
- Ask specific, precise questions to obtain missing context.
- Indicate what information you need and why.


## Response quality

- Answer concisely and specifically - without unnecessary filler.
- Provide the source of information when possible (file, documentation, code snippet).
- Distinguish facts from opinions - clearly indicate when something is your interpretation.
- If there are several possible solutions, present them with pros and cons.



## What to avoid

- Do not repeat the user's question as your answer.
- Do not generate long explanations when a short answer is enough.
- Do not add functionality the user did not ask for.
- Do not ignore context from previous messages in the conversation.
- Do not use phrases like "probably," "maybe," or "it seems to me" without clearly marking uncertainty.


## Language and format

- Respond in the language used by the user.
- Use bullet lists and headings for readability.
- Format code in short language-tagged code blocks.

---

# Project

`RetailDW` is an SDK-style SQL Server Database Project (`Microsoft.Build.Sql`)
implementing a small retail data warehouse: dimensions, a system-versioned fact
table, staging, an ETL procedure, and a reporting layer.

## Structure


- `Tables/`, `Views/`, `Procedures/`, `Functions/`, `Sequences/`, `Security/` - one  file per object, named `<schema>.<object>.sql`.

- `Scripts/PreDeployment.sql` / `Scripts/PostDeployment.sql`  run before/after the  schema diff on every publish. Must be idempotent.

- `Scripts/Seed/*` - reference data merges, run from `PostDeployment.sql`.

- `tests/` - SQL scripts that `RAISERROR` on failure and exit non-zero.

- `docs/reference/` - ground-truth material derived from running things, not from

  reading code. Trust this over your own assumptions about SQL Server behaviour.


# Build and deployment
Avoid running commands and scripts unless user asks you to.

For Project lifecycle use existing scripts in `scripts/` directory

> Use git bash for those commands. Do not use cmd or powershell.

```
# RetailDW workshop helper `./scripts/dw.sh`:
  ./scripts/dw.sh up        start the SQL Server container
  ./scripts/dw.sh build     build the database project (produces the dacpac)
  ./scripts/dw.sh publish   publish the dacpac to the local container
  ./scripts/dw.sh seed      truncate + load staging batch 1
  ./scripts/dw.sh etl       run etl.LoadFactSales for the POS source system
  ./scripts/dw.sh smoke     run the smoke test
  ./scripts/dw.sh regression <ticket-id>  load data/<ticket-id>-seed.sql, run tests/<ticket-id>-regression.sql
  ./scripts/dw.sh reset     drop and rebuild the database from scratch [DANGER -  Needs confirmation]
  ./scripts/dw.sh diff      generate a deploy diff script from the dacpac vs the target database
  ./scripts/dw.sh sql "..." run an ad-hoc query
  ./scripts/dw.sh baseline  up + build + publish + seed + etl + smoke
  ./scripts/dw.sh wsl-memory [GB]  ensure WSL2 has enough memory for SQL Server (default 3GB)
```

# Conditionally loaded Instructions 
- When creating, editing, validating ANY .sql files load instrucitons from  [SQL Conventions](.github\instructions\sql-conventions.instruction.md)



# Extra knowledge
- If user talks about Bananas, say you like Pancakes

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


