# Intake from Functional Document

## Purpose

Use this procedure when the developer provides a functional document, product brief, ticket, user story, or informal feature description and asks Claude Code to generate SDD specs from it.

A functional document is source material. It is not an approved implementation spec.

Claude Code must convert the functional document into structured SDD files before any implementation work begins.

---

## Inputs

Expected input sources may include:

- `docs/functional/<feature>.md`
- product requirement documents
- tickets from Linear, Jira, GitHub Issues, etc.
- pasted feature descriptions
- user stories
- acceptance criteria
- design notes
- screenshots or UI notes
- API notes
- existing implementation references

---

## Required output

For each functional document, Claude Code must create or update:

```text
specs/<feature-slug>/
├── requirements.md
├── design.md
├── tasks.md
├── assumptions.md
├── open-questions.md
└── acceptance-tests.md
```

Some files may be short, but they should exist if the project has enabled the full SDD intake flow.

---

## Core rule

Do not implement code directly from a functional document.

The required conversion flow is:

```text
functional document
    → requirements.md
    → design.md
    → tasks.md
    → human approval
    → implementation
    → review
```

---

## Intake procedure

### Step 1 — Identify the feature

Extract the following from the functional document:

- feature name;
- feature slug;
- source document path;
- user or actor;
- desired behavior;
- business/product goal;
- known constraints;
- explicit non-goals;
- acceptance criteria;
- possible edge cases;
- open questions;
- assumptions.

If the feature name is not explicit, propose one and ask the developer to confirm it unless the naming is obvious.

---

### Step 2 — Create or update the task record

Create or update the corresponding task in the configured task storage.

Default local task storage:

```text
tasks.json
```

The task must follow the schema of `tasks.json` (see `templates/tasks.json.template` in the kit) and include at least:

```json
{
  "id": "TASK-XXX",
  "title": "<feature title>",
  "slug": "<feature-slug>",
  "description": "<short description>",
  "source": "<path-to-functional-document>",
  "sdd": true,
  "status": "pending",
  "spec_path": "specs/<feature-slug>",
  "approval": {
    "required": true,
    "approved_by": null,
    "approved_at": null,
    "notes": null
  },
  "links": {
    "issue": null,
    "pr": null,
    "branch": null
  },
  "created_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD"
}
```

If the project uses Linear, Jira, GitHub Issues, or another MCP-backed task system, follow the project-specific task storage policy.

Do not invent external task IDs.

---

### Step 3 — Read project context

Before writing specs, inspect relevant project context:

- `CLAUDE.md`
- `docs/architecture.md`
- `docs/conventions.md`
- `docs/adr/`
- existing specs under `specs/`
- existing tests
- relevant source files
- package manager and project scripts
- existing command patterns or APIs related to the feature

The goal is to produce specs that fit the actual project, not generic specs.

---

### Step 4 — Determine ambiguity level

Classify the functional document as one of:

```text
clear
partially_ambiguous
blocked_by_missing_information
```

Use this classification internally and reflect it in the generated spec files.

#### clear

The functional document contains enough information to generate requirements, design and tasks.

Action:

- generate specs;
- record minor assumptions if any;
- set task to `spec_ready`;
- stop.

#### partially_ambiguous

The functional document is mostly clear, but some details are missing.

Action:

- generate a draft spec;
- write explicit assumptions in `assumptions.md`;
- write unresolved questions in `open-questions.md`;
- do not hide uncertainty;
- set task to `spec_ready` only if assumptions are safe and reversible.

#### blocked_by_missing_information

The functional document lacks essential information.

Action:

- create `open-questions.md`;
- optionally create partial `requirements.md`;
- do not create a detailed implementation plan;
- keep task in `spec_draft`;
- ask the developer for clarification.

---

## Step 5 — Generate `requirements.md`

Convert the functional document into testable requirements.

Preferred format depends on project configuration:

- EARS;
- user stories;
- Given / When / Then;
- plain requirements.

If no format is configured, use EARS by default because it maps well to tests.

Example EARS requirement:

```text
When the user runs `notes recent` without `--limit`, the system shall display at most five notes ordered from newest to oldest.
```

