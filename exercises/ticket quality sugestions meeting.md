# Ticket quality — raw notes (dump before formalizing)

Brain dump from a few past sprints of tickets that caused rework. Not organized,
not prioritized — just what came up when we complained about bad tickets. Turn
this into an actual instruction file, don't just copy-paste it.


- Who even owns this? Half our tickets don't say who to ping when something's
  ambiguous — need an owner / requester on every ticket.

- "Why do we need this" is missing more often than not. A ticket that only says
  *what* to build but not *why* means every ambiguous case gets guessed at.

- Acceptance criteria — like, actual testable criteria, not "make it work
  correctly". If I can't check a box against it, it's not a criterion.

- Nulls / blanks / zero rows — nobody ever says what should happen when the
  source data is missing, empty, or weird. This is like 80% of our bugs.

- Edge cases in general, not just nulls — first day of month, last day of
  month, duplicate keys, negative amounts, whatever's relevant to the ticket.

- Do they know which tables/views/procs are affected? Doesn't have to be exact,
  but "somewhere in reporting" isn't enough if they already know it's one view.

- Priority / urgency — is this "today" or "next quarter"? Tickets that don't
  say get treated as urgent by default, which isn't fair to the queue.

- Rollback / reversibility — if this changes stored data, can we undo it?
  (Came up on the SnapshotID-style stuff, not always relevant but worth asking.)

- Who signs off that it's done — same as owner, but specifically: who verifies
  acceptance criteria before it's marked closed.

- A lot of tickets read like a Slack message pasted in verbatim — that's fine
  as raw input, but somebody (human or AI) has to turn it into criteria before
  work starts; it can't stay a paraphrase forever.

- "Same as X" references (e.g. "same view they already use") are a trap —
  which view, exactly? Name it or it's not verifiable.

- Vague quantities: "add a column for it" — what type? Nullable? Computed or
  stored? Formula?

- Don't forget: a ticket can be short and still be good, length isn't the
  criterion, checkability is.

