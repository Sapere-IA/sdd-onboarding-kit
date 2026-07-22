---
name: documentation-update
description: Update documentation affected by a completed task, after technical review and before the task is marked done. Use when review identifies documentation targets.
---

# Documentation update

## Purpose

Keep user-facing, developer-facing, and operational documentation aligned
with implemented changes — after code review (so docs describe what was
actually merged-reviewed) and before `done` (so docs are not forgotten).

This skill is the procedure behind the harness's documentation phase: the
reviewer decides whether docs are required and lists targets
(`documentation_required`, `documentation_targets`), the `documenter`
agent executes this procedure, and the reviewer re-checks before the task
becomes `done` (`documentation_status: pending → updated|not_required`).
The phase uses task fields, not extra states.

## When to use

- A reviewed task changed behavior, APIs, setup steps, commands, or
  structure that existing docs describe.
- The reviewer listed documentation targets for a task.
- The project map or README has drifted from reality after a change.

## When not to use

- Before technical review — implementation may still change.
- For documenting rejected or unmerged alternatives.
- When no doc actually describes the changed behavior (do not invent new
  doc surfaces without asking).

## Required inputs

- The completed task/spec and its review notes.
- The list of documentation targets (README, API docs, setup docs,
  changelog/history, project map, user-facing docs).

## Procedure

1. Identify only the docs directly affected by the task.
2. Update them to match the reviewed implementation; keep each doc's
   existing voice and structure.
3. Link or cite the source spec/task where the doc format allows it.
4. Append the task summary to `history.md` if the project uses it.
5. Report which docs were updated and which were judged unaffected, so the
   reviewer can re-check.
6. Set `documentation_status: "updated"` only after the report; the
   reviewer's re-check gates `done`.

## Output artifact

Updated documentation files plus a short list of updated/unaffected
targets in the task's review notes or summary.

## Safety constraints

- Never expose secrets, internal URLs, or credentials in documentation.
- Do not document unreviewed implementation details.
- Do not rewrite unrelated documentation while updating a target.
