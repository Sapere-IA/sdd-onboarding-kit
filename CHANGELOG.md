# Changelog

Kit versions are tracked in `VERSION` and tagged in git (`v<version>`). Each entry lists **Changes** (what is different in the kit) and **Migration** (what `/sdd-update` must do to bring an existing install up to date). The `sdd-update` skill reads the entries between the installed version and the latest, and executes the migration steps with developer approval.

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
