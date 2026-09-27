# Harness primitives used by this kit

The SDD harness is built from five agent-harness concepts: a **project instruction file**, **skills**, **subagents**, **hooks**, and **MCP servers**, plus local files as memory. Every supported harness (Claude Code, OpenAI Codex CLI, Cursor, OpenCode, Google Antigravity) offers most of them under its own name and directory. This file explains each concept, gives the mapping per harness, and defines the fallback when a harness lacks one.

The kit's own layout uses the Claude Code names (`.claude/`, `CLAUDE.md`) as the **reference layout**. When the kit says `.claude/<x>`, read it as `<harness-dir>/<x>` for the harness you are installing into, using the table below. Nothing in the kit is Claude Code-only by design; where a harness differs, adapt the file, never the workflow.

## Mapping table

| Concept | Claude Code | Codex CLI | Cursor | OpenCode | Antigravity |
| --- | --- | --- | --- | --- | --- |
| Harness directory (`<harness-dir>`) | `.claude/` | `.codex/` (agents, hooks, config) and `.agents/` (skills) | `.cursor/` | `.opencode/` | `.agents/` |
| Project instruction file | `AGENTS.md` (read natively when no `CLAUDE.md` exists, v2.1.277+), or `CLAUDE.md` importing it with `@AGENTS.md` | `AGENTS.md` (root → cwd, one per directory; `AGENTS.override.md` wins) | `AGENTS.md` (root and nested); `.cursor/rules/*.mdc` for scoped rules | `AGENTS.md` (`CLAUDE.md` read as fallback) | `AGENTS.md` (root and nested); `.agents/rules/*.md` for scoped rules |
| Skills directory | `.claude/skills/<name>/SKILL.md` | `.agents/skills/<name>/SKILL.md` | `.cursor/skills/` or `.agents/skills/` (also reads `.claude/skills/`, `.codex/skills/`) | `.opencode/skills/` (also reads `.claude/skills/`, `.agents/skills/`) | `.agents/skills/<name>/SKILL.md` |
| Skill frontmatter | `name`, `description` (+ `argument-hint`) | `name`, `description` | `name`, `description` | `name`, `description` | `name`, `description` |
| Skill invocation | `/sdd-workflow` | `$sdd-workflow` or `/skills` | `/` then search the name | agent calls the `skill` tool; ask by name | `/sdd-workflow` |
| Subagents directory | `.claude/agents/<name>.md` | `.codex/agents/<name>.toml` | `.cursor/agents/<name>.md` (also reads `.claude/agents/`) | `.opencode/agents/<name>.md` | `.agents/agents/<name>.md` |
| Subagent format | Markdown, frontmatter `name`, `description`, `tools`, `model` | TOML: `name`, `description`, `developer_instructions` (body goes here), `sandbox_mode`, `model` | Markdown, frontmatter `name`, `description`, `model`, `readonly` | Markdown, frontmatter `description`, `mode: subagent`, `permission`, `model` | Markdown, frontmatter `name`, `description`, `tools`, `model`, `subagent: true` |
| Subagent invocation | `Agent` tool / by name | `spawn_agent` tool / `@name` | `/name` or by name | `@name` / Task tool | `invoke_subagent` tool |
| Hooks config | `.claude/settings.json` `"hooks"` | `.codex/hooks.json` or `[hooks]` in `.codex/config.toml` (same shape as Claude Code) | `.cursor/hooks.json` (`"version": 1`) | `.opencode/plugins/*.js` (JavaScript plugin, no shell hooks) | `.agents/hooks.json` |
| Hook events used by the kit | `PreToolUse`, `PostToolUse`, `PreCompact`, `SessionStart` | `PreToolUse`, `PostToolUse`, `PreCompact`, `SessionStart` | `preToolUse`, `afterFileEdit`, `beforeShellExecution`, `preCompact`, `sessionStart` | `tool.execute.before`, `tool.execute.after`, `session.compacted` | `PreToolUse`, `PostToolUse` |
| Hook stdin: file path | `.tool_input.file_path` | `.tool_input.file_path` | `.file_path` (afterFileEdit) / `.tool_input` (preToolUse) | `output.args.filePath` (plugin API) | `.toolCall.args.TargetFile` |
| Hook stdin: shell command | `.tool_input.command` | `.tool_input.command` | `.command` (beforeShellExecution) | `output.args.command` | `.toolCall.args.CommandLine` |
| Hook block | exit 2 + stderr, or `hookSpecificOutput.permissionDecision: deny` | exit 2 + stderr, or `hookSpecificOutput.permissionDecision: deny` | exit 2, or stdout `{"permission":"deny"}` | `throw new Error(reason)` | stdout `{"decision":"deny","reason":"…"}` |
| Project dir for hooks | `CLAUDE_PROJECT_DIR` | `.cwd` in stdin | `CURSOR_PROJECT_DIR` | `directory` in plugin context | `.workspacePaths[0]` in stdin |
| MCP config | `.mcp.json` | `[mcp_servers.<name>]` in `.codex/config.toml` | `.cursor/mcp.json` | `"mcp"` block in `opencode.json` | `.agents/mcp_config.json` (`mcpServers`) |
| Context inspection / compaction | `/context`, `/compact [focus]` | `/compact` | summarize from the chat UI | `/compact` (alias `/summarize`) | new conversation; no compaction command documented |

Verified against the vendors' documentation on 2026-09-27 (Claude Code `code.claude.com/docs`; Codex `developers.openai.com/codex`; Cursor `cursor.com/docs`; OpenCode `opencode.ai/docs`; Antigravity `antigravity.google/docs`). Harness features move fast: **re-verify the row you are about to use against the installed version before generating configuration**, and record any deviation in `decisions/answers.md`.

