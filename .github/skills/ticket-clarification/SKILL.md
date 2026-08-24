---
name: ticket-clarification
description: 'Groom, review, or clarify a ticket/requirement before implementation starts. Use when reviewing a ticket-*.md file for completeness, turning a raw request (Slack message, email, verbatim ask) into testable acceptance criteria, generating a list of clarifying questions for an analyst/requester, or running a live turn-by-turn clarifying-questions session. Covers ownership, business justification, priority, sign-off, testable acceptance criteria, edge cases, scope, and rollback/reversibility.'
argument-hint: 'Reference a ticket-*.md file, or paste the raw ticket/request text'
---

# Ticket Clarification

## When to Use

- Reviewing a ticket/requirement (`ticket-*.md`) for completeness before implementation starts.
- Turning a raw request (Slack message, email, verbatim ask) into a structured ticket with testable acceptance criteria.
- Generating a list of clarifying questions for an analyst/requester to answer — without answering them yourself.
- Running a live, turn-by-turn clarifying-questions session with the requester, ending in a decisions summary.

## Pick a Mode

| Mode | Use when | Procedure |
|---|---|---|
| **Quality review** | Check if a ticket is ready, or reformat a raw request into one | [Quality checklist](#quality-checklist) |
| **Question list** | Produce a list of questions to send to the requester (no back-and-forth) | [Clarifying questions](./references/clarifying-questions.md) |
| **Live meeting** | Run an interactive grooming session with the user acting as requester | [Clarifying meeting](./references/clarifying-meeting.md) |

## Core Rule (all modes)

Never fill a gap silently or assume "no change needed." Missing or ambiguous items are **open questions** for the requester — list them, don't guess. Surface open questions before any acceptance-criteria draft, question count, or file-change summary. A short ticket can still be complete; checkability is the bar, not length.

## Quality Checklist

The checklist and ticket template are owned by [ticket-quality.instructions.md](../../instructions/ticket-quality.instructions.md) — this skill does not duplicate them, so edits made there are picked up automatically.

1. Read `.github/instructions/ticket-quality.instructions.md`.
2. **If that file does not exist, stop immediately and tell the user the checklist source is missing.** Do not fall back to a remembered or improvised checklist — the skill has no other source of truth for it.
3. Walk each section of the checklist and mark it present, vague, or missing for the current ticket/request.
4. List open questions for anything vague or missing — do not guess an answer.
5. If reformatting a raw request into a ticket, use the ticket template embedded in that same instructions file, filling only what's known and leaving the rest as open questions.

## Example

See [exercises/ticket-example-filled.md](../../../exercises/ticket-example-filled.md) for a filled ticket that passes the quality checklist.
