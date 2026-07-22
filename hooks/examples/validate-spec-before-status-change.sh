#!/usr/bin/env bash
# PreToolUse hook: blocks Edit/Write calls that move a task to spec_ready in
# tasks.json while the three core spec files for that feature are missing.
#
# Reads the hook JSON from stdin (PreToolUse hooks receive no arguments).
# State is read from tasks.json and the tool input, never from spec file content.
# Fails open (exit 0 with a warning) when jq is unavailable.
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TASKS_FILE="$PROJECT_DIR/tasks.json"

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
  echo "SDD hook warning: jq not found; cannot validate spec files before status change." >&2
  exit 0
fi

# Only act on edits that target tasks.json.
# tr -d '\r': jq on Windows emits CRLF; a stray \r breaks pattern matching.
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null | tr -d '\r' || true)
case "$FILE_PATH" in
  */tasks.json|tasks.json) ;;
  *) exit 0 ;;
esac

# Does the proposed content move anything to spec_ready?
# Covers Write (.tool_input.content) and Edit (.tool_input.new_string).
NEW_CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null || true)
if [[ -z "$NEW_CONTENT" ]] || ! echo "$NEW_CONTENT" | grep -q 'spec_ready'; then
  exit 0
fi

if [[ ! -f "$TASKS_FILE" ]]; then
  exit 0
fi

# For every task that is (or is being moved to) spec_ready, require the three
# core spec files. Slugs are read from the existing tasks.json; for a full-file
# Write we also try to parse slugs out of the proposed content itself.
SLUGS=$(jq -r '.tasks[]? | select(.sdd == true) | .slug // empty' "$TASKS_FILE" 2>/dev/null | tr -d '\r' || true)
if echo "$NEW_CONTENT" | jq -e . >/dev/null 2>&1; then
  SLUGS_NEW=$(echo "$NEW_CONTENT" | jq -r '.tasks[]? | select(.status == "spec_ready") | .slug // empty' 2>/dev/null | tr -d '\r' || true)
  SLUGS=$(printf '%s\n%s\n' "$SLUGS" "$SLUGS_NEW" | sort -u)
fi

missing=0
for slug in $SLUGS; do
  [[ -z "$slug" ]] && continue
  # Only enforce for tasks that the new content marks as spec_ready, when we
  # can tell; otherwise check every SDD task slug mentioned alongside spec_ready.
  if echo "$NEW_CONTENT" | jq -e . >/dev/null 2>&1; then
    STATUS=$(echo "$NEW_CONTENT" | jq -r --arg slug "$slug" '.tasks[]? | select(.slug == $slug) | .status // empty' 2>/dev/null | head -1 | tr -d '\r')
    [[ "$STATUS" != "spec_ready" ]] && continue
  fi
  SPEC_DIR="$PROJECT_DIR/specs/$slug"
  for file in requirements.md design.md tasks.md; do
    if [[ ! -s "$SPEC_DIR/$file" ]]; then
      echo "Cannot move '$slug' to spec_ready: missing $SPEC_DIR/$file" >&2
      missing=1
    fi
  done
done

if [[ "$missing" -ne 0 ]]; then
  exit 2
fi

exit 0
