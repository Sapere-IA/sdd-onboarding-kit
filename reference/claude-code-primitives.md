# Claude Code primitives used by this kit

This file explains the Claude Code concepts used by the SDD harness.

## `CLAUDE.md`

`CLAUDE.md` contains persistent instructions loaded by Claude Code. In a project, it should hold stable facts and rules: build commands, testing commands, architecture notes, conventions and common workflows.

In this kit, the target project receives its own `CLAUDE.md` generated from `templates/CLAUDE.md.template`.

Recommended use:

- keep it concise;
- make it project-specific;
- avoid long theory;
- move long procedures into skills.

## Subagents

Subagents are specialized Claude Code assistants defined as Markdown files with YAML frontmatter.

This kit defines four project subagents:

- `leader`
- `spec-author`
- `implementer`
- `reviewer`

During onboarding, these files should be copied into:

```text
.claude/agents/
```

Project-level agents are preferable here because the SDD harness depends on project commands, conventions and approval rules.

## Skills

A Claude Code skill is a folder containing `SKILL.md` plus optional supporting files.

This kit defines:

```text
.claude/skills/sdd-workflow/
```

Use the skill for multi-step SDD work. Keep the project `CLAUDE.md` as the entrypoint and the skill as the detailed workflow.

## Hooks

Hooks are deterministic automation points in Claude Code's lifecycle. They can run shell commands or other handlers before/after tool use, at session start, when files change, when subagents start/stop, and so on.

In this kit, hooks are optional. They should be enabled only after explicit developer approval.

Useful SDD hooks include:

- block implementation before human approval;
- run tests or lint after edits;
- validate task state transitions;
- prevent dangerous shell commands;
- notify when human approval is needed.

## MCPs

MCP servers connect Claude Code to external systems: issue trackers, GitHub, documentation, monitoring, databases, internal APIs, etc.

In this kit, MCPs are optional. The minimum setup uses local files.

Use MCPs when the developer wants Claude Code to read or update external systems directly rather than relying on pasted context.

## Local files as memory

The minimum SDD harness uses local files:

```text
tasks.json
specs/<feature>/requirements.md
specs/<feature>/design.md
specs/<feature>/tasks.md
history.md
```

This keeps the process transparent, versionable and easy to debug.
