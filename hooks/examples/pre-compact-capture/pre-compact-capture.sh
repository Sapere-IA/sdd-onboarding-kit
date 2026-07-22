#!/usr/bin/env bash
set -euo pipefail

# Pre-compact capture hook (example, disabled by default).
#
# Before the context window is compacted, remind that durable state must
# live in artifacts (tasks.json, specs/, decisions/, history.md), not in
# chat history. This hook NEVER writes memory or project files — it only
# reminds; persisting anything stays a deliberate, visible action.
#
# Modes (CAPTURE_MODE environment variable, default below):
#   warn (default) - print the checklist as a warning; never interferes.
#   gate           - block the FIRST compaction attempt per session, with
#                    the checklist as the reason (the exit-2 reason is fed
#                    back, so unsaved state can be persisted before
#                    retrying); later attempts in the same session pass.
#                    Wire gate mode to the "manual" matcher only: blocking
#                    auto-compaction can wedge a session whose context is
#                    already full.
#
# PreCompact hooks cannot inject context into the compaction itself
# (verified against the hooks docs, 2026-06) — that is why the companion
# script post-compact-reorient.sh exists for the SessionStart "compact"
# matcher.

CAPTURE_MODE="${CAPTURE_MODE:-warn}"

input="$(cat)"

checklist="Before compacting, make sure durable state is recorded in artifacts, not only in chat history:
- unresolved decisions and open questions -> decisions/ or the spec's open-questions.md
- current task status and immediate next step -> tasks.json
- failures and lessons worth keeping -> review.md or a failure-learning proposal
- architecture constraints discovered this session -> decisions/architecture-decisions.md or the design spec
Nothing is written automatically: review and persist what matters, then compact again."

if [ "$CAPTURE_MODE" = "gate" ] && command -v jq >/dev/null 2>&1; then
  session_id=$(printf '%s' "$input" | jq -r '.session_id // "no-session"' | tr -d '\r')
  state_dir="${TMPDIR:-/tmp}/sdd-pre-compact"
  mkdir -p "$state_dir"
  state_file="$state_dir/${session_id}.gated"
  if [ ! -f "$state_file" ]; then
    : > "$state_file"
    echo "$checklist" >&2
    exit 2
  fi
  exit 0
fi

# warn mode — and gate mode without jq, which fails open to warn.
echo "SDD pre-compact reminder:" >&2
echo "$checklist" >&2
exit 0
