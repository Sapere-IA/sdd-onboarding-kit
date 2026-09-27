#!/usr/bin/env bash
set -euo pipefail

# Example hook script (PreToolUse on file edits; exit 2 blocks).
# Adapt this script to the project's real task storage and source directories.
# This script assumes local tasks.json and blocks edits to implementation files
# when there is an active SDD task without human approval.
# Edits to spec files (specs/, tasks.json, history.md, etc.) are always allowed.
#
# Harness-neutral: works from the hook payload of Claude Code, Codex, Cursor
# and Antigravity, or with the file path as the first argument / SDD_HOOK_FILE.
#
# KNOWN LIMITATION (deliberate, to keep the example simple): the guard is
# project-wide, not per-task. If ANY sdd:true task is pending/spec_draft/
# spec_ready, ALL implementation edits are blocked — including work on a
# different, already-approved task. If your team runs several SDD tasks in
# parallel, adapt the jq filter to scope the check to the task being worked on
# (e.g. by branch name or an ACTIVE_TASK env var).

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

TASKS_FILE="$sdd_project_dir/tasks.json"

if [[ ! -f "$TASKS_FILE" ]]; then
  exit 0
fi

FILE_PATH="$sdd_file"

# Allow edits to SDD spec/config files regardless of task status.
# These are the files that must be editable during spec_draft and spec_ready phases.
# The harness directory (.claude, .codex, .cursor, .opencode, .agents) is always allowed.
case "$FILE_PATH" in
  */specs/*|*/tasks.json|*/history.md|*/open-questions.md|*/requirements.md|\
  */design.md|*/tasks.md|*/assumptions.md|*/acceptance-tests.md|*/review.md|\
  */.claude/*|*/.codex/*|*/.cursor/*|*/.opencode/*|*/.agents/*|*/AGENTS.md|*/CLAUDE.md)
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
  sdd_block "Blocked by SDD policy: there is an SDD task awaiting spec approval. File attempted: ${FILE_PATH:-unknown}. Only spec files (specs/, tasks.json, history.md, the harness directory) are allowed until status is human_approved or in_progress."
fi

exit 0
