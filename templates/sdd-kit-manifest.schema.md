# `<harness-dir>/sdd-kit-manifest.json` — install manifest schema

Written by onboarding as the **last** generation step, and rewritten by the `sdd-update` skill after every update. It lives in the primary harness directory (`.claude/` for Claude Code, `.cursor/`, `.opencode/`, `.agents/`, or `.codex/` for Codex). It records which kit version the harness came from, which harness(es) it was installed for, and, per installed file, enough to detect both kit-side changes and local edits.

```json
{
  "kit": "sdd-onboarding-kit",
  "kit_version": "2.1.0",
  "kit_source": "<git URL or local path the kit was installed from>",
  "installed_at": "YYYY-MM-DD",
  "updated_at": "YYYY-MM-DD",
  "harness": {
    "primary": "claude-code",
    "dir": ".claude",
    "instruction_files": ["AGENTS.md", "CLAUDE.md"],
    "additional": [
      { "name": "codex", "dirs": [".codex", ".agents"] }
    ]
  },
  "files": [
    {
      "installed_path": ".claude/skills/sdd-workflow/templates/spec.css",
      "kit_path": "templates/specs/spec.css",
      "kit_sha256": "<sha256 of the kit source file at install time>",
      "installed_sha256": "<sha256 of the installed copy as written>",
      "adapted": false
    },
    {
      "installed_path": "AGENTS.md",
      "kit_path": "templates/AGENTS.md.template",
      "kit_sha256": "…",
      "installed_sha256": "…",
      "adapted": true
    },
    {
      "installed_path": ".codex/agents/reviewer.toml",
      "kit_path": "agents/reviewer.md",
      "kit_sha256": "…",
      "installed_sha256": "…",
      "adapted": true
    }
  ]
}
```

Field rules:

- `harness.primary` — one of `claude-code`, `codex`, `cursor`, `opencode`, `antigravity`, or a free-form name for another harness; `harness.dir` is `<harness-dir>`; `harness.instruction_files` lists the generated instruction files (`AGENTS.md`, plus `CLAUDE.md` when Claude Code is used); `harness.additional` lists every other harness installed for, with its directories. The `sdd-update` skill uses this block to find every copy to refresh. A manifest without the block (installs before 2.1.0) means `claude-code` / `.claude`.

- `adapted: false` — the file was copied byte-for-byte from the kit (`kit_sha256 == installed_sha256`). The `sdd-update` skill may refresh it mechanically **iff** its current hash still equals `installed_sha256`; otherwise the developer edited it locally and must be asked.
- `adapted: true` — the file was generated or adapted for the project (placeholders filled, content merged, or converted to the harness's agent format such as Codex TOML). The `sdd-update` skill never overwrites it mechanically; changes are merged with developer approval, guided by the changelog.
- Hashes are lowercase hex SHA-256 of file bytes (`git hash-object` is NOT used; use `sha256sum` / `Get-FileHash -Algorithm SHA256` / `shasum -a 256`).
- Every file the onboarding created or modified for the harness gets a record — including `AGENTS.md` (and the `CLAUDE.md` stub), agents, skills, templates, renderer, validation scripts, vendored `<harness-dir>/reference/*` policies, hook scripts and wiring files, in every harness directory. Project files untouched by onboarding are never listed.
- `files[].kit_path` uses the kit's repo-relative path at `kit_version`. When a file has no kit source (e.g. a generated `decisions/answers.md`), set `kit_path: null` and `kit_sha256: null` with `adapted: true`.
