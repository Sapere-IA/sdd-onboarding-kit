# Changelog

Kit versions are tracked in `VERSION` and tagged in git (`v<version>`). Each entry lists **Changes** (what is different in the kit) and **Migration** (what `/sdd-update` must do to bring an existing install up to date). The `sdd-update` skill reads the entries between the installed version and the latest, and executes the migration steps with developer approval.

## 3.0.0 — 2026-10-06

### Changes

- **One interactive page per spec.** `scripts/render-spec.sh specs/<feature-slug>/` writes a single `spec.html`. It opens on an overview: "At a glance" (the requirements summary), counts, and "Needs your decision" (open questions and pending assumptions). Each document has its own tab, `##` sections collapse, and empty `None.` sections shrink to one line. ID chips link to their definitions, and the page prints cleanly. The 2.x per-document `.html` pages are gone.
- **Review in the page, hand back a file.** Every item with an ID (requirement rows, `Q`/`A`/`AT` cards, timeline tasks) gets Accept / Change / Reject / Answer / Comment controls. The developer approves the spec or requests changes, can add a general note, and then saves `feedback.md` (a save dialog, or a `<feature-slug>.feedback.md` download) or copies it into the chat. The agent applies it to the markdown, re-renders and deletes the file (`spec-format.md` § Feedback file). An approving feedback file with no change or reject items counts as the developer's approval. In-progress feedback is kept in the browser's localStorage.
- **No Node or Python needed.** `render-spec.mjs` and `render_spec.py` are removed. The markdown is embedded verbatim and rendered in the browser by `spec.js`. The bundler is POSIX `sh` (`scripts/render-spec.sh`), with a PowerShell port for Windows (`scripts/render-spec.ps1`). The renderer-runtime onboarding question is gone. The markdown conventions are unchanged, so 2.x specs render as they are.
- **New design.** The Sapere IA palette (paper / ink / lime / coral; Instrument Sans + JetBrains Mono). Light by default; it follows the OS dark mode and has a toggle. It works at phone width. `README.html` and `DOCUMENTATION.html` use the same design and are shorter.
- **Concise specs.** `spec-format.md` sets budgets: a Summary of at most 3 sentences, one sentence per item, a design section that fits on one screen, about 8 tasks or fewer, and a whole spec readable in about 5 minutes. The spec templates went from roughly 1,000 to roughly 300 lines: sections were merged, rarely used ones are optional, and coverage matrices and checklists that duplicated other files were removed. Acceptance-test cards use Requirements / Given / When / Then. `review.md` starts with its Decision.
- **New core skills.** `bro` re-explains your previous message, or a given text, file, spec ID or term, in plain language and in at most about 150 words. `closing` is an end-of-session audit: it checks that tasks, specs, decisions, history and memory match what happened, writes a `## Resume here` handoff in `history.md`, runs a cold-start test, and asks before committing.

### Migration (from 2.x)

Run with developer approval, per step (`sdd-update` § 2.x → 3.0.0 has the details).

1. Remove `scripts/render-spec.mjs` / `scripts/render_spec.py`. Install `scripts/render-spec.sh` and `scripts/render-spec.ps1`.
2. Refresh `<harness-dir>/skills/sdd-workflow/templates/` (`spec-shell.html.template`, `spec.css`, `spec.js`, and the trimmed `*.md.template` files), plus `spec-format.md`, `workflow.md`, `review-checklist.md`, `task-state-machine.md`, `SKILL.md` and the agents. Preserve project adaptations. The new renderer refuses a pre-3.0 shell template.
3. Delete the per-document rendered `.html` files under `specs/` and re-render each spec folder into `spec.html`.
4. Add `specs/**/feedback.md` to `.gitignore`.
5. Install the `bro` and `closing` skills into every harness directory.
6. Update `AGENTS.md`: the render command (`sh scripts/render-spec.sh specs/<feature-slug>/`), the feedback flow line, and the "Session skills" section.
7. Existing specs need no rewrite. Apply the new budgets the next time a spec is revised.

## 2.1.0 — 2026-09-27

### Changes

