---
name: decision-log
description: Record durable architectural and workflow decisions in the project's decision log. Use when a spec, review, or discussion settles something future sessions must not re-litigate.
---

# Decision log

## Purpose

Make significant decisions survive context compaction and new sessions by
recording them in versioned project files instead of chat history.

## Where decisions live

- `decisions/answers.md` — onboarding answers (always created at onboarding).
- `decisions/architecture-decisions.md` — durable architectural choices.
- `decisions/rejected-options.md` — alternatives considered and rejected.
- `decisions/workflow-decisions.md` — agreed workflow rules ("from now on, X").
- `docs/adr/` — if the project already uses ADRs, architecture decisions go
  there in the project's existing format and numbering instead of
  `architecture-decisions.md`.

The locations configured for this project are recorded in
`decisions/answers.md` (onboarding question §17). Each decision file
carries its own entry format in its header.

## When to use

- A spec or review settles an architectural choice (and especially when an
  alternative was explicitly rejected).
- A workflow rule is agreed with the developer ("from now on, X").
- The same question keeps being re-asked across sessions.
- The SDD workflow flagged a decision for logging: the spec-author reports
  significant decisions when a spec is ready, and the reviewer flags
  decisions settled during implementation or review (see `workflow.md`).

## When not to use

- Trivial choices with no future consequence (naming a local variable,
  one-off formatting).
- One-off instructions that apply to a single task.
- Speculative conclusions not yet confirmed by the developer.
- Anything containing secrets or sensitive operational data.

## Required inputs

- The decision, its context, and the alternatives considered.
- Which file it belongs in (architecture / rejected option / workflow rule,
  or an ADR).
- The source task/spec/review the decision came from.

## Procedure

1. Confirm the decision is durable and non-trivial.
2. Pick the target: architectural choice → `architecture-decisions.md` (or
   `docs/adr/` if configured); rejected alternative →
   `rejected-options.md`; workflow rule → `workflow-decisions.md`.
3. Draft the entry using the target file's entry format (date, status,
   context, decision, alternatives, consequences, source).
4. Propose the exact entry text to the developer. Do not write without
   approval.
5. On approval, append the entry below the marker, newest first.
6. If the decision contradicts an earlier entry, mark the old entry as
   superseded rather than deleting it.
7. If the rule is load-bearing for every session, additionally propose a
   one-line `AGENTS.md` rule (see `reference/memory-policy.md` in the kit:
   decisions live in `decisions/`; `AGENTS.md` carries only short rules).

## Output artifact

An appended entry in the project's decision log (`decisions/*.md` or
`docs/adr/`).

## Safety constraints

- Propose, do not overproduce: when in doubt, ask whether it is worth
  logging.
- Never write an entry without developer approval of the exact text.
- Never log secrets, credentials, or personal data.
- Decision logs are project memory; do not write to the harness's global (user-level) memory.
