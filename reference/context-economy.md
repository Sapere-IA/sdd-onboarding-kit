# Context economy

An agent's context window is a scarce, shared resource. Everything loaded into a session — project instructions, file contents, tool definitions, conversation history — competes for the same space. When the window fills up, quality degrades before capacity runs out: instructions get diluted, earlier decisions fade, and the model starts re-deriving things it already knew.

Most well-known coding-agent "tricks" are really context-management practices. This kit treats them as one explicit policy, valid in every harness (Claude Code, Codex, Cursor, OpenCode, Antigravity); only the command names differ.

## The principle

Load the minimum context needed for the current step, keep durable knowledge in files instead of chat history, and reset between unrelated tasks.

## Practices

### Keep `AGENTS.md` concise and linked

`AGENTS.md` (and, in Claude Code, the `CLAUDE.md` that imports it) is loaded into every session, so every line has a permanent cost.

- Keep it to stable facts and short rules: commands, policies, locations, state machine.
- Link to deeper files (`reference/`, skills, project map, decision logs) instead of copying their content.
- Move any multi-step procedure into a skill. A skill's body loads only when used; `AGENTS.md` content is always loaded.
- If a section grows past a screen, it probably belongs in a linked file.

### Inspect usage and compact with the harness's commands

| Harness | Inspect context usage | Compact / summarize | Fresh start |
| --- | --- | --- | --- |
| Claude Code | `/context` | `/compact [focus instructions]` | `/clear` |
| Codex CLI | `/status` | `/compact` | `/new` |
| Cursor | context indicator in the chat UI | summarize from the chat UI / new chat | new chat |
| OpenCode | session view | `/compact` (alias `/summarize`) | `/new` (alias `/clear`) |
| Antigravity | conversation view | no compaction command documented — start a new conversation | new conversation |

Names verified on 2026-09-27; re-verify against the installed version. Recommend inspecting usage when:

- a session has been long and behavior is degrading;
- deciding whether to compact or start fresh;
- auditing whether `AGENTS.md`, MCP toolsets, or large files are consuming the window.

Compact between unrelated tasks, after a noisy investigation, or when usage shows the window filling up. Prefer **selective compacting** where the harness accepts focus instructions (Claude Code does). When compacting mid-feature, instruct it to preserve:

- decisions made and their reasons;
- current task status and next steps;
- architecture constraints discovered;
- unresolved questions.

Example (Claude Code):

```text
/compact Preserve: the approved spec decisions, current task status, the constraint that the API is read-only, and the open question about pagination.
```

Where the harness cannot take focus instructions, write those four items to their artifacts first, then compact or start a new conversation.

In an SDD project, compaction is safe because durable truth lives in files (`tasks.json`, `specs/`, decision logs, `history.md`), not in the chat. If something matters beyond the session, write it to an artifact before compacting.

### Use subagents for noisy research

Exploration that reads many files — locating code, surveying a directory tree, broad searches — pollutes the main context with content that is only needed to produce a short conclusion. Delegate it to a subagent (where the harness has them) and keep only the conclusion in the main conversation.

Good candidates: codebase exploration, dependency surveys, log analysis, long test output triage. Poor candidates: small targeted reads, or work whose full detail the main conversation genuinely needs.

### Use skills for repeatable long procedures

If the same multi-step instructions are pasted or re-explained across sessions, turn them into a skill. The procedure is versioned, reviewed once, and loaded only when invoked.

### Avoid loading MCP-heavy toolsets unless needed

Every configured MCP server adds tool definitions to the context of every session, whether used or not. Configure MCPs per project and only when the project actually needs them; prefer scoping heavy toolsets (e.g. browser automation) to a dedicated subagent where the harness supports per-agent MCPs. See `mcps/mcp-policy.md`.

## Good vs bad context loading

| Situation | Bad (context-expensive) | Good (context-economical) |
|---|---|---|
| Project orientation | Paste the directory tree and ten files into chat | Link a concise project map from `AGENTS.md` |
| Long procedure | Copy the full SDD workflow into `AGENTS.md` | Keep it in the `sdd-workflow` skill |
| Finding code | Read 20 files in the main conversation | Subagent searches; returns paths and a summary |
| Task switch | Continue in the same long session | Compact (or start fresh if truly unrelated) |
| External tools | Enable every MCP globally | Configure per project, scope heavy ones to subagents |
| Past decisions | Rely on chat history | Record in decision logs / specs, link from `AGENTS.md` |

## Where durable context lives in an SDD project

| Kind of knowledge | Artifact |
|---|---|
| Stable rules and commands | `AGENTS.md` (short, linked) |
| Task state | `tasks.json` |
| Feature requirements/design | `specs/<feature-slug>/` |
| Decisions and rejected options | decision logs (`decisions/`) |
| Completed work | `history.md` |
| Procedures | `<harness-dir>/skills/` |
