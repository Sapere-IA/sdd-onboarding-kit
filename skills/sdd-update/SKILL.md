---
name: sdd-update
description: Update this project's SDD harness from the sdd-onboarding-kit. Use when the developer asks to update SDD, sync the harness with the kit, or apply a new kit version.
---

# SDD harness update skill

Bring this project's installed SDD harness up to date with the latest published version of the `sdd-onboarding-kit`, preserving every project-specific adaptation.

Kit source: `{{KIT_REPO_URL}}`

## Safety rules (read first)

- Touch only harness files: `CLAUDE.md` (SDD sections only), `.claude/`, `scripts/` harness scripts, spec templates, hooks installed by onboarding, and `specs/` only for format migrations. Never touch product code.
- Every migration step and every adapted-file merge requires developer approval before it is applied. Mechanical refreshes of unmodified verbatim assets may be batched under a single approval.
- Never delete or overwrite a locally edited file without showing the developer what would be lost.
- Work on a clean git state: if the repo has uncommitted changes to harness files, ask the developer to commit or stash first, so the update is a reviewable diff.
- Clean up the temporary kit clone when done.

## Procedure

### 1. Read the local manifest

Read `.claude/sdd-kit-manifest.json`. It records `kit_version` and, per installed file, its kit source path, hashes, and `adapted` flag.

**If the manifest is missing** (install predates the manifest), enter bootstrap mode:

1. Fetch the kit (step 2) first.
2. Reconstruct the file list by matching installed harness files against the kit's layout (`.claude/agents/*`, `.claude/skills/sdd-workflow/*`, templates, scripts, vendored `.claude/reference/*`).
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
2. Apply only those changes to the installed file, preserving the project adaptations (commands, paths, policies recorded in `decisions/answers.md`).
3. Show the resulting diff and get approval per file (related files may be grouped).

### 6. Run migrations

Execute the changelog **Migration** steps for each version being crossed, in order, each with approval. Never run a destructive step (deleting files, `git rm`) without showing exactly what it removes.

### 7. Rewrite the manifest and report

- Rewrite `.claude/sdd-kit-manifest.json`: new `kit_version`, `updated_at`, fresh hashes for every touched file; add records for newly installed files.
- Run `scripts/validate-sdd-structure.sh` (or `.ps1`) if present.
- Delete the temporary clone.
- Report: previous → new version, files refreshed mechanically, files merged, files skipped (locally edited, developer declined), migration steps run, and anything left for the developer.
