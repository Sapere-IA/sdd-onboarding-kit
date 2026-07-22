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
└── open-questions.md      # when questions are unresolved
```

When creating a new spec, instantiate each file from the corresponding `.md.template` in `.claude/skills/sdd-workflow/templates/` and replace every `{{PLACEHOLDER}}` token. Do not copy `spec.css`/`spec.js` into the feature folder — the renderer inlines them.

## Rendering

```bash
node scripts/render-spec.mjs specs/<feature-slug>/     # Node projects
python scripts/render_spec.py specs/<feature-slug>/    # Python projects
```

(Only one renderer is installed per project.) Each `<name>.md` becomes a self-contained `<name>.html` next to it, styled from the assets in `.claude/skills/sdd-workflow/templates/`. Render before asking the developer to review; never hand-edit the HTML output.

## Ownership and no-duplication rule

Each file owns one content type. Everything else **references by ID** — `REQ-001`, `AC-002`, a section anchor like `design.md § Data model changes` — and never restates the content. Duplicated prose within a document or across a spec's documents is a spec defect: the reviewer flags it as a finding.

| File | Owns |
| --- | --- |
| `requirements.md` | Observable behavior (the only place behavior is stated) |
| `design.md` | The technical plan |
| `tasks.md` | Implementation sequencing |
| `review.md` | Verdicts and evidence |
| `acceptance-tests.md` | Test scenarios |
| `assumptions.md` / `open-questions.md` | Explicit uncertainty |

## Conciseness rules

- Short declarative sentences. No filler narrative, no restated context the reader already has.
- One line per requirement, finding, risk, or rule. Tables for enumerable facts.
- Secondary sections that do not apply are collapsed to a single line (`None.` / `Not applicable.` / `None expected.`) with their placeholder tables deleted — the explicit line is kept only where absence is information (UI criteria, visual evidence, external dependencies, security). Guidance comments (`<!-- … -->`) may be deleted once the section is filled.

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

Inside a card, a leading `####` heading becomes the card header: an ID prefix (`A1 — `) becomes a chip, a trailing inline badge stays in the header. Tabs from the old HTML format are gone — use `###` subsections instead.

## Document contents

Section-by-section guidance lives in the templates themselves (as `<!-- … -->` comments). Summary of purpose:

- **`requirements.md`** — behavior: summary, functional/non-functional requirements, edge cases, error states, acceptance criteria, UI criteria and visual evidence (when a UI is affected), external dependencies, documentation expectations, decision candidates, requirement-to-test mapping.
- **`design.md`** — plan: technical summary, data flow SVG, files to change / not to change, interfaces, data model, dependency freshness evidence, security, documentation targets, test design, risks, rollback.
- **`tasks.md`** — ordered timeline of small verifiable tasks referencing requirement IDs, plus the validation checklist.
- **`review.md`** — traceability table with cell verdicts, commands run, findings (`BLK-n`/`NBK-n` rows), drift check, deep-review record, documentation decision, propose-only proposals, decision.

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
