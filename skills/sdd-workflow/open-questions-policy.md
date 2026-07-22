# Open Questions Policy

## Purpose

This policy defines how Claude Code should identify, record, prioritize, and resolve open questions during Spec Driven Development.

Open questions prevent hidden ambiguity from becoming incorrect code.

---

## Core rule

If a missing decision could materially change the product behavior, architecture, tests, security model, data model, or developer workflow, Claude Code must record it as an open question.

Do not bury important questions in chat.

Do not proceed to implementation while blocking questions remain unresolved.

---

## Where open questions belong

Open questions must be written in:

```text
specs/<feature-slug>/open-questions.md
```

For onboarding-level decisions, use:

```text
decisions/answers.md
```

and keep unresolved onboarding questions in the relevant onboarding notes.

---

## Blocking vs non-blocking questions

Every question must be classified as:

```text
blocking
```

or:

```text
non-blocking
```

### Blocking questions

A blocking question must be answered before implementation.

Examples:

- Who is allowed to access this data?
- Should this feature modify existing records?
- What is the source of truth for this field?
- Is this a breaking API change?
- Should this create a database migration?
- What command runs the test suite?
- Should human approval be required before implementation?
- Should this feature use an external service?

### Non-blocking questions

A non-blocking question may remain unresolved for a draft spec if the assumption is safe and explicit.

Examples:

- What should the exact empty-state copy be?
- Should the CLI help text say “recent” or “latest”?
- Should the output include a trailing newline?
- Should the internal helper function be named one way or another?

Non-blocking questions should still be recorded.

---

## Required question format

Each question in `open-questions.md` is a card under the `## Open` section, following the `open-questions.md` template. Add the `blocking-yes` card class and the `[!blocking Blocking]` badge for blocking questions (`[!warning Non-blocking]` otherwise):

```md
::: card blocking-yes
#### Q1 — Short title [!blocking Blocking]

- **Question:** The question that needs to be answered.
- **Why it matters:** What decision depends on this answer.
- **Default if unanswered:** Optional — only include if safe.
- **Affected files / sections:** `requirements.md`, `design.md`, `tasks.md`
- **Related requirements:** REQ-001
:::
```

Once answered, move the card to the `## Resolved` (or `## Deferred`) section, change the badge to `[!ok Resolved]` (or `[!warning Deferred]`), and add:

```md
- **Decision:** Developer's decision.
- **Resolved by:** developer, YYYY-MM-DD
```

---

## Categories of open questions

Use categories when helpful.

Recommended categories:

```text
Product behavior
Permissions and security
Data model
API/CLI contract
UX/copy
Validation and testing
Architecture
External integrations
Task management
Hooks and automation
MCPs
Git workflow
```

---

## When to stop and ask immediately

Claude Code must stop and ask the developer immediately if a blocking question prevents writing a meaningful spec.

Examples:

- the feature goal is unclear;
- the main actor is unclear;
- the system boundary is unclear;
- the data source is unknown;
- security/permission behavior is unspecified;
- the feature could require a destructive migration;
- the task conflicts with existing project architecture;
- the requested change could break existing public APIs.

---

## When to continue with a draft

Claude Code may continue with a draft spec if:

- the ambiguity is low or medium risk;
- the assumption is explicit;
- the assumption is reversible;
- the open question is non-blocking;
- the spec can still be reviewed meaningfully.

In that case, record the question and any default assumption.

---

## Relationship to assumptions

Use an open question when developer input is needed.

Use an assumption when Claude Code can safely proceed with a draft.

Some entries may appear in both files:

- `open-questions.md` records the decision still needed.
- `assumptions.md` records the temporary assumption used for the draft.

Example, in `open-questions.md`:

```md
::: card
#### Q2 — Empty-state copy [!warning Non-blocking]

- **Question:** What exact message should be shown when no notes exist?
- **Default if unanswered:** Use "No notes found."
:::
```

And in `assumptions.md`:

```md
::: card risk-low
#### A2 — Empty-state copy [!pending Pending]

- **Assumption:** Use "No notes found." as the empty-state message.
- **Risk / impact if wrong:** Low — copy change only.
- **Blocks implementation:** No
:::
```

---

## Status behavior

The presence of open questions affects task status.

### If blocking questions exist

Task status should be:

```text
spec_draft
```

Claude Code must not implement.

### If only non-blocking questions exist

Task status may be:

```text
spec_ready
```

but the final response must mention unresolved non-blocking questions.

### If no open questions exist

Task status may be:

```text
spec_ready
```

assuming requirements, design and tasks are complete.

---

## Human approval behavior

Human approval of a spec should resolve or explicitly accept all blocking questions.

Before moving a task to:

```text
human_approved
```

Claude Code must verify:

- no blocking questions remain pending;
- assumptions have been accepted, corrected, or removed;
- the developer understands any remaining non-blocking questions.

---

## Implementer behavior

The `implementer` agent must read `open-questions.md`.

If any question has:

```text
Blocking: Yes
Decision: Pending
```

the implementer must stop.

The implementer must not answer product, security, architecture, or workflow questions by itself.

---

## Reviewer behavior

The `reviewer` agent must check:

- whether implementation proceeded despite unresolved blocking questions;
- whether decisions in `open-questions.md` were reflected in code and tests;
- whether new questions emerged during implementation;
- whether unresolved questions require returning to `spec_draft`.

---

## Examples

### Good blocking question

```md
::: card blocking-yes
#### Q1 — User visibility scope [!blocking Blocking]

- **Question:** Should users see only their own notes or all notes in the system?
- **Why it matters:** Determines authorization behavior and data filtering.
- **Default if unanswered:** None — the developer must decide.
- **Affected files / sections:** `requirements.md`, `design.md`, `tasks.md`
- **Related requirements:** REQ-002
:::
```

### Good non-blocking question

```md
::: card
#### Q2 — Empty-state copy [!warning Non-blocking]

- **Question:** What exact message should be displayed when no notes exist?
- **Why it matters:** User-facing copy only, not core behavior.
- **Default if unanswered:** Use "No notes found."
- **Affected files / sections:** `requirements.md`, `acceptance-tests.md`
- **Related requirements:** REQ-004
:::
```

### Bad question

```md
How should this work?
```

This is too vague and not actionable.