- **Multi-harness support.** The kit installs the same SDD harness under Claude Code, OpenAI Codex CLI, Cursor, OpenCode and Google Antigravity (and, with documented fallbacks, any other coding-agent harness). The Claude Code layout (`.claude/`) stays the kit's *reference layout*; `reference/harness-primitives.md` (renamed from `claude-code-primitives.md`) maps every concept — instruction file, skills, subagents, hooks, MCP config, invocation, compaction — to each harness, with fallbacks when a harness lacks one (roles played by the main conversation, skills read on demand, hooks instruction-only). `questions.md` §0 records the harness(es); `instructions.md`, `output-project-structure.md` and the validators speak in terms of `<harness-dir>`.
- **`AGENTS.md` is the canonical project instruction file.** `templates/CLAUDE.md.template` became `templates/AGENTS.md.template` (harness-neutral wording, new placeholders `{{HARNESS_DIR}}`, `{{SKILL_INVOCATION}}`, `{{CONTEXT_COMMANDS}}`, `{{HARNESS_NOTES}}`); a new two-line `templates/CLAUDE.md.template` (`@AGENTS.md` import) is generated only when Claude Code is one of the harnesses. The kit's own root has the same pair.
- **Harness-neutral hook scripts.** Every example hook starts with an identical adapter block that reads the payloads of Claude Code, Codex, Cursor and Antigravity (or explicit `SDD_HOOK_*` variables / a path argument) and emits block/advisory output per `SDD_HOOK_OUTPUT` (`exit`, `cursor`, `antigravity`, `plain`). `hooks/hooks-policy.md` documents the contract; `hooks/settings-snippets.md` carries wiring for `.claude/settings.json`, `.codex/hooks.json`, `.cursor/hooks.json`, `.agents/hooks.json` and an OpenCode plugin. Spec/harness allowlists in the guards now cover every harness directory and `AGENTS.md`.
- **Validators and scripts.** `validate-sdd-structure.sh`/`.ps1` and `init.sh` take `SDD_HARNESS_DIR` (default `.claude`), `SDD_SKILLS_DIR` (Codex: `.agents/skills`) and `SDD_PROJECT_DIR`; they accept `AGENTS.md` (or a legacy `CLAUDE.md`), require `CLAUDE.md` to be the import stub when both exist, and accept Codex `.toml` agents.
- **Manifest and update skill.** `sdd-kit-manifest.json` gains a `harness` block (primary harness, directory, instruction files, additional harness directories); `sdd-update` refreshes every harness directory listed there and treats a manifest without the block as a Claude Code install.
- **Wording pass.** Agents, skills, templates, policies and MCP notes no longer assume Claude Code: "Claude" → "the agent", `CLAUDE.md` → `AGENTS.md`, `.claude/...` paths → the harness directory or "this skill's folder"; harness-specific commands appear only in per-harness tables (`reference/context-economy.md`, `reference/memory-policy.md`, `reference/session-recovery.md`, `reference/autonomy-policy.md`).

### Migration (for installs made before 2.1.0)

Run with developer approval, per step. Existing Claude Code installs keep working unchanged; these steps are what make the install shareable with other harnesses.

1. **Create `AGENTS.md` from `CLAUDE.md`**: move the whole content of the project `CLAUDE.md` into `AGENTS.md`, apply the template's wording changes (`templates/AGENTS.md.template`: "Roles (subagents)" section, harness-neutral skill invocation, "Harness updates" pointing at the `sdd-update` skill), then replace `CLAUDE.md` with the two-line stub from `templates/CLAUDE.md.template` (`@AGENTS.md`). Claude Code deduplicates the import, so nothing loads twice.
2. **Refresh the hook scripts** installed by onboarding from `hooks/examples/` (the adapter block is new; project logic below it is unchanged apart from the harness-directory allowlists). Existing `.claude/settings.json` wiring keeps working: the default output mode is Claude Code's.
3. **Refresh the validators**: overwrite `scripts/validate-sdd-structure.sh` / `.ps1` and `scripts/init.sh` from the kit.
4. **Refresh the skills and agents** (wording only): update `<harness-dir>/skills/sdd-workflow/*`, installed optional packs, `sdd-update`, and the agents from the kit, preserving project adaptations; rewrite any `.claude/skills/...` path inside them to the harness-relative form the kit now uses.
5. **Vendored policies**: if `context-economy.md`, `memory-policy.md`, `autonomy-policy.md` or `deep-review-policy.md` were vendored under `<harness-dir>/reference/`, refresh them from the kit.
6. **Add the `harness` block to the manifest**: `{"primary": "claude-code", "dir": ".claude", "instruction_files": ["AGENTS.md", "CLAUDE.md"], "additional": []}` for an existing Claude Code install; record the answer to `questions.md` §0 in `decisions/answers.md` (new "Harness" section from `decisions/answers.template.md`).
7. **Optional — add another harness**: run the onboarding's Phase 4 for that harness only (skills and agents copied into its directory in its format, hook wiring, MCP config), add it to the manifest's `harness.additional`, and note it in `decisions/answers.md`. `AGENTS.md`, specs, tasks, history, decisions and scripts are shared as-is.

