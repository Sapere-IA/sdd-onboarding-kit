# Instructions for coding agents working inside this kit

This repository is an SDD onboarding kit. It is not the target project configuration. These instructions apply to any coding agent (Claude Code, Codex, Cursor, OpenCode, Antigravity or another harness) opened in this repository.

When the developer asks to install or configure SDD in another repository:

1. Start by reading `instructions.md`.
2. Then read `questions.md`.
3. Then read `output-project-structure.md`.
4. Use the files under `templates/`, `agents/`, `skills/`, `hooks/`, `mcps/`, and `scripts/` as source material.
5. Do not treat this kit's root `AGENTS.md`/`CLAUDE.md` as the final project instruction file.
6. Generate or update the target project's own `AGENTS.md` from `templates/AGENTS.md.template` (plus the `CLAUDE.md` import stub from `templates/CLAUDE.md.template` when Claude Code is one of the harnesses).
7. Map the kit's reference layout (`.claude/`) to the harness being installed using `reference/harness-primitives.md`.
8. Ask the developer before enabling hooks, configuring MCPs, changing git policy, or assuming test/lint commands.

The final goal is to create a project-specific SDD harness, not to explain SDD abstractly.

When the developer asks to make changes in this repository:

1. If `todolist.md` exists (it is gitignored and local-only), read it: it contains the tasks to be done. If it does not exist, ask the developer what to change.
2. Complete the tasks. You may need to modify some of the hooks, MCPs, templates, etc.
3. If `bugs.md` exists (also gitignored and local-only), check that the bugs it describes are solved.
4. Mark with X all the checkboxes of the tasks/bugs you complete.
5. After adding, renaming or deleting kit files, run `scripts/update-manifest.sh` to regenerate `manifest.md`.
6. Keep every installable file harness-neutral: no harness name or harness-specific command in agents, skills, templates or policies unless it is inside a per-harness table or example.
