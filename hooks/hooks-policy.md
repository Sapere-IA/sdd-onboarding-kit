# Hooks policy for the SDD harness

Hooks are optional but useful for enforcing deterministic workflow constraints.

Do not enable hooks without explicit developer approval.

## Why hooks matter

Prompts and skills guide the agent. Hooks can enforce rules regardless of whether the agent remembers them.

Use hooks for rules like:

- block implementation before spec approval;
- block destructive shell commands;
- run tests or lint after edits;
- validate task state transitions;
- notify when human approval is needed.

## Harness support

Hook support differs per harness (`reference/harness-primitives.md`):

| Harness | Hook mechanism | Kit support |
| --- | --- | --- |
| Claude Code | `.claude/settings.json` → `hooks` (`PreToolUse`, `PostToolUse`, `PreCompact`, `SessionStart`) | Full: scripts + wiring snippets |
| Codex CLI | `.codex/hooks.json` or `[hooks]` in `.codex/config.toml`; same events, payload and exit codes as Claude Code; loads once the project is trusted | Full: same snippets as Claude Code |
| Cursor | `.cursor/hooks.json` (`preToolUse`, `afterFileEdit`, `beforeShellExecution`, `afterShellExecution`, `preCompact`, `sessionStart`) | Full: scripts read Cursor payloads; `SDD_HOOK_OUTPUT=cursor` for JSON denies |
| Antigravity | `.agents/hooks.json` (`PreToolUse`, `PostToolUse`; tool names `write_to_file`, `replace_file_content`, `run_command`) | Full: scripts read `toolCall` payloads; `SDD_HOOK_OUTPUT=antigravity` |
| OpenCode | JavaScript plugins in `.opencode/plugins/` (`tool.execute.before/after`) — no shell hooks | Via a small plugin that shells out to the same scripts (snippet provided) |
| Other | none | Nothing installed; rules stay instruction-level (the kit's default posture) |

The example hook **scripts are the same file for every harness**; only the wiring differs. See `settings-snippets.md`.

## Hook contract (harness-neutral scripts)

Every kit hook script starts with the same adapter block. It gives the script these inputs, in priority order:

| Value | Explicit override | Read from the payload on stdin |
| --- | --- | --- |
| `sdd_project_dir` | `SDD_PROJECT_DIR`, else `CLAUDE_PROJECT_DIR`, else `CURSOR_PROJECT_DIR` | `.cwd` (Claude Code, Codex, Cursor) or `.workspacePaths[0]` (Antigravity); else the current directory |
| `sdd_file` | `SDD_HOOK_FILE`, else the first argument | `.tool_input.file_path` / `.tool_input.notebook_path` (Claude Code, Codex), `.file_path` (Cursor), `.toolCall.args.TargetFile` (Antigravity) |
| `sdd_command` | `SDD_HOOK_COMMAND` | `.tool_input.command` (Claude Code, Codex), `.command` (Cursor), `.toolCall.args.CommandLine` (Antigravity) |
| `sdd_content` | `SDD_HOOK_CONTENT` | `.tool_input.content` / `.tool_input.new_string`, `.content`, Cursor `.edits[].new_string`, Antigravity `CodeContent` / `ReplacementContent` |
| `sdd_tool` | `SDD_HOOK_TOOL` | `.tool_name` or `.toolCall.name` |
| `sdd_session` | `SDD_HOOK_SESSION` | `.session_id` or `.conversationId`; default `no-session` |
| `sdd_event` | `SDD_HOOK_EVENT` | `.hook_event_name`; default per script |

And two output helpers, formatted per `SDD_HOOK_OUTPUT`:

| `SDD_HOOK_OUTPUT` | `sdd_block "<reason>"` (deny) | `sdd_context "<text>"` (advisory) | Use for |
| --- | --- | --- | --- |
| `exit` (default) | reason on stderr, **exit 2** | `{"hookSpecificOutput": {"hookEventName": …, "additionalContext": …}}` on stdout | Claude Code, Codex; Cursor also honors exit 2 |
| `cursor` | `{"permission": "deny", "user_message": …, "agent_message": …}` on stdout, exit 0 | `{"permission": "allow", "agent_message": …}` | Cursor when a JSON decision is preferred |
| `antigravity` | `{"decision": "deny", "reason": …}` on stdout, exit 0 | text on stderr | Antigravity |
| `plain` | reason on stderr, exit 2 | text on stderr | wrappers, OpenCode plugin, manual runs |

Rules for adding or adapting a hook:

- Keep the adapter block byte-identical across scripts (copy it from any kit hook); put project logic below it and use only the `sdd_*` values.
- Explicit overrides win over the payload, so a wrapper (OpenCode plugin, CI, a manual test) can call any script as `SDD_HOOK_FILE=<path> script.sh` or `script.sh <path>` with no stdin.
- Blocking is always `sdd_block`; never `exit 2` directly, so the wiring's output format applies.
- Fail open when `jq` is missing (warn and allow), unless the developer explicitly accepts fail-closed.
- Verify the event names and payload field names against the installed harness version before enabling; the adapter covers the shapes documented on 2026-09-27.

## Recommended rollout

1. Start with no hooks enabled.
2. Install hook scripts as examples.
3. Ask the developer which hooks to enable.
4. Enable warning-only mode first where possible.
5. Move to blocking mode after the team trusts the workflow.

## Risk

Hooks can block legitimate work if they are too broad. Keep them small, testable and project-specific.

## Environment requirements

The example hook scripts are bash and rely on `jq` for reading hook JSON and `tasks.json`. On Windows this means Git Bash (or WSL) plus `jq` installed and on `PATH`. The examples fail open — they warn and allow the action — when `jq` is missing; switch them to fail closed only if the developer explicitly accepts that hooks will block work on machines without `jq`.

## Safety classification

Every hook in the kit — and any hook added during onboarding — is classified by its highest-risk behavior:

### Advisory

Observes and suggests. Never blocks a tool call, never writes project files or memory (a temp-directory counter at most). Safe to enable first.

### Blocking

Can stop a tool call (non-zero exit or a deny decision). Writes nothing. Enable once the team trusts the rule; prefer starting the same script in its warn mode where one exists.

### Mutating

Runs commands that change files or state (formatters that rewrite code, generators, anything with side effects beyond reading). **The kit ships no mutating hook.** Adding one requires explicit opt-in: the developer must approve it knowing exactly what it changes, and the hook's README must document every side effect.

### Dangerous

Touches external systems, credentials, git history, deployments, or production data. **The kit ships none and recommends against them.** If a project insists, the approval must be explicit and recorded (e.g. in `decisions/workflow-decisions.md`), and the hook must be scoped as narrowly as possible.

A hook is listed under its highest applicable class: a hook that suggests by default but can be switched to block is documented under both modes. Delivery can additionally be async (run in the background) for slow validations or notifications — async does not change the classification.

## Classification of the kit's example hooks

All of these are **examples, disabled by default**. None is enabled by installing the kit.

| Hook | Class | Notes |
|---|---|---|
| `block-implementation-before-approval.sh` | Blocking | Denies before approval; spec/harness files always allowed. |
| `run-tests-after-edit.sh` | Advisory | Runs the configured test command after edits; never blocks. |
| `validate-spec-before-status-change.sh` | Blocking | Blocks `spec_ready` without the three core spec files. |
| `failure-learning/suggest-failure-learning.sh` | Advisory | Suggests the failure-learning skill; never writes memory. |
| `pre-compact-capture/` | Advisory | Reminds before compaction that durable state belongs in artifacts; never blocks, never writes. |
| `targeted-validation/` | Advisory | Suggests (default) or runs targeted checks for changed files; never blocks. |
| `spec-drift/` | Blocking (opt-in) / Advisory (default) | `DRIFT_MODE=warn` warns; `DRIFT_MODE=block` blocks edits outside the approved task scope. |

## Project-specific requirement

Before enabling a hook, the onboarding agent must know:

- harness and wiring file;
- event;
- matcher;
- command (including any `SDD_HOOK_OUTPUT` or mode variables);
- whether it blocks;
- what files it reads;
- what false positives are acceptable.
