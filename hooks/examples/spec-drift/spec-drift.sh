#!/usr/bin/env bash
set -euo pipefail

# Spec-drift hook (example, disabled by default).
#
# Detects edits outside the approved task's scope. The scope is the
# optional "scope" array of glob patterns on the active task(s) in
# tasks.json (filled by the spec-author from the design's files-to-change
# list when the spec is approved). Wired to the pre-edit event of the
# harness (PreToolUse with matcher Edit|Write in Claude Code/Codex, and the
# equivalents in hooks/settings-snippets.md).
#
# Strictness (DRIFT_MODE environment variable, default below):
#   warn (default) - allow the edit but tell the agent it drifted from the
#                    approved scope.
#   block          - deny the edit with the reason; the fix is to update
#                    the design/spec and the task's scope first.
#
# Fails open (allows, no output) when jq, tasks.json, active approved
# tasks, or scope data are missing — no scope recorded means nothing to
# enforce.

DRIFT_MODE="${DRIFT_MODE:-warn}"

# ---- SDD hook adapter (identical in every kit hook; contract: hooks/hooks-policy.md) ----
# Reads the harness payload from stdin (Claude Code, Codex, Cursor and Antigravity shapes) or from
# explicit SDD_HOOK_* variables / a file-path argument, and exposes:
#   sdd_project_dir, sdd_file, sdd_command, sdd_content, sdd_tool, sdd_session, sdd_event
# Output helpers: sdd_block "<reason>" (deny + exit) and sdd_context "<text>" (advisory), formatted
# per SDD_HOOK_OUTPUT: exit (default: Claude Code / Codex / Cursor), cursor, antigravity, plain.
sdd_input=""
if [ ! -t 0 ]; then sdd_input="$(cat)"; fi
sdd_jq() {  # $1 = jq filter; prints the first line of the result, or nothing; never fails
  local out=""
  if [ -n "$sdd_input" ] && command -v jq >/dev/null 2>&1; then
    out="$(printf '%s' "$sdd_input" | jq -r "$1" 2>/dev/null | tr -d '\r' | head -n 1)" || true
  fi
  printf '%s' "$out"
  return 0
}
sdd_jq_multi() {  # like sdd_jq but keeps every line (file contents)
  local out=""
  if [ -n "$sdd_input" ] && command -v jq >/dev/null 2>&1; then
    out="$(printf '%s' "$sdd_input" | jq -r "$1" 2>/dev/null | tr -d '\r')" || true
  fi
  printf '%s' "$out"
  return 0
}
sdd_project_dir="${SDD_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-}}}"
[ -n "$sdd_project_dir" ] || sdd_project_dir="$(sdd_jq '.cwd // .workspacePaths[0]? // empty')"
[ -n "$sdd_project_dir" ] || sdd_project_dir="$(pwd)"
sdd_file="${SDD_HOOK_FILE:-${1:-}}"
[ -n "$sdd_file" ] || sdd_file="$(sdd_jq '.tool_input.file_path // .tool_input.notebook_path // .tool_input.path // .file_path // .toolCall.args.TargetFile // empty')"
sdd_command="${SDD_HOOK_COMMAND:-}"
[ -n "$sdd_command" ] || sdd_command="$(sdd_jq '.tool_input.command // .command // .toolCall.args.CommandLine // empty')"
sdd_content="${SDD_HOOK_CONTENT:-}"
[ -n "$sdd_content" ] || sdd_content="$(sdd_jq_multi '.tool_input.content // .tool_input.new_string // .content // .toolCall.args.CodeContent // .toolCall.args.ReplacementContent // (if ((.edits? // null) | type) == "array" and ((.edits | length) > 0) then (.edits | map(.new_string // "") | join("\n")) else empty end)')"
sdd_tool="${SDD_HOOK_TOOL:-}"
[ -n "$sdd_tool" ] || sdd_tool="$(sdd_jq '.tool_name // .toolCall.name // empty')"
sdd_session="${SDD_HOOK_SESSION:-}"
[ -n "$sdd_session" ] || sdd_session="$(sdd_jq '.session_id // .conversationId // .conversation_id // empty')"
sdd_session="${sdd_session:-no-session}"
sdd_event="${SDD_HOOK_EVENT:-}"
[ -n "$sdd_event" ] || sdd_event="$(sdd_jq '.hook_event_name // empty')"
sdd_event="${sdd_event:-PreToolUse}"
# shellcheck disable=SC2329  # helper may be unused in a given hook
sdd_block() {  # deny with a reason, then exit
  case "${SDD_HOOK_OUTPUT:-exit}" in
    antigravity) jq -n --arg r "$1" '{decision: "deny", reason: $r}'; exit 0 ;;
    cursor) jq -n --arg r "$1" '{permission: "deny", user_message: $r, agent_message: $r}'; exit 0 ;;
    *) printf '%s\n' "$1" >&2; exit 2 ;;
  esac
}
# shellcheck disable=SC2329  # helper may be unused in a given hook
sdd_context() {  # advisory text for the agent; never blocks
  case "${SDD_HOOK_OUTPUT:-exit}" in
    exit) if command -v jq >/dev/null 2>&1; then
            jq -n --arg e "$sdd_event" --arg r "$1" '{hookSpecificOutput: {hookEventName: $e, additionalContext: $r}}'
          else printf '%s\n' "$1"; fi ;;
    cursor) jq -n --arg r "$1" '{permission: "allow", agent_message: $r}' ;;
    *) printf '%s\n' "$1" >&2 ;;
  esac
}
# ---- end SDD hook adapter ----

tasks_file="$sdd_project_dir/tasks.json"

[ -f "$tasks_file" ] || exit 0

if ! command -v jq >/dev/null 2>&1; then
  echo "SDD hook warning: jq not found; spec-drift check skipped." >&2
  exit 0
fi

file_path="$sdd_file"
[ -n "$file_path" ] || exit 0

rel_path="${file_path#"$sdd_project_dir"/}"

# Spec and harness files are always in scope: specs evolve during work and
# the harness must stay editable.
case "$rel_path" in
  specs/*|tasks.json|history.md|decisions/*|AGENTS.md|CLAUDE.md|.claude/*|.codex/*|.cursor/*|.opencode/*|.agents/*)
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
  sdd_block "$reason"
fi

sdd_context "Warning — $reason"
exit 0
