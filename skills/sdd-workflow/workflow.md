# SDD workflow

This file contains the operational workflow for SDD tasks.

## 1. Select or create task

A task must have:

- ID;
- title;
- slug;
- description;
- `sdd` flag or equivalent policy;
- status;
- spec path;
- approval metadata.

If the developer describes a new feature informally, create a task entry before creating the spec.

## 2. Decide if SDD applies

Use project policy from `CLAUDE.md`.

If SDD does not apply, state why and follow the non-SDD workflow.

If SDD applies, continue.

## 3. Create spec

For a `pending` task, create:

```text
specs/<feature-slug>/requirements.md
specs/<feature-slug>/design.md
specs/<feature-slug>/tasks.md
```

Use `spec-format.md` (markdown is the source of truth; do not hand-write spec HTML). Keep each file concise: reference other spec files by ID, never restate their content.

Recommended order:

1. Requirements.
2. Design.
3. Tasks.
4. Requirement-to-test mapping.

## 4. Stop for approval

When the spec is complete:

1. Set status to `spec_ready`.
2. Render the spec for the developer: `node scripts/render-spec.mjs specs/<feature-slug>/` (or the Python renderer — see `spec-format.md` § Rendering). The HTML output is a gitignored artifact.
3. Summarize the spec and point the developer at the rendered files.
4. Ask the developer to approve or request changes.
5. Do not implement.

## 5. Revise spec if requested

If the developer asks for changes:

1. Update spec files.
2. Record changed assumptions.
3. Keep status as `spec_draft` or `spec_ready` according to project policy.
4. Ask again for approval.

## 6. Implement approved spec

Only after approval:

1. Set status to `in_progress`.
2. Read `tasks.md`.
3. Execute tasks sequentially.
4. Add/update tests.
5. Run configured validation.
6. Mark completed tasks in `tasks.md` (change the item's status marker to `[x]`; `[>]` in progress, `[!]` blocked).
7. Set status to `review`.

## 7. Review

The reviewer validates:

- requirements implemented;
- tests cover requirements;
- design followed;
- conventions respected;
- validation commands pass;
- no unauthorized scope creep.

The reviewer also flags significant decisions settled by the spec,
implementation, or review (architectural choices, rejected alternatives,
workflow rules) for the decision log — see §9.

The reviewer also checks conciseness: content duplicated within a spec file or across the spec's files is a finding.

Write `review.md`, then re-render the spec directory so the developer reads current HTML.

## 8. Documentation phase

Runs after the reviewer approves and before the task is marked `done`. The state machine is unchanged; the phase is tracked with the task fields `documentation_required`, `documentation_status` (`pending|updated|not_required`), and `documentation_targets`.

1. The reviewer decides whether documentation is required and lists the targets (see the review checklist §7).
2. If not required: set `documentation_required: false`, `documentation_status: "not_required"`, and continue to completion.
3. If required: invoke the `documenter` agent. It updates only the listed targets, cites the source spec/task where possible, appends the `history.md` entry, and reports updated vs unaffected targets.
4. The reviewer runs a lightweight docs re-check and sets `documentation_status: "updated"` — or returns the gaps to the documenter.

The documenter never runs before technical review; docs must describe the implementation as reviewed.

## 9. Complete

If reviewer approves and documentation is `updated` or `not_required`:

1. Set task status to `done`.
2. Append to `history.md` (skip if the documenter already did).
3. Include changed files and commands run.
4. If the spec or review settled a significant decision, propose a
   decision-log entry: architectural choices →
   `decisions/architecture-decisions.md` (or `docs/adr/` if configured),
   rejected alternatives → `decisions/rejected-options.md`, workflow rules
   → `decisions/workflow-decisions.md`. Propose only — the developer
   approves the entry text. Do not log trivial decisions; never log
   secrets or sensitive operational data.

If reviewer rejects:

1. Set status to `in_progress`, `spec_draft` or `blocked`.
2. List exact corrections.

## 10. History entry format

Append to `history.md` by copying the commented entry block from the file itself
(the format lives in `templates/history.md.template`) and inserting the filled-in
entry immediately after the `<!-- INSERT-ENTRY-HERE -->` marker, newest first.
Remove the "No entries yet" paragraph when adding the first entry.

## Workflow variant: intake from functional document

Use this variant when the source input is a functional document, PRD, ticket, user story, or informal feature description.

Flow:

```text
functional document
→ intake analysis
→ assumptions.md
→ open-questions.md
→ requirements.md
→ design.md
→ tasks.md
→ acceptance-tests.md
→ human approval
→ implementation
→ review
```

Rules:

1. Do not implement directly from the functional document.
2. If blocking questions exist, keep the task in spec_draft.
3. If only non-blocking questions or explicit assumptions exist, the task may move to spec_ready.
4. Only the developer may move the task to human_approved.