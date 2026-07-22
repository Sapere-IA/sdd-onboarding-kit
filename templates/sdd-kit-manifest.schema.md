# `.claude/sdd-kit-manifest.json` — install manifest schema

Written by onboarding as the **last** generation step, and rewritten by `/sdd-update` after every update. It records which kit version the harness came from and, per installed file, enough to detect both kit-side changes and local edits.

```json
{
  "kit": "sdd-onboarding-kit",
  "kit_version": "2.0.0",
  "kit_source": "<git URL or local path the kit was installed from>",
  "installed_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD",
  "files": [
    {
      "installed_path": ".claude/skills/sdd-workflow/templates/spec.css",
      "kit_path": "templates/specs/spec.css",
      "kit_sha256": "<sha256 of the kit source file at install time>",
      "installed_sha256": "<sha256 of the installed copy as written>",
      "adapted": false
    },
    {
      "installed_path": "CLAUDE.md",
      "kit_path": "templates/CLAUDE.md.template",
      "kit_sha256": "…",
      "installed_sha256": "…",
      "adapted": true
    }
  ]
}
```

Field rules:

- `adapted: false` — the file was copied byte-for-byte from the kit (`kit_sha256 == installed_sha256`). `/sdd-update` may refresh it mechanically **iff** its current hash still equals `installed_sha256`; otherwise the developer edited it locally and must be asked.
- `adapted: true` — the file was generated or adapted for the project (placeholders filled, content merged). `/sdd-update` never overwrites it mechanically; changes are merged with developer approval, guided by the changelog.
- Hashes are lowercase hex SHA-256 of file bytes (`git hash-object` is NOT used; use `sha256sum` / `Get-FileHash -Algorithm SHA256` / `shasum -a 256`).
- Every file the onboarding created or modified for the harness gets a record — including `CLAUDE.md`, agents, skills, templates, renderer, validation scripts, vendored `.claude/reference/*` policies, and hook scripts. Project files untouched by onboarding are never listed.
- `files[].kit_path` uses the kit's repo-relative path at `kit_version`. When a file has no kit source (e.g. a generated `decisions/answers.md`), set `kit_path: null` and `kit_sha256: null` with `adapted: true`.
