# Spec-drift hook example (advisory by default, blocking opt-in)

Detects edits outside the approved task's scope — files the design/spec
did not anticipate. Example only — **disabled by default**, like every
kit hook.

## Where the scope comes from

The hook needs a deterministic, machine-readable scope. It reads the
optional `scope` array of glob patterns on the active task(s) in
`tasks.json`:

```json
{
  "id": "TASK-042",
  "status": "in_progress",
  "scope": ["src/auth/*", "src/middleware/session.*", "test/auth/*"]
}
```

The spec-author records these globs from the design's files-to-change
list when the spec is approved (see `agents/spec-author.md`). No scope
recorded means nothing to enforce — the hook stays silent. Spec and
harness files (`specs/`, `tasks.json`, `history.md`, `decisions/`,
`.claude/`) are always in scope.

## Strictness

| Mode | Behavior | Class |
|---|---|---|
| `DRIFT_MODE=warn` (default) | Allows the edit; injects a warning that it drifted from the approved scope. | Advisory |
| `DRIFT_MODE=block` | Denies the edit with the reason; the fix is to update the design/spec and the task's `scope` first. | Blocking |

Start in `warn` mode; move to `block` only after the team trusts the
scope data (`hooks/hooks-policy.md` rollout rule). The hook supports the
SDD state machine — out-of-scope work returns to the spec, it is not
silently absorbed.

## Guarantee

- Writes nothing, anywhere. Warn mode never interferes.
- Fails open (allows, silent) without `jq`, without `tasks.json`,
  without active approved tasks, or without scope data.
- Known limitation: with several active tasks the union of their scopes
  is allowed — the hook does not know which task an edit belongs to.

## Installation (after explicit developer approval)

Copy `spec-drift.sh` into the target project (e.g. `.claude/hooks/`),
make it executable, and add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/spec-drift.sh"
          }
        ]
      }
    ]
  }
}
```

For block mode, set `DRIFT_MODE=block` in the environment or change the
default at the top of the script.

## Version note

The `permissionDecision` output format and `tool_input` field names can
evolve between Claude Code versions. Verify against the installed
version's hook documentation before enabling — the kit-wide rule in
`hooks/settings-snippets.md` applies.

## Environment

Bash plus `jq` (Git Bash or WSL on Windows). Without `jq` the hook warns
and allows — it never blocks.
