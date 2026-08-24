# Clarifying Meeting (live-session mode)

Run this as a live grooming session with the user acting as the analyst/requester. Do not batch-dump the whole checklist — this is a conversation, not a form.

## Setup

- Load the ticket from the reference or pasted text provided.
- Check it against the [quality checklist](../SKILL.md#quality-checklist) to find what's missing or ambiguous.

## Session loop

- Ask 1–3 closely related questions per turn (e.g. all edge-case questions together), not the entire checklist at once.
- Wait for the user's answer before asking the next batch.
- If an answer is still vague, ask exactly one follow-up to pin it down — don't loop indefinitely on the same point.
- If the user doesn't know an answer, record it as still open and move on; never invent an answer on their behalf.
- Keep going until the user signals they want to stop (e.g. "stop", "that's enough", "done", "let's wrap up").

## Ending: summary

When the session ends, produce a summary with exactly these four sections, in this order:

- **Answers** — each question asked and the answer given
- **Decisions** — the concrete, checkable outcome derived from each answer (e.g. "NetAmount = GrossAmount − DiscountAmount; null DiscountAmount treated as 0")
- **Open questions** — anything raised but left unresolved
- **Out of scope** — anything the user explicitly excluded during the conversation

## After the summary

Ask the user exactly one question: should this be saved as a **new file**, used to **update the existing ticket** in place, or added as a **comment/appendix** to the existing ticket without altering the original content?

Then perform only the chosen action:
- **New file**: create it using the ticket template in [ticket-quality.instructions.md](../../../instructions/ticket-quality.instructions.md). If that file is missing, stop and tell the user instead of improvising a template.
- **Update existing**: revise the ticket's fields/criteria directly based on the decisions.
- **Append as comment**: add a dated "Clarification session" section to the end of the existing ticket with the four summary sections, leaving the original ticket text untouched.
