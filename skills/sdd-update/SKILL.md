---
name: sdd-update
description: Update this project's SDD harness from the sdd-onboarding-kit. Use when the developer asks to update SDD, sync the harness with the kit, or apply a new kit version.
---

# SDD harness update skill

Bring this project's installed SDD harness up to date with the latest published version of the `sdd-onboarding-kit`, preserving every project-specific adaptation.

Kit source: `{{KIT_REPO_URL}}`

## Safety rules (read first)

- Touch only harness files: `AGENTS.md` (SDD sections only) and the `CLAUDE.md` stub, every harness directory listed in the manifest's `harness` block (`.claude/`, `.codex/`, `.cursor/`, `.opencode/`, `.agents/`), `scripts/` harness scripts, spec templates, hooks installed by onboarding, and `specs/` only for format migrations. Never touch product code.
- Every migration step and every adapted-file merge requires developer approval before it is applied. Mechanical refreshes of unmodified verbatim assets may be batched under a single approval.
- Never delete or overwrite a locally edited file without showing the developer what would be lost.
- Work on a clean git state: if the repo has uncommitted changes to harness files, ask the developer to commit or stash first, so the update is a reviewable diff.
- Clean up the temporary kit clone when done.

## Procedure

### 1. Read the local manifest

Read `<harness-dir>/sdd-kit-manifest.json` (look in `.claude/`, `.codex/`, `.cursor/`, `.opencode/`, `.agents/`). It records `kit_version`, the `harness` block (primary harness and directory, instruction files, additional harness directories), and, per installed file, its kit source path, hashes, and `adapted` flag. A manifest without a `harness` block is a pre-2.1.0 Claude Code install (`.claude/`, `CLAUDE.md`).

**If the manifest is missing** (install predates the manifest), enter bootstrap mode:

1. Fetch the kit (step 2) first.
2. Detect the harness directories present, then reconstruct the file list by matching installed harness files against the kit's reference layout (`<harness-dir>/agents/*`, `<harness-dir>/skills/sdd-workflow/*`, templates, scripts, vendored `<harness-dir>/reference/*`). Files in a non-Claude agent format (Codex `.toml`, adapted frontmatter) are `adapted: true`.
3. A file byte-identical to some kit version's source is verbatim; anything else is `adapted: true`.
4. Treat the installed version as unknown: apply every changelog entry's migration whose changes are not already present (verify, don't assume), and flag uncertainty to the developer instead of guessing.

### 2. Fetch the kit

```bash
git clone --depth 1 {{KIT_REPO_URL}} <tmp-dir>
```

If the developer keeps a local checkout, use that path instead (read-only). Read the kit's `VERSION` and `CHANGELOG.md`.

### 3. Compare versions

- Installed `kit_version` == kit `VERSION`: report "already up to date" and stop.
- Otherwise, read every `CHANGELOG.md` entry newer than the installed version — these define both what changed and the migration steps.

### 4. Refresh verbatim assets

For each manifest record with `adapted: false` whose kit source changed:

- If the installed file's current SHA-256 still equals the manifest's `installed_sha256`: overwrite with the new kit version (mechanical; batch these under one approval).
- If not, the developer edited it locally: show the three-way situation (manifest version → local edits → new kit version) and ask.

### 5. Merge adapted files

For each `adapted: true` file whose kit source changed:

1. Diff the kit source between the installed and new versions to isolate what the kit actually changed.
2. Apply only those changes to the installed file, preserving the project adaptations (commands, paths, policies recorded in `decisions/answers.md`) and the harness packaging (agent frontmatter or Codex TOML, `<harness-dir>` paths). Apply the same change to every copy listed for additional harnesses.
3. Show the resulting diff and get approval per file (related files may be grouped).

### 6. Run migrations

Execute the changelog **Migration** steps for each version being crossed, in order, each with approval. Never run a destructive step (deleting files, `git rm`) without showing exactly what it removes.

#### 2.x → 3.0.0

The `CHANGELOG.md` entry stays authoritative; these are the steps it implies. Each step needs approval; apply every harness-directory step to each directory in the manifest's `harness` block.

1. **Renderer swap.** Show and remove `scripts/render-spec.mjs` and/or `scripts/render_spec.py` (and their manifest records). Install `scripts/render-spec.sh` and `scripts/render-spec.ps1` verbatim. Drop any renderer-runtime answer from `decisions/answers.md` (note it as superseded rather than deleting history).
2. **Spec assets and workflow.** Refresh `<harness-dir>/skills/sdd-workflow/templates/` (`spec-shell.html.template`, `spec.css`, `spec.js` and the trimmed `*.md.template` files), the `sdd-workflow` skill files and the agents from the kit (step 4 rules apply if they were edited locally). Existing specs keep rendering unchanged; they are not rewritten to the new templates.
3. **Stale rendered pages.** List the per-document `.html` files under `specs/` (one per markdown doc, from the 2.x renderer), delete them after approval, then re-render each spec folder with `sh scripts/render-spec.sh specs/<feature-slug>/` so each spec has a single `spec.html`. If the project commits rendered HTML (`decisions/answers.md`), tell the developer the deletions and new pages need committing; do not commit them yourself.
4. **Gitignore.** Add `specs/**/feedback.md` next to the existing SDD rendered-artifact entries in `.gitignore`.
5. **Session skills.** Install `skills/bro/SKILL.md` → `<harness-dir>/skills/bro/SKILL.md` and `skills/closing/SKILL.md` → `<harness-dir>/skills/closing/SKILL.md` (new verbatim records in the manifest).
6. **`AGENTS.md`.** In the spec-storage section, replace the old render command with `sh scripts/render-spec.sh specs/<feature-slug>/` (one page `specs/<feature-slug>/spec.html`) and add the one-line `feedback.md` flow; add the "Session skills" section (`bro`, `closing`) from the kit template. Merge as an adapted file (step 5 rules).
7. **Validate.** In step 7 below, the structure validator now also requires `scripts/render-spec.sh` and the `bro` and `closing` skills.

#### 3.0.0 → 3.1.0

No mandatory step. If `autonomy-policy.md` is vendored under `<harness-dir>/reference/`, refresh it. Install the `goblin-mode` pack only if the developer asks for it (`CHANGELOG.md` 3.1.0 Migration step 2).

### 7. Rewrite the manifest and report

- Rewrite `<harness-dir>/sdd-kit-manifest.json`: new `kit_version`, `updated_at`, the `harness` block, fresh hashes for every touched file; add records for newly installed files.
- Run `scripts/validate-sdd-structure.sh` (or `.ps1`) if present, with `SDD_HARNESS_DIR=<harness-dir>` when it is not `.claude`.
- Delete the temporary clone.
- Report: previous → new version, files refreshed mechanically, files merged, files skipped (locally edited, developer declined), migration steps run, and anything left for the developer.
