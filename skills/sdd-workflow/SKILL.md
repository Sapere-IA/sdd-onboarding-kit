---
name: sdd-workflow
description: Run the Spec Driven Development workflow for Claude Code. Use when starting, specifying, implementing or reviewing a feature through requirements, design, tasks, human approval, implementation and review.
argument-hint: "[task-id-or-feature-description]"
---

# SDD Workflow Skill

Use this skill when the developer asks to work through Spec Driven Development or when the project `CLAUDE.md` says that a task requires SDD.

## Required supporting files

Read the relevant file before acting:

- `workflow.md` for the full procedure.
- `task-state-machine.md` for status transitions.
- `spec-format.md` when creating or editing specs.
- `review-checklist.md` when reviewing implementation.
- `examples.md` when an output example is needed.

## Core rule

Do not write implementation code for an SDD task until the spec is approved according to the project approval policy.

## Standard execution

1. Identify the task.
2. Check the task status.
3. Route according to `task-state-machine.md`.
4. If the task needs a spec, create/update the spec.
5. If the spec is ready but not approved, stop.
6. If approved, implement from the spec.
7. Validate and review.
8. Record completion.

## Argument

Use `$ARGUMENTS` as the task ID, issue reference, feature slug or feature description supplied by the developer.

If `$ARGUMENTS` is empty, select the next eligible task from the configured task store.

## Functional document intake

When the developer provides a functional document or asks to generate specs from a product/functional description, read:

- `intake-from-functional-doc.md`
- `assumptions-policy.md`
- `open-questions-policy.md`

Then generate or update:

- `requirements.md`
- `design.md`
- `tasks.md`
- `assumptions.md`
- `open-questions.md`
- `acceptance-tests.md`

Do not implement code directly from a functional document.
Stop after creating the spec unless the developer explicitly approves implementation.