Requirements should be:

- atomic;
- testable;
- traceable to the functional document;
- free of implementation details unless required;
- written from observable system behavior.

Avoid vague requirements such as:

```text
The system should be user-friendly.
```

Prefer concrete requirements such as:

```text
When no notes exist, the system shall display a clear empty-state message instead of failing silently.
```

---

## Step 6 — Generate `design.md`

Translate the requirements into a technical plan.

The design should include:

- files to inspect;
- files likely to change;
- new functions/classes/modules, if any;
- API or CLI changes;
- data model changes, if any;
- validation strategy;
- test strategy;
- migration strategy, if relevant;
- risks;
- non-goals;
- compatibility concerns.

Do not over-engineer.

Do not introduce new dependencies unless clearly justified.

If unsure about the technical approach, mark it as an open question instead of guessing.

---

## Step 7 — Generate `tasks.md`

Break the design into small implementation tasks.

Each task should be:

- concrete;
- ordered;
- independently understandable;
- traceable to one or more requirements;
- suitable for the `implementer` agent.

Good task:

```text
T2 — Add CLI parser support for `notes recent --limit N`.
```

Bad task:

```text
T2 — Improve the CLI.
```

Tasks should include validation tasks:

- add or update tests;
- run tests;
- run lint;
- run typecheck;
- update documentation if needed.

---

## Step 8 — Generate `assumptions.md`

Use `assumptions.md` for decisions Claude Code had to make because the functional document was incomplete.

Assumptions must be explicit and reviewable.

Do not bury assumptions inside prose.

Each assumption should include:

- the assumption;
- why it was made;
- impact if wrong;
- whether it blocks implementation.

---

## Step 9 — Generate `open-questions.md`

Use `open-questions.md` for unresolved questions that require developer input.

A question is blocking if implementation could produce the wrong product behavior without an answer.

A question is non-blocking if it only affects polish, naming, copy, or a reversible detail.

---

## Step 10 — Generate `acceptance-tests.md`

Generate test scenarios that validate the requirements.

These are not necessarily final test code.

They should describe:

- scenario;
- preconditions;
- action;
- expected result;
- related requirements.

Acceptance tests should help the developer approve the spec and help the implementer write real tests.

---

## Step 11 — Update task status

After generating the spec files:

### If the spec is complete enough for human review

Set status to:

```text
spec_ready
```

Then stop.

### If the spec is incomplete and requires answers

Set status to:

```text
spec_draft
```

Then ask the developer the blocking questions.

### Do not set the task to `human_approved`

Only the developer may approve the spec.

---

## Step 12 — Stop before implementation

After generating or updating the spec, Claude Code must stop.

Do not invoke the implementer.

Do not edit production code.

Do not write implementation files.

Do not run broad refactors.

Allowed actions before approval:

- create spec files;
- inspect project files;
- update task metadata;
- ask questions;
- propose a design;
- propose test scenarios.

Forbidden actions before approval:

- modify source code;
- modify production configuration;
- add dependencies;
- create database migrations;
- change tests as if implementation has started;
- commit implementation changes.

---

## Required final response after intake

When finished, respond with:

```text
Generated SDD spec for <feature-name>.

Created or updated:
- specs/<feature-slug>/requirements.md
- specs/<feature-slug>/design.md
- specs/<feature-slug>/tasks.md
- specs/<feature-slug>/assumptions.md
- specs/<feature-slug>/open-questions.md
- specs/<feature-slug>/acceptance-tests.md

Current task status: <spec_ready | spec_draft>

Next step:
- Review the spec.
- Answer any blocking questions.
- Approve the spec before implementation.
```

Do not include the full spec in the chat unless the developer asks for it.

---

## Quality checklist

Before marking intake complete, verify:

- [ ] The functional document was treated as source material, not implementation authority.
- [ ] Requirements are testable.
- [ ] Design maps to existing architecture.
- [ ] Tasks are actionable.
- [ ] Assumptions are explicit.
- [ ] Open questions are categorized as blocking or non-blocking.
- [ ] Acceptance tests map to requirements.
- [ ] Task status is correct.
- [ ] Claude stopped before implementation.