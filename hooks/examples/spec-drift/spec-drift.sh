#!/usr/bin/env bash
set -euo pipefail

# Spec-drift hook (example, disabled by default).
#
# Detects edits outside the approved task's scope. The scope is the
# optional "scope" array of glob patterns on the active task(s) in
# tasks.json (filled by the spec-author from the design's files-to-change
# list when the spec is approved). Wired to PreToolUse with matcher
# Edit|Write.
#
# Strictness (DRIFT_MODE environment variable, default below):
#   warn (default) - allow the edit but tell Claude it drifted from the
#                    approved scope.
#   block          - deny the edit with the reason; the fix is to update
#                    the design/spec and the task's scope first.
#
# Fails open (allows, no output) when jq, tasks.json, active approved
# tasks, or scope data are missing — no scope recorded means nothing to
# enforce.

DRIFT_MODE="${DRIFT_MODE:-warn}"

project_dir="${CLAUDE_PROJECT_DIR:-$(pwd)}"
tasks_file="$project_dir/tasks.json"

[ -f "$tasks_file" ] || exit 0

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  echo "SDD hook warning: jq not found; spec-drift check skipped." >&2
  exit 0
fi

# tr -d '\r': jq on Windows emits CRLF; a stray \r breaks glob matching.
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' | tr -d '\r')
[ -n "$file_path" ] || exit 0

rel_path="${file_path#"$project_dir"/}"

# Spec and harness files are always in scope: specs evolve during work and
# the harness must stay editable.
case "$rel_path" in
  specs/*|tasks.json|history.md|decisions/*|.claude/*)
    exit 0
    ;;
esac

# Union of scope globs across active approved SDD tasks.
globs=$(jq -r '
  .tasks[]?
  | select(.sdd == true and (.status == "human_approved" or .status == "in_progress"))
  | (.scope // [])[]' "$tasks_file" 2>/dev/null | tr -d '\r' || true)
[ -n "$globs" ] || exit 0

matched="no"
while IFS= read -r glob; do
  [ -n "$glob" ] || continue
  # shellcheck disable=SC2254  # $glob is intentionally an unquoted pattern
  case "$rel_path" in
    $glob) matched="yes"; break ;;
  esac
done <<EOF
$globs
EOF
[ "$matched" = "yes" ] && exit 0

globs_list=$(printf '%s' "$globs" | tr '\n' ' ')
reason="Spec drift: \`$rel_path\` is outside the approved scope of the active SDD task(s). Approved scope globs: $globs_list. If this file is genuinely needed, update the design/spec and the task's scope array in tasks.json first."

if [ "$DRIFT_MODE" = "block" ]; then
  jq -n --arg r "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
fi

jq -n --arg r "$reason" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("Warning — " + $r)
  }
}'
exit 0
