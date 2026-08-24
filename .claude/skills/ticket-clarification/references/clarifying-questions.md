# Clarifying Questions (question-list mode)

Given a raw or incomplete ticket/request, generate the clarifying questions an analyst/requester needs to answer before implementation can start. Only ask — do not answer the questions yourself, and do not guess at missing details.

Check the ticket against the [quality checklist](../SKILL.md#quality-checklist) and generate one question per genuinely missing or ambiguous item. Skip a category entirely if it's already fully specified in the ticket.

## Output format

Group questions under these headers as bullet points, omitting any header with no questions:

- **Ownership & sign-off** — who owns/requested it, who signs off that it's done
- **Why** — business justification, what happens if this isn't built
- **Priority** — urgency/deadline
- **Acceptance criteria** — testable pass/fail conditions; exact object names for "same as X" references; missing type/nullability/formula for requested fields
- **Edge cases** — null/blank/zero-row behavior, boundary conditions, duplicate keys, negative values
- **Scope** — exact tables/views/procedures affected
- **Data safety** — rollback/reversibility if stored or historical data is touched

Each bullet must be a direct, specific question addressed to the requester — not a restatement of the checklist item it comes from.