## 2.0.1 — 2026-07-22

### Changes

- **Renderer: dotted and hyphenated task/spec IDs render as chips.** `ID_TOKEN`, `REQ_ROW`, the timeline-chip matcher and the chip-variant map in both renderers now accept IDs with a hyphen after the letter prefix and dotted numeric segments (`T-4.35.12`, `SPEC-4.35`), which previously rendered as plain text. Both renderers remain output-equivalent.

### Migration (for installs made before 2.0.1)

1. **Re-copy the renderer**: overwrite `scripts/render-spec.mjs` (or `scripts/render_spec.py`) from the kit. No other file changed.

## 2.0.0 — 2026-07-22

### Changes

- **Markdown-source specs.** All LLM-written documents (per-feature specs, `history`, `architecture`, `conventions`, functional briefs) are now markdown with YAML frontmatter — the single source of truth. Styled HTML is a rendered, gitignored artifact produced by a zero-dependency renderer (`scripts/render-spec.mjs` for Node projects or `scripts/render_spec.py` for Python projects, feature-identical). Conventions (requirement rows, verdict markers, task status markers, cards): `skills/sdd-workflow/spec-format.md`. The old `.html.template` spec templates are gone; templates are `.md.template` plus rendering assets (`spec-shell.html.template`, `spec.css`, `spec.js`). `spec.css`/`spec.js` are no longer copied into feature folders — the renderer inlines them.
- **Conciseness and no-duplication policy.** Each spec file owns one content type; everything else references by ID. Duplicated or padded content is a review finding (review checklist §1b). Templates were slimmed accordingly.
- **Self-update mechanism.** The kit is versioned (`VERSION`, git tags, this changelog). Onboarding always installs `.claude/skills/sdd-update/SKILL.md` and writes `.claude/sdd-kit-manifest.json` (kit version + per-file source/installed hashes + adapted flag) as the last generation step.

### Migration (for installs made before 2.0.0)

Run with developer approval, per step:

1. **Install the renderer**: copy `scripts/render-spec.mjs` (Node projects) or `scripts/render_spec.py` (Python projects) into `scripts/`; ask which if ambiguous.
2. **Refresh the sdd-workflow skill**: update `spec-format.md`, `workflow.md`, `review-checklist.md`, `examples.md`, `assumptions-policy.md`, `open-questions-policy.md` and the agents (`spec-author`, `implementer`, `reviewer`) from the kit, preserving project-specific adaptations (commands, paths, policies from `decisions/answers.md`).
3. **Replace the spec templates**: delete `.claude/skills/sdd-workflow/templates/*.html.template`; install the `.md.template` set plus `spec-shell.html.template`; keep `spec.css`/`spec.js` (take the kit's updated `spec.css` — it adds `td.pending`).
4. **Convert existing spec HTML to markdown**: for each `specs/<slug>/*.html` (and `history.html`, plus generated `architecture`/`conventions` docs), rewrite the content as the equivalent `.md` per `spec-format.md` — frontmatter from the header meta-table, requirement rows from `.req-row` divs, timeline items from `.task-item` elements (status class → `[x]`/`[>]`/`[!]`), verdict cells from `td` classes, cards from `.card` divs. While converting, apply the conciseness policy: collapse non-applicable boilerplate sections to one line and replace restated content with ID references. Then delete the old HTML, render the new markdown, and have the developer spot-check one rendered spec before deleting the rest.
5. **Gitignore rendered artifacts**: add `specs/**/*.html` and `history.html` (plus rendered architecture/conventions siblings) to `.gitignore`; `git rm --cached` any previously committed rendered HTML.
6. **Update `CLAUDE.md`** references: spec file names to `.md`, `history.html` → `history.md`, add the render command and the `/sdd-update` mention.
7. **Update hooks** if installed: refresh `block-implementation-before-approval.sh`, `validate-spec-before-status-change.sh`, `spec-drift.sh`, and `validate-sdd-structure.sh`/`.ps1` from the kit (they now check `.md` spec files).
8. **Write the manifest**: create `.claude/sdd-kit-manifest.json` per `templates/sdd-kit-manifest.schema.md` reflecting the updated install.
