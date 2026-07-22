# Assumptions Policy

## Purpose

This policy defines how Claude Code should handle missing or ambiguous information during Spec Driven Development.

The goal is to avoid hidden decisions.

Claude Code may make assumptions only when they are explicit, reviewable, and safe.

---

## Core rule

Never make silent assumptions.

If Claude Code needs to infer something that affects product behavior, architecture, data, security, compatibility, or developer workflow, it must either:

1. ask the developer; or
2. record the assumption explicitly in `assumptions.md`.

---

## Where assumptions belong

Assumptions must be written in:

```text
specs/<feature-slug>/assumptions.md
```

Do not hide important assumptions only in:

- chat messages;
- implementation comments;
- commit messages;
- `design.md`;
- task descriptions.

The dedicated `assumptions.md` file is the source of truth for inferred decisions.

---

## Types of assumptions

### 1. Product behavior assumptions

These affect what the user experiences.

Examples:

- default limit is 5;
- empty states should show a message instead of returning nothing;
- search should be case-insensitive;
- deleted items should be excluded;
- existing records should not be modified.

These assumptions usually require developer review.

---

### 2. Technical assumptions

These affect implementation strategy.

Examples:

- reuse an existing repository method;
- add a new service function instead of modifying the controller directly;
- avoid adding a new dependency;
- follow the existing CLI command pattern;
- add tests in the existing test directory.

These may be acceptable if aligned with existing project conventions.

---

### 3. Data assumptions

These affect stored data or data interpretation.

Examples:

- `created_at` is the correct field for recency;
- soft-deleted records should be ignored;
- null values should sort last;
- IDs are globally unique;
- existing schema can support the feature.

These are often risky and should be verified.

---

### 4. Security and permission assumptions

These affect access control or sensitive data.

Examples:

- the current user may only see their own records;
- admin users can see all records;
- API responses must not expose internal metadata;
- logs must not contain personal data.

These assumptions should usually be treated as blocking unless explicitly documented elsewhere.

---

### 5. Workflow assumptions

These affect the SDD harness itself.

Examples:

- use local `tasks.json`;
- require human approval before implementation;
- run `pytest` as the test command;
- create one branch per feature;
- do not commit automatically.

These should be recorded in onboarding decisions, usually:

```text
decisions/answers.md
```

If they are feature-specific, also mention them in the feature spec.

---

## Assumption risk levels

Each assumption must be categorized by risk.

### Low risk

Safe, reversible, and consistent with existing project conventions.

Example:

```text
Assume the new tests should live next to existing CLI tests.
```

Low-risk assumptions may be used to produce a draft spec.

---

### Medium risk

May affect implementation shape or user behavior, but is easy to correct during spec review.

Example:

```text
Assume the default number of recent notes is 5.
```

Medium-risk assumptions may be used in a spec draft, but must be clearly visible.

---

### High risk

May affect security, data integrity, backwards compatibility, external APIs, billing, authentication, or irreversible migrations.

Example:

```text
Assume all authenticated users may access all notes.
```

High-risk assumptions should normally become blocking open questions.

Do not implement based on high-risk assumptions without developer approval.

---

## Required assumption format

Each assumption in `assumptions.md` is a card under the `## Pending` section, following the `assumptions.md` template. Set the card's risk class (`risk-low`, `risk-medium`, `risk-high`) to match the risk level:

```md
::: card risk-medium
#### A1 — Short title [!pending Pending]

- **Assumption:** What Claude Code is assuming.
- **Reason:** Why this assumption was made.
- **Risk / impact if wrong:** Low | Medium | High — what breaks if incorrect.
- **Blocks implementation:** Yes | No
- **Related requirements:** REQ-001
:::
```

When the developer accepts or rejects an assumption, move its card to the `## Accepted` or `## Rejected or replaced` section and update the badge (`[!ok Accepted]` / `[!rejected Rejected]`), recording the date and the decision.

---

## When to ask instead of assuming

Ask the developer instead of assuming when the answer affects:

- user permissions;
- security;
- privacy;
- data deletion;
- billing;
- irreversible migrations;
- external API contracts;
- public CLI/API behavior;
- backwards compatibility;
- legal/compliance behavior;
- whether to add a dependency;
- whether to change architecture;
- whether to skip human approval;
- whether to enable MCPs or hooks.

---

## When assumptions are acceptable

Claude Code may make an assumption when:

- the assumption is low or medium risk;
- the assumption is consistent with existing project conventions;
- the assumption is easy to review and reverse;
- the assumption is written in `assumptions.md`;
- the spec remains understandable without hidden context.

---

## Relationship between assumptions and open questions

Use `assumptions.md` when Claude Code can proceed with a reasonable draft.

Use `open-questions.md` when Claude Code cannot safely proceed.

Example:

### Use assumption

```text
The brief does not specify empty-state copy. Assume: "No notes found."
```

This is reversible and low risk.

### Use open question

```text
The brief does not specify whether users can see other users' notes.
```

This affects permissions and must be answered.

---

## Approval behavior

Human approval of a spec means:

- the developer has reviewed requirements;
- the developer has reviewed design;
- the developer has reviewed tasks;
- the developer accepts or corrects assumptions;
- unresolved blocking questions are answered or explicitly deferred.

After approval, assumptions that remain in the spec are treated as accepted for that feature.

---

## Implementation behavior

The `implementer` agent must read `assumptions.md` before implementation.

If `assumptions.md` contains any item with:

```text
Blocks implementation: Yes
```

the implementer must stop and ask for clarification.

If assumptions contradict `requirements.md`, `design.md`, or developer instructions, the implementer must stop.

---

## Reviewer behavior

The `reviewer` agent must check:

- whether implementation relies on undocumented assumptions;
- whether all listed assumptions were respected;
- whether high-risk assumptions were implemented without approval;
- whether any assumption should be converted into an ADR or project convention.

---

## Examples

### Good assumption

```md
::: card risk-medium
#### A1 — Default recent notes limit [!pending Pending]

- **Assumption:** The default number of recent notes shown by the CLI is 5.
- **Reason:** The brief does not specify a default; existing list commands use small default result sets.
- **Risk / impact if wrong:** Medium — the CLI shows too many or too few notes by default.
- **Blocks implementation:** No
- **Related requirements:** REQ-001
:::
```

### Bad assumption

```md
Users can see all notes.
```

This is bad because it does not explain risk, impact, or whether it blocks implementation.

### Better as open question

A permissions decision like this belongs in `open-questions.md` as a blocking question card:

```md
::: card blocking-yes
#### Q1 — Should users see only their own notes? [!blocking Blocking]

- **Question:** Should `notes recent` return only notes owned by the current user?
- **Why it matters:** Affects authorization and data privacy.
- **Default if unanswered:** None — blocking.
:::
```