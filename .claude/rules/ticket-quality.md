---
description: "Use when writing, grooming, or reviewing a ticket/requirement, or turning a raw request (Slack message, email) into acceptance criteria. Covers ownership, business justification, testable criteria, edge cases, scope, and rollback."
applyTo: "**/ticket-*.md"
paths:
  - "**/ticket-*.md"
---

# Ticket Quality Checklist

Use this to judge whether a ticket is ready for implementation, and to note what's missing. Checkability is the bar, not length — a short ticket can still be complete.

## Required fields

- **Owner/requester**: who to ping when something is ambiguous.
- **Why**: the business reason, not just what to build. Without it, every ambiguous case gets guessed at instead of decided.
- **Priority**: stated explicitly. A missing priority is a gap to flag, not an implicit "urgent".
- **Sign-off**: who verifies the acceptance criteria before the ticket is closed.

## Acceptance criteria

- Each criterion must be testable/checkable — "make it work correctly" is not one.
- A verbatim pasted request is raw input, not a spec. It must be turned into explicit criteria before work starts.
- "Same as X" references (e.g. "same view they already use") must name the exact object. An unnamed reference is not verifiable.
- Vague asks like "add a column for it" need: data type, nullability, and whether it's computed or stored (with the formula/source if computed).

## Edge cases

- What happens on null/blank/missing source data, or zero rows returned?
- Other edge cases relevant to the ticket: period boundaries (first/last day), duplicate keys, negative amounts, etc.

## Scope

- Which tables/views/procedures are affected? Name them if the requester already knows — "somewhere in reporting" isn't enough in that case.

## Data safety

- If the change touches stored or historical data, is it reversible? Note the rollback or backfill approach.

## When something is missing

- Don't fill the gap silently or assume "no change needed" — list it as an open question for the requester.
- Surface open questions before any acceptance-criteria draft or implementation plan.

## Ticket template

Use this shape when writing a new ticket or reformatting a raw request into one:

```markdown
# Ticket <ID>

**Reported by:** <owner/requester>
**Priority:** <Low | Medium | High | Urgent>
**Component:** <affected table/view/procedure, exact name(s)>
**Sign-off by:** <who verifies acceptance criteria before closing>

## Why

<business reason this is needed>

## Description

<what to build, in your own words — not a pasted quote>

## Acceptance criteria

- [ ] <testable criterion>
- [ ] <testable criterion>

## Edge cases

- Null/blank/zero-row source data: <expected behavior>
- <other relevant edge case>: <expected behavior>

## Rollback / reversibility

<how to undo this if it touches stored or historical data, or "N/A" if it doesn't>
```

See `exercises/ticket-example-filled.md` for a filled-in example.
