# Spec format

Each SDD feature gets a directory of **markdown** documents. Markdown is the single source of truth: agents read and write only the `.md` files. Styled HTML is a **rendered artifact**, generated on demand for human review and gitignored in the project.

```text
specs/<feature-slug>/
├── requirements.md
├── design.md
├── tasks.md
├── review.md
├── acceptance-tests.md    # when acceptance tests are drafted
├── assumptions.md         # when assumptions were made
├── open-questions.md      # when questions are unresolved
├── spec.html              # rendered page (gitignored)
└── feedback.md            # developer feedback (gitignored), deleted once applied
```

When creating a new spec, instantiate each file from the corresponding `.md.template` in this skill's `templates/` folder, replace every `{{PLACEHOLDER}}` token, and delete the optional sections that do not apply.

## Rendering

```bash
sh scripts/render-spec.sh specs/<feature-slug>/      # → specs/<feature-slug>/spec.html
pwsh scripts/render-spec.ps1 specs/<feature-slug>/   # Windows
sh scripts/render-spec.sh history.md                 # single file → rendered page next to it
```

The script embeds the folder's markdown in **one** self-contained page, `spec.html`, which renders in the browser (no Node or Python needed) from the assets in this skill's `templates/` folder: an overview tab ("At a glance" from the requirements `## Summary`, ID counts, task progress, review decision, and "Needs your decision" listing pending question and assumption cards), one tab per document, and collapsible `##` sections. Every item with an ID gets review buttons; the developer saves their verdicts as a feedback file (§ Feedback file). Render before asking the developer to review and after every spec change; never hand-edit the HTML (a gitignored artifact).

## Feedback file

The developer reviews on the page and saves `specs/<feature-slug>/feedback.md` — or downloads `<feature-slug>.feedback.md` (usually to their downloads folder), or pastes the same text in chat:

```markdown
---
doc: feedback
feature_slug: example-feature
generated: 2026-10-06T10:00:00Z
verdict: approve            # approve | request_changes | none
---

## Items

- REQ-001: accept
- REQ-003: change — Link expires in 15 min, not 60
- A1: reject — Order by created_at instead
- Q1: answer — Exclude archived notes
- T2: comment — Split into two tasks

## General

Free text from the developer.
```

Apply it:

1. Find it: the spec folder first; otherwise ask the developer for the downloaded path or the pasted text.
2. Apply each item to the markdown file that owns the ID:
   - `answer` → move the question card to `## Resolved` with the answer as its **Decision:**, then reflect it in the affected files;
   - `accept` → an assumption moves to `## Accepted`; any other item needs no edit;
   - `reject` → an assumption moves to `## Rejected or replaced`; revise the affected requirements; for other items, remove or replace the item;
   - `change` → edit the owning item as asked;
   - `comment` → address it, or turn it into an open question;
   - `## General` → apply like a `comment`.
3. Never edit the HTML. Re-render, delete the feedback file, and summarize what changed in ≤ 5 lines.
4. `verdict: approve` with no `change`/`reject` items is the developer's approval of the spec — record it per `task-state-machine.md`. If the feedback also changed the spec, the approval does not carry over: re-render and ask for approval of the revised spec.

## Ownership and no-duplication rule

Each file owns one content type. Everything else **references by ID** — `REQ-001`, `AC-002`, a section anchor like `design.md § Interfaces and data` — and never restates the content. Duplicated prose within a document or across a spec's documents is a spec defect: the reviewer flags it as a finding.

| File | Owns |
| --- | --- |
| `requirements.md` | Observable behavior (the only place behavior is stated) |
| `design.md` | The technical plan |
| `tasks.md` | Implementation sequencing |
| `review.md` | Verdicts and evidence |
| `acceptance-tests.md` | Test scenarios |
| `assumptions.md` / `open-questions.md` | Explicit uncertainty |

## Conciseness rules

The whole spec reads in about five minutes. Budgets:

| Item | Budget |
| --- | --- |
| `## Summary` | ≤ 3 sentences |
| Requirement, edge case, error, acceptance criterion, finding, risk | One sentence each |
| Design section | Fits on one screen: ≤ ~10 lines, or a table |
| Card field (assumption, question, acceptance test) | One sentence |
| `tasks.md` | ≤ ~8 tasks; split the feature into several specs otherwise |

- Cut anything the reader can infer: restated context, rationale for the obvious, generic advice, the text behind an ID.
- Short declarative sentences; tables for enumerable facts; no filler narrative.
- Delete optional sections that do not apply (their template comment says "Optional — delete if not applicable"). Keep the single line `None.` only where absence is information (external dependencies, security, findings, documentation targets).
- Delete guidance comments (`<!-- … -->`) once a section is filled.

