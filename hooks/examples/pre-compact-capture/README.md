# Pre-compact capture hook example (advisory)

Reminds — before the context window is compacted — that durable state must
live in artifacts (`tasks.json`, `specs/`, `decisions/`, `history.md`),
not in chat history. Example only — **disabled by default**, like every
kit hook.

## Guarantee

- Neither script writes memory (global or project) or project files; the
  only side effect is a gate marker under the system temp directory.
- `pre-compact-capture.sh` never blocks in `warn` mode (default); in
  `gate` mode it blocks exactly one manual compaction per session.
- `post-compact-reorient.sh` never blocks anything.
- Both fail open when `jq` is missing.

## Why two scripts

`PreCompact` hooks cannot inject context into the compaction — they can
only warn or block (verified against the hooks docs, 2026-06). So the
example splits the job:

| Script | Event / matcher | What it does |
|---|---|---|
| `pre-compact-capture.sh` | `PreCompact`, matcher `manual` (and `auto` for warn mode) | `warn` (default): prints the persistence checklist. `gate`: blocks the first manual compaction per session with the checklist as the reason, so unsaved decisions/status/lessons can be persisted before retrying. |
| `post-compact-reorient.sh` | `SessionStart`, matcher `compact` | After compaction, injects `additionalContext`: re-read durable artifacts instead of trusting the compacted summary. |

Set `gate` mode only on the `manual` matcher. Blocking `auto` compaction
can wedge a session whose context is already full.

## Installation (after explicit developer approval)

Copy both scripts into the target project (e.g. `.claude/hooks/`), make
them executable, and add to `.claude/settings.json`:

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "manual",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/pre-compact-capture.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-compact-reorient.sh"
          }
        ]
      }
    ]
  }
}
```

For gate mode, set `CAPTURE_MODE=gate` in the environment or change the
default at the top of the script.

## Version note

Event names, matchers (`manual`, `auto`, `compact`), and output shapes can
evolve between Claude Code versions. Verify against the installed
version's hook documentation before enabling — the kit-wide rule in
`hooks/settings-snippets.md` applies.

## Environment

Bash plus `jq` (Git Bash or WSL on Windows). Without `jq`, gate mode falls
back to warn and the reorient script falls back to plain stdout.
