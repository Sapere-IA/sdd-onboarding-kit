# Expected project structure after onboarding

After the onboarding is complete, the target repository should contain a project-specific SDD harness.

`<harness-dir>` is the primary harness directory chosen in `questions.md` §0: `.claude/` for Claude Code, `.cursor/` for Cursor, `.opencode/` for OpenCode, `.agents/` for Antigravity; Codex CLI uses `.codex/` for agents, hooks and config and `.agents/` for skills. The mapping, per-harness file formats and fallbacks are in `reference/harness-primitives.md`. Additional harnesses get their own copies of `agents/` and `skills/` plus their own hook wiring and MCP config; everything outside `<harness-dir>` is shared.

## Minimal local-file setup

```text
<project>/
├── AGENTS.md                          # project instructions — read by every harness
├── CLAUDE.md                          # `@AGENTS.md` import stub — only when Claude Code is one of the harnesses
├── <harness-dir>/
│   ├── agents/                        # harness-native format: markdown frontmatter, or .toml for Codex
│   │   ├── leader
│   │   ├── spec-author
│   │   ├── implementer
│   │   ├── reviewer
│   │   ├── documenter
│   │   └── browser-tester             (only if questions.md §18 option 2)
│   ├── skills/                        # .agents/skills/ for Codex and Antigravity
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
│   │       └── SKILL.md
│   ├── context/
│   │   └── project-map.md
│   ├── reference/                     # vendored policies referenced by installed components
│   ├── hooks/
│   │   └── README.md
│   ├── <hook wiring, if enabled>      # settings.json (Claude Code), hooks.json (Codex, Cursor, Antigravity), plugins/ (OpenCode)
│   └── sdd-kit-manifest.json
├── <MCP config, if configured>        # .mcp.json / .codex/config.toml / .cursor/mcp.json / opencode.json / .agents/mcp_config.json
├── specs/
│   └── <feature-slug>/
│       ├── requirements.md
│       ├── design.md
│       ├── tasks.md
│       ├── assumptions.md
│       ├── open-questions.md
│       ├── acceptance-tests.md
│       └── review.md
│       (rendered *.html siblings are gitignored artifacts)
├── decisions/
│   ├── answers.md
│   ├── architecture-decisions.md   (decision-log pack; or docs/adr/ instead)
│   ├── rejected-options.md         (decision-log pack)
│   └── workflow-decisions.md       (decision-log pack)
├── tasks.json
├── history.md
└── scripts/
    ├── init.sh
    ├── run-tests.sh
    ├── run-lint.sh
    ├── render-spec.mjs            (OR render_spec.py — exactly one, per the detected runtime)
    └── validate-sdd-structure.sh
```

## Optional MCP-enabled setup

If the developer selects external task management or knowledge sources, the project may also contain:

```text
<project>/
├── <harness MCP config file>
├── docs/adr/
├── docs/architecture.md
└── docs/conventions.md
```

Local files should still exist unless the developer explicitly chooses a fully external tracker.

## Success criteria

The onboarding is complete when:

1. `AGENTS.md` exists and reflects this specific project, names the harness's skill invocation, and — when Claude Code is one of the harnesses — `CLAUDE.md` is the two-line import stub whose first line is `@AGENTS.md`.
2. The SDD skill exists under `<harness-dir>/skills/sdd-workflow/` (and under each additional harness's skills directory).
3. The markdown spec templates (plus `spec-shell.html.template`, `spec.css`, and `spec.js`) exist under `<harness-dir>/skills/sdd-workflow/templates/`, and exactly one renderer (`scripts/render-spec.mjs` or `scripts/render_spec.py`) is installed.
4. The five roles (leader, spec-author, implementer, reviewer, documenter) exist under `<harness-dir>/agents/` in the harness's agent format, or — for a harness without subagents — as role files with the fallback line recorded in `AGENTS.md`.
5. There is a task storage mechanism.
6. There is a spec storage mechanism.
7. `decisions/answers.md` records the developer's onboarding answers, including the harness section (§0).
8. There is a validation command or documented TODO.
9. Hooks are either explicitly enabled (with wiring in the harness's format) or explicitly left disabled, or recorded as unavailable in the harness.
10. MCPs are either explicitly configured (in the harness's config file) or explicitly left unconfigured.
11. No generated file contains unresolved placeholders without a TODO explaining why (the `.md.template` files and `spec-shell.html.template` under `<harness-dir>/skills/sdd-workflow/templates/` are exempt — their placeholders are instantiated per feature / by the renderer).
12. A project map exists at the configured location (default `<harness-dir>/context/project-map.md`) and is linked from `AGENTS.md`, or a documented TODO defers its generation.
13. Optional skill packs are either installed under `<harness-dir>/skills/<name>/` (listed by name in `AGENTS.md`) or explicitly declined in `decisions/answers.md`; no pack is installed without selection.
14. If the `run-and-verify` pack was selected, `<harness-dir>/skills/run-and-verify/SKILL.md` is project-specific: real commands or explicit `TODO: ask the developer` entries (never invented commands), environment variables by name only (no secret values), and UI/API verification steps for the reviewer to follow.
15. If the `decision-log` pack was selected, the decision files chosen during onboarding exist (`decisions/architecture-decisions.md`, `decisions/rejected-options.md`, `decisions/workflow-decisions.md` — or `docs/adr/` for architecture decisions), the installed skill references the chosen locations, and they are recorded in `decisions/answers.md`.
16. Browser testing matches the `questions.md` §18 answer: no Playwright anywhere (option 1), `<harness-dir>/agents/browser-tester` with the MCP scoped to the agent where the harness allows it and otherwise in the harness MCP config (option 2), or setup documented without configuration (option 3). No credentials appear in any generated file.
17. `<harness-dir>/skills/sdd-update/SKILL.md` is installed with the kit URL filled, and `<harness-dir>/sdd-kit-manifest.json` records the kit version, the `harness` block, and every installed file (in every harness directory) with hashes and adapted flags.
18. Rendered spec artifacts (`specs/**/*.html`, `history.html`, rendered architecture/conventions siblings) are gitignored, unless the developer explicitly chose to commit them (recorded in `decisions/answers.md`).
19. No installed file assumes a harness the project does not use: harness-specific commands and paths appear only in `AGENTS.md`'s harness placeholders, the hook wiring, and the MCP config.