## Markdown conventions (what the renderer understands)

Standard markdown — headings `##`–`####`, paragraphs, lists, GFM tables, fenced code, `**bold**`, `*italic*`, `[links](…)`, `> quotes`, `---` rules — plus the SDD-specific conventions below. Raw HTML blocks (a line starting with `<`) pass through untouched, which is how inline SVG diagrams are embedded. HTML comments are preserved but invisible in the rendered page.

### Frontmatter → header

Every document starts with YAML frontmatter (simple `key: value` lines only). `title` becomes the page heading; every other key becomes a row of the header meta-table. Keys named `status`, `approval`, `human_approval`, `review_status`, `decision`, `documentation_status` render as colored badges; keys ending in `_id`, `_slug`, `_document`, `_path`, `_command`, `_date` (and `created`) render as code.

```yaml
---
doc: requirements
title: Requirements — Feature title
task_id: TASK-001
feature_slug: feature-slug
status: spec_draft
human_approval: pending
---
```

### Requirement rows

A line of the form `ID: text` renders as a styled requirement row. Recognized prefixes and their colors: `REQ` (orange), `NFR` (violet), `EDGE` (yellow), `ERR`/`BLK` (red), `AC`/`UI`/`IMG` (green), `NBK` (yellow), `T<n>` (orange). A table cell containing only an ID token renders as the matching chip.

```markdown
REQ-001: When the user runs `notes recent`, the system shall print at most five notes.
```

### Status and verdict markers

- Inline badge: `[!ok approved]`, `[!warning needs_changes]`, `[!blocking rejected]`, `[!pending TODO]`, `[!draft Draft]`.
- Table-cell verdict (colors the whole cell): start the cell with `!ok`, `!warning`, `!blocking`, or `!pending` — e.g. `| REQ-001 | !ok Yes | !blocking No |`.

### Task timeline (`tasks.md`)

An ordered list whose items start with a status marker renders as the milestone timeline. Markers: `[ ]` pending, `[x]` done, `[>]` in progress, `[!]` blocked. Optional `T<n>:` label chip; optional ` — ` separates title from detail.

```markdown
1. [x] T1: Add failing tests — Cover REQ-001 before implementing.
2. [ ] T2: Implement the change
```

These markers are the single mechanism for subtask progress; the global task status lives in `tasks.json`, never in spec files.

### Checklists

An unordered list whose items all start with `[ ]` (or `[x]`) renders as a styled checklist.

### Containers

Fenced blocks wrap content in styled boxes; close with `:::` on its own line.

```markdown
::: card risk-high            <!-- also: risk-medium, risk-low, blocking-yes -->
#### A1 — Card title [!pending Pending]

- **Field:** value            <!-- a list of "**Key:** value" items renders as a field grid -->
- **Another field:** value
:::

::: collapse Section title    <!-- collapsible section -->
Content.
:::

::: note                      <!-- highlighted note box -->
::: diagram                   <!-- centered container for an inline SVG -->
```

Inside a card, a leading `####` heading becomes the card header: an ID prefix (`A1 — `) becomes a chip, a trailing inline badge stays in the header. Page tabs are generated (one per document) — structure a document with `###` subsections.

## Document contents

Section guidance lives in the templates (as `<!-- … -->` comments). Summary of purpose:

- **`requirements.md`** — behavior: summary, requirements (REQ/NFR), edge cases and errors, acceptance criteria; UI criteria and visual evidence only when a UI is affected.
- **`design.md`** — plan: summary, optional data-flow SVG, files to change (and not to change), interfaces and data, dependency freshness evidence, security, test design, documentation targets, risks and rollback.
- **`tasks.md`** — ordered timeline of small verifiable tasks referencing requirement IDs.
- **`review.md`** — decision, traceability table with cell verdicts, commands run, findings (`BLK-n`/`NBK-n` rows), drift and high-risk record, documentation decision, propose-only proposals.

## Requirements formats

### EARS

Use EARS when requirements should map cleanly to tests:

```text
When <trigger>, the system shall <response>.
If <condition>, the system shall <response>.
While <state>, the system shall <response>.
```

### User stories

`As a <role>, I want <capability>, so that <benefit>.` — with acceptance criteria under each story.

### Given/When/Then

`Given <context> / When <action> / Then <outcome>` — when behavior is scenario-driven.
