# Hook wiring snippets per harness

These snippets are examples only. Do not paste them without adapting paths, commands and matchers to the target project and verifying event names against the installed harness version. The hook **scripts** are identical in every harness (see `hooks-policy.md`, "Hook contract"); only the wiring below differs. Scripts are assumed to be installed under `<harness-dir>/hooks/` (or `scripts/`).

## Claude Code — `.claude/settings.json`

Codex CLI uses the same JSON shape in `.codex/hooks.json` (see below).

### Pre-edit approval guard (blocking)

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/block-implementation-before-approval.sh" },
          { "type": "command", "command": ".claude/hooks/validate-spec-before-status-change.sh" },
          { "type": "command", "command": ".claude/hooks/spec-drift.sh" }
        ]
      }
    ]
  }
}
```

### Post-edit validation (advisory)

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/targeted-validation.sh" }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/suggest-failure-learning.sh" }
        ]
      }
    ]
  }
}
```

Use `./scripts/run-tests.sh` (or `run-tests-after-edit.sh`) on `Edit|Write` only once the toolchain exists.

### Pre-compact capture (advisory)

```json
{
  "hooks": {
    "PreCompact": [
      { "matcher": "manual", "hooks": [ { "type": "command", "command": ".claude/hooks/pre-compact-capture.sh" } ] }
    ],
    "SessionStart": [
      { "matcher": "compact", "hooks": [ { "type": "command", "command": ".claude/hooks/post-compact-reorient.sh" } ] }
    ]
  }
}
```

Gate mode (`CAPTURE_MODE=gate`) goes on the `manual` matcher only.

### Subagent lifecycle example

```json
{
  "hooks": {
    "SubagentStart": [
      { "matcher": "implementer", "hooks": [ { "type": "command", "command": "./scripts/validate-sdd-structure.sh" } ] }
    ]
  }
}
```

## Codex CLI — `.codex/hooks.json` or `[hooks]` in `.codex/config.toml`

Codex hooks use the same events (`PreToolUse`, `PostToolUse`, `PreCompact`, `SessionStart`, `SubagentStart`), the same stdin payload (`tool_name`, `tool_input.file_path`, `tool_input.command`, `cwd`) and the same exit-code semantics (exit 2 blocks) as Claude Code. Copy the Claude Code snippets into `.codex/hooks.json` with the script paths adjusted (`.codex/hooks/...`). Inline TOML equivalent:

```toml
[[hooks.PreToolUse]]
matcher = "Edit|Write"

[[hooks.PreToolUse.hooks]]
type = "command"
command = ".codex/hooks/block-implementation-before-approval.sh"
timeout = 30
```

Project-level Codex hooks load only after the project is trusted; the developer reviews them with `/hooks` on first start. Verify tool names in matchers (`Edit|Write`, `Bash`) against the installed Codex version.

## Cursor — `.cursor/hooks.json`

