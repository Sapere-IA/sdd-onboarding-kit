# SDD onboarding instructions for Claude Code

You are configuring the current target repository to use **Spec Driven Development (SDD)** with Claude Code.

Your job is to install a project-specific SDD harness. Do not implement product features during onboarding unless the developer explicitly asks for a separate implementation task after the harness is installed.

## Mandatory read order

The reading is tiered so you can start the interview quickly without losing rigor. Read the **core** tier before Phase 1 and the questions; read each **on-demand** group when you reach the work it governs (you must still read every on-demand file before you generate or configure the component it covers — the tiering changes *when* you read, not *whether*).

### Core — read before Phase 1 and the questions (6)

1. `reference/sdd-theory.md`
2. `reference/harness-engineering.md`
3. `reference/claude-code-primitives.md`
4. `questions.md`
5. `output-project-structure.md`
6. `templates/CLAUDE.md.template`

### On-demand — read when you reach the relevant step

- **Before generating subagents (Phase 4 → Subagents):** `agents/leader.md`, `agents/spec-author.md`, `agents/implementer.md`, `agents/reviewer.md`, `agents/documenter.md`.
- **Before generating the core skill (Phase 4 → Skill):** `skills/sdd-workflow/SKILL.md`, `skills/sdd-workflow/workflow.md`, `skills/sdd-workflow/spec-format.md`, `skills/sdd-workflow/review-checklist.md`.
- **Only if the developer enables hooks (Phase 4 → Hooks):** `hooks/hooks-policy.md`.
- **Only if the developer configures MCPs (Phase 4 → MCPs):** `mcps/mcp-policy.md`.
- **Only if the developer provides a functional document:** the intake set listed under "Functional document intake" below.
- **Only for selected optional packs:** that pack's files under `skills/optional/<name>/` and any policy named in its row of "Referenced policy files".

Each on-demand file is also re-named at the step that needs it, so following the phases in order surfaces them at the right time.

If any file you need at its tier is missing, stop and tell the developer which file is missing.

## Phase 1 — Inspect the target repository

Inspect the current repository before asking configuration questions.

Identify:

