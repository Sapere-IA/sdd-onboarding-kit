#!/usr/bin/env bash
set -euo pipefail

# Example hook script (PostToolUse on file edits; never blocks).
# Runs the project's test script after an edit. Harness-neutral: the project
# directory comes from SDD_PROJECT_DIR / CLAUDE_PROJECT_DIR / CURSOR_PROJECT_DIR,
# the hook payload's cwd, or the current directory.

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
sdd_event="${sdd_event:-PostToolUse}"
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

cd "$sdd_project_dir"

if [[ -x "./scripts/run-tests.sh" ]]; then
  ./scripts/run-tests.sh
else
  echo "SDD hook warning: ./scripts/run-tests.sh not found or not executable." >&2
fi