Cursor has no pre-edit event with a rewritable payload for every edit path, so the approval guard is wired to `preToolUse` (tool `Write`) and `afterFileEdit`; `beforeShellExecution` carries the command. Set `SDD_HOOK_OUTPUT=cursor` when the hook should deny through Cursor's JSON (`exit 2` also blocks).

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      { "matcher": "Write", "command": "SDD_HOOK_OUTPUT=cursor .cursor/hooks/block-implementation-before-approval.sh" },
      { "matcher": "Write", "command": "SDD_HOOK_OUTPUT=cursor .cursor/hooks/validate-spec-before-status-change.sh" },
      { "matcher": "Write", "command": "SDD_HOOK_OUTPUT=cursor .cursor/hooks/spec-drift.sh" }
    ],
    "afterFileEdit": [
      { "command": "SDD_HOOK_OUTPUT=plain .cursor/hooks/targeted-validation.sh" }
    ],
    "afterShellExecution": [
      { "command": "SDD_HOOK_OUTPUT=plain .cursor/hooks/suggest-failure-learning.sh" }
    ],
    "preCompact": [
      { "command": "SDD_HOOK_OUTPUT=plain .cursor/hooks/pre-compact-capture.sh" }
    ]
  }
}
```

`CURSOR_PROJECT_DIR` is set by Cursor and picked up by the adapter. The `afterShellExecution` payload carries no exit status the scripts can rely on; wrap the command or set `SDD_HOOK_FAILED=1` from a wrapper if the failure signal matters. Verify field names against the installed Cursor version.

## Antigravity — `.agents/hooks.json`

Antigravity matches on its tool names (`write_to_file`, `replace_file_content`, `multi_replace_file_content`, `run_command`) and expects a stdout JSON decision; set `SDD_HOOK_OUTPUT=antigravity`.

```json
{
  "sdd-harness": {
    "PreToolUse": [
      {
        "matcher": "write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [
          { "type": "command", "command": "SDD_HOOK_OUTPUT=antigravity .agents/hooks/block-implementation-before-approval.sh", "timeout": 10 },
          { "type": "command", "command": "SDD_HOOK_OUTPUT=antigravity .agents/hooks/validate-spec-before-status-change.sh", "timeout": 10 },
          { "type": "command", "command": "SDD_HOOK_OUTPUT=antigravity .agents/hooks/spec-drift.sh", "timeout": 10 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "write_to_file|replace_file_content|multi_replace_file_content",
        "hooks": [ { "type": "command", "command": "SDD_HOOK_OUTPUT=antigravity .agents/hooks/targeted-validation.sh", "timeout": 10 } ]
      },
      {
        "matcher": "run_command",
        "hooks": [ { "type": "command", "command": "SDD_HOOK_OUTPUT=antigravity .agents/hooks/suggest-failure-learning.sh", "timeout": 10 } ]
      }
    ]
  }
}
```

The project directory comes from the payload's `workspacePaths[0]`. Antigravity has no compaction event; the pre-compact scripts are not wired.

## OpenCode — `.opencode/plugins/sdd-hooks.js`

OpenCode runs JavaScript plugins instead of shell hooks. This plugin forwards the same scripts through the explicit-override interface (no stdin); a non-zero exit blocks the tool call.

```js
// .opencode/plugins/sdd-hooks.js — forwards SDD hook scripts (kit-provided, adapt paths)
import { execFileSync } from "node:child_process"

const HOOKS = ".opencode/hooks"
const run = (script, env, directory) => {
  try {
    const out = execFileSync("bash", [`${HOOKS}/${script}`], {
      cwd: directory, env: { ...process.env, SDD_PROJECT_DIR: directory, SDD_HOOK_OUTPUT: "plain", ...env },
      stdio: ["ignore", "pipe", "pipe"],
    })
    return { ok: true, out: String(out) }
  } catch (e) {
    return { ok: false, out: String(e.stderr || e.message) }
  }
}

export const SddHooks = async ({ directory }) => ({
  "tool.execute.before": async (input, output) => {
    if (["write", "edit"].includes(input.tool)) {
      const env = { SDD_HOOK_FILE: output.args.filePath, SDD_HOOK_CONTENT: output.args.content ?? output.args.newString ?? "" }
      for (const s of ["block-implementation-before-approval.sh", "validate-spec-before-status-change.sh", "spec-drift.sh"]) {
        const r = run(s, env, directory)
        if (!r.ok) throw new Error(r.out)
      }
    }
  },
  "tool.execute.after": async (input, output) => {
    if (["write", "edit"].includes(input.tool)) run("targeted-validation.sh", { SDD_HOOK_FILE: output.args?.filePath }, directory)
    if (input.tool === "bash") run("suggest-failure-learning.sh", { SDD_HOOK_COMMAND: output.args?.command, SDD_HOOK_TOOL: "bash" }, directory)
  },
  "session.compacted": async () => { run("post-compact-reorient.sh", {}, directory) },
})
```

Verify the tool names (`write`, `edit`, `bash`) and argument keys (`filePath`, `content`, `command`) against the installed OpenCode version. Advisory output from `plain` mode goes to the plugin's stderr; surface it through the client API if the team wants it in the conversation.

## Warning

Hook JSON shape, event names and tool names used in matchers evolve with each harness's versions. During onboarding, verify the current local documentation or installed version before finalizing the wiring, and record the harness and version in `decisions/answers.md`.
