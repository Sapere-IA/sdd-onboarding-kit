#!/usr/bin/env bash
set -euo pipefail

# Example hook script.
# Adapt this script to the project's real task storage and source directories.
# This script assumes local tasks.json and blocks edits to implementation files
# when there is an active SDD task without human approval.
# Edits to spec files (specs/, tasks.json, history.md, etc.) are always allowed.
#
# KNOWN LIMITATION (deliberate, to keep the example simple): the guard is
# project-wide, not per-task. If ANY sdd:true task is pending/spec_draft/
# spec_ready, ALL implementation edits are blocked — including work on a
# different, already-approved task. If your team runs several SDD tasks in
# parallel, adapt the jq filter to scope the check to the task being worked on
# (e.g. by branch name or an ACTIVE_TASK env var).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASKS_FILE="$PROJECT_DIR/tasks.json"

if [[ ! -f "$TASKS_FILE" ]]; then
  exit 0
fi

# Read file path from hook input.
# tr -d '\r': jq on Windows emits CRLF; a stray \r breaks pattern matching.
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null | tr -d '\r' || true)

# Allow edits to SDD spec/config files regardless of task status.
# These are the files that must be editable during spec_draft and spec_ready phases.
case "$FILE_PATH" in
  */specs/*|*/tasks.json|*/history.md|*/open-questions.md|*/requirements.md|\
  */design.md|*/tasks.md|*/assumptions.md|*/acceptance-tests.md|*/review.md|\
  */.claude/*)
    exit 0
    ;;
esac

# If jq is unavailable, warn but do not block. Change this policy if desired.
if ! command -v jq >/dev/null 2>&1; then
  echo "SDD hook warning: jq not found; cannot enforce approval guard." >&2
  exit 0
fi

ACTIVE_UNAPPROVED=$(jq '[.tasks[]? | select(.sdd == true and (.status == "pending" or .status == "spec_draft" or .status == "spec_ready"))] | length' "$TASKS_FILE")

if [[ "$ACTIVE_UNAPPROVED" -gt 0 ]]; then
  echo "Blocked by SDD policy: there is an SDD task awaiting spec approval." >&2
  echo "File attempted: ${FILE_PATH:-unknown}" >&2
  echo "Only spec files (specs/, tasks.json, history.md, .claude/) are allowed until status is human_approved or in_progress." >&2
  exit 2
fi

exit 0