- language or languages;
- framework;
- package manager;
- test framework;
- lint/typecheck/format commands;
- existing `README`, `docs`, `Makefile`, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`, `build.gradle`, or equivalent;
- existing `CLAUDE.md`, `.claude/`, `.mcp.json`, task files, issue references, CI config;
- existing architecture/conventions documentation;
- existing git branch and cleanliness status;
- available external CLIs (`gh`, `vercel`, `supabase`, cloud CLIs): detect which exist so narrow CLI calls can be preferred over broad MCP loading (`reference/cli-vs-mcp-policy.md`) — do not require, install, or authenticate any of them, and record nothing about credentials beyond authenticated yes/no;
- **spec renderer runtime**: whether `node` and/or `python3`/`python` is available, and which matches the project (a `package.json` project gets the Node renderer, a Python project gets the Python renderer). Exactly one of `scripts/render-spec.mjs` / `scripts/render_spec.py` is installed. If both runtimes are plausible or neither is detected, ask the developer instead of guessing.

Do not overwrite existing files without first reading them.

Note for inspection results:

- If no test/lint toolchain is installed, or `jq` is missing, record it. Recommend *against* enabling tool-running hooks (`run-tests-after-edit` and similar) until the toolchain and sources exist — on a repo with no code or no toolchain, such a hook fires on every edit and only produces noise. The generated `run-tests.sh`/`run-lint.sh` no-op cleanly in that state (see "Test and lint scripts"), but a disabled hook is the better default until there is something to run.
- If the repository has no code yet — only a plan, brief, or build spec — see "Greenfield and plan-only repositories" below before generating the harness.

## Phase 2 — Ask unresolved decisions

Use `questions.md` as the source of questions.

Ask only questions that cannot be inferred confidently from the repository. Group them so the developer can answer quickly.

You must not assume:

- whether every task uses SDD;
- whether human approval is mandatory;
- what requirements format to use;
- what task storage backend to use;
- what MCPs to configure;
- what hooks to enable;
- what commands run tests, lint, typecheck or formatting;
- whether to create branches, commits or pull requests;
- whether tasks may be skipped as too small for SDD;
- which optional skill packs to install;
- how strictly dependency/API freshness verification should be enforced;
- whether autonomous workflows are allowed beyond read-only monitoring;
- whether deep review is required (vs recommended) for any category;
- whether the documentation phase may be relaxed.

If the developer wants a default recommendation, propose the safe default profile in this file (offered as a single question first — see the `Recommended defaults profile` block at the top of `questions.md`; if accepted, ask only the §7 commands, §11 protected files, §1 SDD scope, and flagged deviations).

## Safe default profile

Use this only if the developer explicitly asks for recommended defaults.

```yaml
sdd_scope: tasks_marked_sdd_true
human_approval_required: true
requirements_format: EARS
task_storage: local_tasks_json
spec_storage: specs/<feature-slug>/
history_storage: history.md
local_first: true                  # no external MCPs or CLIs required
mcp_profile: none_by_default       # external MCPs only on explicit opt-in
hooks_profile: recommend_but_do_not_enable_without_approval
git_branch_policy: ask_before_creating_branch
git_commit_policy: ask_before_committing
git_mutations: explicit_permission_per_action
tests_required_before_done: true
reviewer_required_before_done: true
documentation_phase: enabled       # not done while required docs pending
dependency_freshness_policy: required_for_high_risk_categories
failure_learning: proposals_enabled_no_automatic_writes
memory_scope: project_default_global_only_with_explicit_approval
browser_testing: disabled_unless_frontend_detected_and_opted_in
autonomy: disabled_except_documented_readonly_monitoring
deep_review: recommended_for_high_risk_paid_modes_per_invocation_approval
session_recovery_rule: enabled_in_claude_md
```

## Greenfield and plan-only repositories

Phase 1 assumes an existing codebase to inspect. Some repositories have no code yet — only a plan, product brief, build spec, or an `IMPLEMENTATION_PLAN.md`. The harness still installs; adjust as follows.

- **Record the planned layout, do not invent it.** If the plan describes a target directory structure, capture it in the project map as the *planned* layout (label it clearly as planned, not present). Do not fabricate files or commands that the plan does not state.
- **Defer command validation.** With no toolchain or sources, the test/lint/build commands cannot be run or confirmed. Record them as `TODO: ask the developer` (or leave the script command empty) rather than guessing — the generated `run-tests.sh`/`run-lint.sh` no-op cleanly until filled. Recommend leaving tool-running hooks disabled until the toolchain and code exist (see Phase 1 note).
- **Seed `tasks.json` from the plan.** When the repository *is* a phased plan (e.g. `IMPLEMENTATION_PLAN.md` with numbered phases/specs), turn that plan into seeded tasks rather than shipping only the `TEMPLATE-001` example. Create one `pending` task per planned unit of work, with a stable `id`, `title`, `slug`, `spec_path`, and a `source` pointing at the plan section it came from. Keep `approval.required` per the §1/profile answers; do not pre-approve. This is often the highest-value step on a plan-only repo — confirm the granularity with the developer, then seed. If the developer prefers not to seed, keep the single example task.
- **Address `git init` explicitly — do not run it silently.** If the repository is not yet a git repo, initializing it is itself a mutation. The git-policy answers (branches/commits/PRs) presuppose a repo. Ask the developer whether to `git init`, or defer it to them; either way, record the decision in `decisions/answers.md`. Do not create branches or commits until the repo exists and the developer has approved git mutations.

## Phase 3 — Generate the project SDD harness

After the developer answers, create or update the following in the target repository:

```text
<project>/
├── CLAUDE.md
├── .claude/
│   ├── agents/
│   │   ├── leader.md
│   │   ├── spec-author.md
│   │   ├── implementer.md
│   │   ├── reviewer.md
│   │   ├── documenter.md
│   │   └── <browser-tester.md, if questions.md §18 selected it>
│   ├── skills/
│   │   ├── sdd-workflow/
│   │   │   ├── SKILL.md
│   │   │   ├── workflow.md
│   │   │   ├── spec-format.md
│   │   │   ├── task-state-machine.md
│   │   │   ├── review-checklist.md
│   │   │   ├── intake-from-functional-doc.md
│   │   │   ├── assumptions-policy.md
│   │   │   ├── open-questions-policy.md
│   │   │   ├── examples.md
│   │   │   └── templates/
│   │   │       ├── requirements.md.template
│   │   │       ├── design.md.template
│   │   │       ├── tasks.md.template
│   │   │       ├── review.md.template
│   │   │       ├── acceptance-tests.md.template
│   │   │       ├── assumptions.md.template
│   │   │       ├── open-questions.md.template
│   │   │       ├── spec-shell.html.template
│   │   │       ├── spec.css
│   │   │       └── spec.js
│   │   ├── sdd-update/
│   │   │   └── SKILL.md
│   │   └── <optional skill packs selected during onboarding>/
│   ├── context/
│   │   └── project-map.md
│   ├── reference/
│   │   └── <policy files vendored from the kit — see "Referenced policy files">
│   ├── hooks/
│   │   └── README.md
│   ├── settings.json
│   └── sdd-kit-manifest.json
├── specs/
├── decisions/
│   ├── answers.md
│   └── <decision-log files, if the decision-log pack is selected>
├── tasks.json
├── history.md
└── scripts/
    ├── init.sh
    ├── run-tests.sh
    ├── run-lint.sh
    ├── render-spec.mjs              # OR render_spec.py — exactly one, per the detected runtime
    ├── validate-sdd-structure.sh
    └── validate-sdd-structure.ps1   # PowerShell port — install for Windows-primary teams
