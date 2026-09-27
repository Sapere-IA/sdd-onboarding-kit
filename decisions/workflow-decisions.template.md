# Workflow decisions

Durable workflow rules agreed with the developer ("from now on, X"). This
file records the decision and its context; rules that every session needs
loaded should additionally be promoted to a one-line `AGENTS.md` rule (see
`reference/memory-policy.md` in the kit).

Rules:

- Append new entries below the marker, newest first.
- Log only agreed, durable rules — not one-off instructions for a single task.
- Never log secrets, credentials, or sensitive operational data.
- When a rule replaces an earlier one, mark the old entry
  `Status: superseded by <date — title>` instead of deleting it.
- Propose entries to the developer before writing them.

Entry format:

```markdown
## <YYYY-MM-DD> — <short rule title>

- Status: accepted
- Rule: <the agreed way of working>
- Context: <what prompted the rule>
- Applies to: <where the rule holds, and any exceptions>
- Source: <task/spec/review, or a summarized conversation>
```

---

No entries yet.