## Project instruction file

The instruction file holds persistent, stable project facts and rules: commands, architecture notes, conventions, the SDD policy, and links to the harness files. All supported harnesses read `AGENTS.md`, so the kit generates **`AGENTS.md` as the single source of truth** from `templates/AGENTS.md.template`.

- **Claude Code** reads `AGENTS.md` directly when the project has no `CLAUDE.md`, but only in recent versions and not in every session type. For reliability, also generate the two-line `CLAUDE.md` from `templates/CLAUDE.md.template`, which imports `AGENTS.md` with `@AGENTS.md`. Claude Code deduplicates an imported `AGENTS.md`, so it is never loaded twice.
- **Codex, Cursor, OpenCode, Antigravity** read `AGENTS.md` natively; no stub is needed. Do not add per-harness copies of the content: one file, many readers.
- Keep it short and project-specific; long procedures go into the skill. Never embed the directory tree; link the project map.

## Skills

A skill is a folder with `SKILL.md` (YAML frontmatter `name` + `description`, then instructions) plus supporting files. The `SKILL.md` format is shared by every supported harness (the "Agent Skills" convention), so the kit's skills install **unchanged**; only the directory differs.

- Install the core skill at `<harness-dir>/skills/sdd-workflow/` (see the table for the directory each harness reads). Cursor, OpenCode and Codex also read `.agents/skills/`, so a project used with several of them can install the skills once under `.agents/skills/`; Claude Code reads only `.claude/skills/`.
- Skills are invoked differently per harness (slash command, `$name`, a `skill` tool, or simply by asking). The generated `AGENTS.md` names the skill and says "invoke it by name"; do not hard-code one harness's syntax in installed files.
- **Fallback when a harness has no skill support:** install the same folder anyway and add a line to `AGENTS.md`: "Before any SDD work, read `<harness-dir>/skills/sdd-workflow/SKILL.md` and follow it." The workflow is identical; only the loading trigger changes.

## Subagents

The kit defines five roles (`leader`, `spec-author`, `implementer`, `reviewer`, `documenter`, plus the optional `browser-tester`) as markdown files with a `name`/`description`/`tools` frontmatter and a body of instructions. The **body is the role**; the frontmatter is packaging.

- **Markdown harnesses** (Claude Code, Cursor, OpenCode, Antigravity): copy the file, keep the body, and adapt the frontmatter to the harness's fields (see the table). Unknown keys are ignored by most harnesses, but drop `tools:` where the harness uses a different permission model (OpenCode `permission`, Cursor `readonly`).
- **Codex CLI**: convert to TOML: `name`, `description`, and the whole markdown body as `developer_instructions` (multi-line string). Use `sandbox_mode = "read-only"` for `leader` and `reviewer`.
- **Fallback when a harness has no subagents:** keep the files under `<harness-dir>/agents/` as *role definitions* and add to `AGENTS.md`: "When the SDD workflow calls for the `<role>` agent, read `<harness-dir>/agents/<role>.md` and act as that role in the main conversation, one role at a time." The workflow already assumes the main conversation orchestrates roles sequentially, so nothing else changes.
- Whatever the harness, roles never advance SDD state on their own: approval and `done` stay human-gated.

## Hooks

Hooks are deterministic checks the harness runs around tool calls. Prompts and skills guide; hooks enforce. The kit ships example hook **scripts** that are harness-neutral (they read the payload shape of every supported harness, or explicit environment variables) and per-harness **wiring** snippets. See `hooks/hooks-policy.md` ("Hook contract") and `hooks/settings-snippets.md`.

- Claude Code and Codex share the same hook JSON shape, events and exit-code semantics: the same snippet works in both.
- Cursor uses lowercase event names and its own payloads; the scripts handle them, and `SDD_HOOK_OUTPUT=cursor` selects its deny format when needed (exit 2 also blocks).
- Antigravity uses `hooks.json` with `toolCall.name`/`toolCall.args` payloads and a stdout `{"decision":"deny"}` response: set `SDD_HOOK_OUTPUT=antigravity` in the wiring.
- OpenCode has no shell hooks; a tiny JavaScript plugin shells out to the same script (snippet provided).
- **Fallback when a harness has no hooks:** nothing is installed; the rules stay instruction-level in `AGENTS.md` and the skill. This is already the kit's default posture (hooks are opt-in), so the workflow is unchanged, only its enforcement is advisory.

## MCP servers

MCP servers connect the agent to external systems (issue trackers, GitHub, docs, browsers). The **server definitions are the same** everywhere (command, args, env, or URL); only the configuration file differs (see the table). The kit's `mcps/*.md` notes describe what to configure; the installing agent writes it into the harness's file. MCPs stay optional and off by default; the browser-tester agent scopes Playwright to itself where the harness supports per-agent MCP declarations (Claude Code, Codex), otherwise it is configured project-wide with the same permission rules.

## Local files as memory

Independent of the harness, the harness state lives in versioned files:

```text
tasks.json
specs/<feature>/requirements.md
specs/<feature>/design.md
specs/<feature>/tasks.md
history.md
decisions/
```

This is what makes the kit portable: every harness reads and writes the same artifacts, and a project can be worked on with several harnesses at once without translating state.

## Installing for more than one harness

Choose one **primary harness directory** (`questions.md` §0). Install the full harness there. For each additional harness, install only what it cannot read from the primary location: the skills and agents directories (copies, recorded in the manifest), the hook wiring, and the MCP config file. `AGENTS.md`, `specs/`, `tasks.json`, `history.md`, `decisions/` and `scripts/` are shared and never duplicated. Record every directory in the manifest's `harness` block so `sdd-update` can refresh all copies.