```

Adapt every file to the target project. Do not leave unresolved placeholders such as `{{TEST_COMMAND}}` in final project files unless the developer explicitly says that the command is unknown and should remain as a TODO.

## Phase 4 — File generation rules

### `CLAUDE.md`

Create the project `CLAUDE.md` from `templates/CLAUDE.md.template`.

It must be concise and project-specific. It should contain:

- project summary;
- build/test/lint commands;
- SDD workflow policy;
- status transitions;
- human approval policy;
- where specs, tasks and history live;
- how to invoke the SDD skill;
- when not to use SDD;
- protected files or risky areas;
- the spec render command (`{{RENDER_COMMAND}}` → the installed renderer, e.g. `node scripts/render-spec.mjs` or `python scripts/render_spec.py`) and a pointer to `/sdd-update`.

Do not put the full theory of SDD into `CLAUDE.md`. Put long procedures in the project skill.

Do not embed a directory tree in `CLAUDE.md`; link the project map instead (replace `{{PROJECT_MAP_PATH}}` with the configured location).

### Project map

Generate a project map from `templates/project-map.md.template`, filled with the Phase 1 inspection results.

- Default location: `.claude/context/project-map.md`. Use `docs/project-map.md` if the developer prefers it visible in docs (see `questions.md` §12).
- Keep it concise: shallow annotated tree (2–3 levels), no exhaustive file listing, no generated/vendored directories.
- Record unknown commands as `TODO: ask the developer` — do not invent them.
- Never record secrets, credentials, or tokens.
- If the developer defers generation, record a clear TODO (in `decisions/answers.md` and the onboarding summary) instead of creating an empty file.
- The map carries its own maintenance rule: it must be updated when the repository structure changes significantly.

### Subagents

Copy and adapt:

- `agents/leader.md` to `.claude/agents/leader.md`
- `agents/spec-author.md` to `.claude/agents/spec-author.md`
- `agents/implementer.md` to `.claude/agents/implementer.md`
- `agents/reviewer.md` to `.claude/agents/reviewer.md`
- `agents/documenter.md` to `.claude/agents/documenter.md`

If the project already has agents with these names, merge carefully or ask before overwriting.

`reviewer.md` and `spec-author.md` link the deep-review policy. Vendor it to `.claude/reference/deep-review-policy.md` and rewrite both links per "Referenced policy files" below (the same policy is also linked from the always-installed `review-checklist.md` and the spec templates).

### Optional browser tester

Only if the developer chose option 2 in `questions.md` §18, copy and adapt `agents/optional/browser-tester.md` to `.claude/agents/browser-tester.md`. The Playwright MCP stays declared inline in the agent's frontmatter — do not add it to `.mcp.json` (see `mcps/playwright-policy.md`). Vendor that policy to `.claude/reference/playwright-policy.md` and rewrite the agent's link to it per "Referenced policy files" below. Verify the frontmatter `mcpServers` syntax and the Playwright launch command against the installed Claude Code version before finalizing the file. For option 3, record the setup reference in the project's docs without configuring anything.

### Skill

Copy and adapt the full `skills/sdd-workflow/` directory into:

```text
.claude/skills/sdd-workflow/
```

This skill contains the full multi-step SDD procedure. Keep `CLAUDE.md` short and use the skill for operational detail.

### Optional skill packs

The core `sdd-workflow` skill is always installed. The packs under `skills/optional/` are installed only when the developer selects them (see `questions.md` §14).

- For each selected pack, copy `skills/optional/<name>/` to `.claude/skills/<name>/` and adapt placeholders and project-specific details (commands, paths, doc locations). If the pack links a kit policy (`reference/*.md` or `mcps/playwright-policy.md`), vendor it and rewrite the link per "Referenced policy files" below. Exception: `run-and-verify` is generated from a template, not copied — see "Run and verify skill" below.
- If `failure-learning` is selected, also copy `templates/memory/failure-learning-entry.md` to `.claude/skills/failure-learning/entry-template.md` (the skill references it), keeping its placeholder tokens — entries are instantiated per lesson, not during onboarding. Memory scope rules come from `reference/memory-policy.md`: project memory by default, never a global write without explicit approval.
- If `git-discipline` is selected, also copy `templates/git/` (commit-message, PR-description, and release-note templates) to `.claude/skills/git-discipline/templates/`, adapt them to the `questions.md` §8 git-policy answers (commit convention, task-reference format, changelog categories), and delete the generator-notes comments from the adapted copies.
- If `decision-log` is selected, also create the decision files the developer chose in `questions.md` §17 from the kit's templates: `decisions/architecture-decisions.template.md`, `decisions/rejected-options.template.md`, `decisions/workflow-decisions.template.md` → `decisions/<name>.md`. If the project already uses `docs/adr/`, architecture decisions stay there in the project's existing format — do not create a competing file. Record the chosen locations in `decisions/answers.md` and adapt the installed skill to them.
- If the repository clearly indicates applicability (e.g. a frontend for `ui-qa` and `spec-from-screenshot`), suggest the pack — but install only on confirmation.
- Record installed and declined packs in `decisions/answers.md`.
- In `CLAUDE.md`, list installed optional skills by name with a one-line purpose at most. Never paste skill bodies into `CLAUDE.md`: skill content loads only when invoked, which is what keeps it cheap.

### Run and verify skill

If the developer selected the `run-and-verify` pack (`questions.md` §14), generate `.claude/skills/run-and-verify/SKILL.md` from `templates/run-and-verify.md.template` instead of copying the pack file verbatim.

- Fill the placeholders from the Phase 1 inspection first (`package.json` scripts, `Makefile`, CI config, existing docs), confirm inferred commands with the developer, and ask the `questions.md` §15 questions only for what remains unknown.
- Reuse the §7 answers for test/lint/typecheck commands — do not re-ask.
- Record any command that cannot be confirmed as `TODO: ask the developer`. Never invent a command.
- Record required environment variables by name only. Never write secret values, tokens, or credentials into the generated skill or any other file.
- The generated skill is the project's run/verify recipe: implementer and reviewer run applicable checks through it (see `agents/implementer.md`, `agents/reviewer.md`, and the review checklist).

### Spec templates and renderer

Copy the markdown spec templates and rendering assets into the target project so the spec-author has a source when creating new feature specs after the kit is removed:

```text
templates/specs/requirements.md.template      → .claude/skills/sdd-workflow/templates/requirements.md.template
templates/specs/design.md.template            → .claude/skills/sdd-workflow/templates/design.md.template
templates/specs/tasks.md.template             → .claude/skills/sdd-workflow/templates/tasks.md.template
templates/specs/review.md.template            → .claude/skills/sdd-workflow/templates/review.md.template
templates/specs/acceptance-tests.md.template  → .claude/skills/sdd-workflow/templates/acceptance-tests.md.template
templates/specs/assumptions.md.template       → .claude/skills/sdd-workflow/templates/assumptions.md.template
templates/specs/open-questions.md.template    → .claude/skills/sdd-workflow/templates/open-questions.md.template
templates/specs/spec-shell.html.template      → .claude/skills/sdd-workflow/templates/spec-shell.html.template
templates/specs/spec.css                      → .claude/skills/sdd-workflow/templates/spec.css
templates/specs/spec.js                       → .claude/skills/sdd-workflow/templates/spec.js
```

Copy these verbatim, including the `{{PLACEHOLDER}}` tokens. The `.md.template` files are instantiated per feature, not during onboarding; `spec-shell.html.template`, `spec.css`, and `spec.js` are consumed by the renderer.

Install exactly one renderer, matching the runtime detected in Phase 1 (ask if ambiguous):

```text
scripts/render-spec.mjs   → scripts/render-spec.mjs    # Node projects
scripts/render_spec.py    → scripts/render_spec.py     # Python projects
```

Markdown is the source of truth; rendered HTML is a build artifact. Add the rendered artifacts to the target project's `.gitignore`:

```gitignore
# SDD rendered artifacts (markdown is the source of truth)
specs/**/*.html
history.html
```

If architecture/conventions docs are generated at a different location (e.g. `docs/architecture.md`), gitignore their rendered `.html` siblings too. If the developer explicitly prefers committing rendered HTML, record that decision in `decisions/answers.md` and skip the gitignore entries.

Do NOT copy the kit's `specs/example-feature/` directory into the target project. It is a rendered reference example for humans and agents, not part of the installed harness.

### Referenced policy files (vendoring)

Several installed agents, skills, and templates link to policy files that live in the kit (`reference/*.md`, `mcps/playwright-policy.md`). Those paths resolve only while the kit is present — once `sdd-onboarding-kit/` is removed, every such link dangles and the installed harness is no longer self-contained.

Make the harness self-contained: for each policy referenced by a component you actually install, copy the policy file into `.claude/reference/`, then rewrite the reference in the installed component to point at `.claude/reference/<file>` (dropping any "in the kit" phrasing). Vendor only the policies whose referencing component is installed — do not copy the whole `reference/` directory.

| Vendor to `.claude/reference/` | Source | Required when you install |
| --- | --- | --- |
| `deep-review-policy.md` | `reference/deep-review-policy.md` | always (referenced by `reviewer.md`, `spec-author.md`, `review-checklist.md`, and the `design`/`review` spec templates) |
| `context-economy.md` | `reference/context-economy.md` | the `context-audit` pack |
| `memory-policy.md` | `reference/memory-policy.md` | the `decision-log` or `failure-learning` pack, or any vendored `workflow-decisions` file |
| `dependency-freshness-policy.md` | `reference/dependency-freshness-policy.md` | the `dependency-freshness` pack |
| `autonomy-policy.md` | `reference/autonomy-policy.md` | the `git-discipline` pack |
| `playwright-policy.md` | `mcps/playwright-policy.md` | the `ui-qa` pack or the `browser-tester` agent |

The `design`/`review` spec templates already carry the rewritten `.claude/reference/deep-review-policy.md` path, so copying them verbatim (per "Spec templates" above) is correct — you only need to ensure `deep-review-policy.md` is vendored. For agents and skills, rewrite the link as part of the "copy and adapt" step.

The onboarding-time reading material (`reference/sdd-theory.md`, `harness-engineering.md`, `claude-code-primitives.md`, `cli-vs-mcp-policy.md`, `session-recovery.md`) is not linked by any installed component and does not need vendoring; it is read during onboarding only.

### Update mechanism (always installed)

The kit is versioned (`VERSION`, `CHANGELOG.md`, git tags). Every install gets the self-update skill and an install manifest so the harness can be updated when the kit publishes a new version:

1. Copy `skills/sdd-update/SKILL.md` to `.claude/skills/sdd-update/SKILL.md`, filling its `{{KIT_REPO_URL}}` placeholder with the kit's git URL (ask the developer if unknown; recording a local path instead is acceptable).
2. As the **last** generation step (after every other file is written), create `.claude/sdd-kit-manifest.json` following `templates/sdd-kit-manifest.schema.md`: kit version, install date, and one record per installed file with its kit source path, the SHA-256 of the kit source, the installed path, the SHA-256 of the installed copy, and `adapted: true|false` (`false` only for files copied byte-for-byte). This manifest is what lets `/sdd-update` distinguish verbatim assets from adapted files and detect local edits.

### Onboarding decisions record

Create `decisions/answers.md` in the target project from `decisions/answers.template.md`, filled with the developer's answers to the onboarding questions. Workflow-level assumptions and onboarding decisions are recorded there.

If the `decision-log` pack was selected, the additional decision files are created alongside it — see "Optional skill packs" above.

### Test and lint scripts

Generate `scripts/run-tests.sh` and `scripts/run-lint.sh` from `scripts/run-tests.sh.template` and `scripts/run-lint.sh.template`, filling `{{TEST_COMMAND}}` / `{{LINT_COMMAND}}` from the §7 command answers.

- These scripts carry no-op guards: they exit 0 cleanly when the command is empty, a `TODO: ...` string, or an unreplaced placeholder, and when the named toolchain binary is not on `PATH`. This keeps them safe to wire into hooks before the toolchain or sources exist.
- On a greenfield/plan-only repo, leave the command empty or as `TODO: ask the developer` rather than inventing one — the guard handles it (see "Greenfield and plan-only repositories"). Never invent a command.
- Because the no-op state relies on these placeholders, an unresolved `{{TEST_COMMAND}}`/`{{LINT_COMMAND}}` left in these two scripts is acceptable and is not a Phase 5 placeholder failure.

### Hooks

Do not enable hooks silently.

Hook scripts and the scripts under `scripts/` are bash and most rely on `jq`. On Windows they require Git Bash (or WSL) plus `jq` on `PATH`; the example hooks fail open (warn and allow) when `jq` is missing. Confirm with the developer that the team's environment provides bash and `jq` before enabling any hook (see `questions.md` §9).

For structure validation specifically, a PowerShell port (`scripts/validate-sdd-structure.ps1`) needs neither bash nor `jq` and runs the full check — including `tasks.json` state-machine validation, which the bash version skips when `jq` is absent. Install it for Windows-primary teams (it can sit alongside the `.sh`) so validation is not quietly weakened. It is structure validation only; it does not replace the bash hook scripts.

Do not enable tool-running hooks (such as `run-tests-after-edit`) before the toolchain and sources exist. On a greenfield or plan-only repo they fire on every edit with nothing meaningful to run — install them disabled and tell the developer to enable them once there is code and a confirmed command.

If the developer approves hooks, create `.claude/settings.json` entries from `hooks/settings-snippets.md` and copy any required hook scripts into `scripts/` or `.claude/hooks/`.

Prefer hooks for deterministic constraints such as:

- blocking implementation before spec approval;
- running validation after edits;
- preventing dangerous shell commands;
- validating task state transitions.

### MCPs

Do not configure MCPs silently.

If the developer chooses MCPs, use `mcps/mcp-policy.md` and the relevant integration notes.

If no MCPs are selected, use local markdown/JSON storage:

- `tasks.json`
- `specs/<feature>/`
- `history.md`

## Phase 5 — Validate installation

After writing files:

1. Run `scripts/validate-sdd-structure.sh` if safe (or `scripts/validate-sdd-structure.ps1` on Windows-primary teams without bash/`jq`).
2. Run `scripts/init.sh` if safe.
3. Run the configured test command if the developer approved running tests.
4. Verify all generated files have no unresolved placeholders (Markdown and HTML). Exceptions: (a) per-instance template files (`*.template` under any `templates/` directory) keep their `{{PLACEHOLDER}}` tokens by design — this covers the spec templates under `.claude/skills/sdd-workflow/templates/` and the git templates under `.claude/skills/git-discipline/templates/` (`validate-sdd-structure.sh` applies the same exemption); (b) `scripts/run-tests.sh`/`run-lint.sh` may keep an unresolved `{{TEST_COMMAND}}`/`{{LINT_COMMAND}}` on a greenfield repo where the command is intentionally unknown — the no-op guard treats that as "skip cleanly" (see "Test and lint scripts").
5. Verify the project `CLAUDE.md` points to `.claude/skills/sdd-workflow/SKILL.md`.
6. Verify that task statuses in `tasks.json` match the configured state machine.
7. Verify the project map exists at the configured location and is linked from `CLAUDE.md`, or that a TODO records that generation was deferred.
8. If the `run-and-verify` pack was selected, verify `.claude/skills/run-and-verify/SKILL.md` has no unresolved placeholders (unknown commands appear as explicit `TODO: ask the developer` entries), no invented commands, and no secret values — environment variables by name only.
9. Verify the installed harness is self-contained: no installed file links a kit-relative policy path. Grep `CLAUDE.md`, `.claude/`, and `specs/` for `reference/` or `mcps/playwright-policy.md` references that are not prefixed with `.claude/` — every such link must resolve to a file vendored under `.claude/reference/` (see "Referenced policy files"). The harness must not depend on `sdd-onboarding-kit/` remaining in the repository.
10. Verify the renderer works: run the installed renderer against a template-instantiated sample (or the first real spec) and confirm it produces HTML without errors; confirm the rendered-artifact `.gitignore` entries exist (unless the developer chose to commit rendered HTML).
11. Verify `.claude/sdd-kit-manifest.json` exists, parses as JSON, records the kit version, and covers the installed files; verify `.claude/skills/sdd-update/SKILL.md` exists with no unresolved placeholders.

## Phase 6 — Final onboarding summary

At the end, report:

- files created;
- files modified;
- hooks enabled or left disabled;
- MCPs configured or left unconfigured;
- project-specific commands detected;
- open TODOs;
- the first command/prompt the developer should use to start an SDD task.

## Explicit non-goals

During onboarding, do not:

- implement a product feature;
- refactor the codebase;
- invent missing business requirements;
- enable external integrations without approval;
- run destructive commands;
- commit changes unless the developer explicitly asked for commits.

## Functional document intake

If the developer provides a functional document, treat it as source material, not as an approved spec.

Convert it into an SDD spec before implementation.

Never implement directly from a functional document unless the developer explicitly disables SDD for that task.

If the developer provides a functional document, product brief, ticket, PRD, user story, or informal feature description, read:

1. `skills/sdd-workflow/intake-from-functional-doc.md`
2. `skills/sdd-workflow/assumptions-policy.md`
3. `skills/sdd-workflow/open-questions-policy.md`
4. `templates/functional/functional-brief.md.template`
5. `templates/specs/assumptions.md.template`
6. `templates/specs/open-questions.md.template`
7. `templates/specs/acceptance-tests.md.template`

Claude Code must treat the functional document as source material, not as an approved implementation spec.

Claude Code must generate or update the SDD spec before implementation.