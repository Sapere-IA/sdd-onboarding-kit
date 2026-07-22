#!/usr/bin/env bash
set -euo pipefail

# Post-compact reorientation hook (example, disabled by default).
#
# Companion to pre-compact-capture.sh. Wired to SessionStart with matcher
# "compact": right after the context is compacted, inject a reminder to
# re-read durable artifacts instead of trusting the compacted summary.
# Advisory only — never blocks, never writes.

# stdin is consumed but not needed.
cat >/dev/null

reminder="Context was just compacted. Durable truth lives in artifacts: re-check tasks.json (active task and status), the active spec under specs/, decisions/, and history.md before continuing. If something from before the compaction seems missing, re-read those files instead of guessing."

if ! command -v jq >/dev/null 2>&1; then
  # Fail open: emit plain stdout (SessionStart stdout is added as context;
  # verify against the installed version — see README.md).
  echo "$reminder"
  exit 0
fi

jq -n --arg r "$reminder" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $r
  }
}'
exit 0
