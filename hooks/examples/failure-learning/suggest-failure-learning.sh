#!/usr/bin/env bash
set -euo pipefail

# Advisory-only failure-learning hook (example, disabled by default).
#
# Watches validation-style shell commands; when the same command fails more
# than once in a session, it injects a reminder suggesting the
# failure-learning skill. It NEVER writes memory or project files — its only
# side effect is a counter file under the system temp directory. Any memory
# write must go through the skill's mandatory confirmation prompt.
#
# Wired to the post-shell event of the harness (PostToolUse with matcher
# Bash in Claude Code/Codex, afterShellExecution in Cursor, PostToolUse with
# matcher run_command in Antigravity).

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
# shellcheck disable=SC2329,SC2317  # helper may be unused in a given hook
sdd_block() {  # deny with a reason, then exit
  case "${SDD_HOOK_OUTPUT:-exit}" in
    antigravity) jq -n --arg r "$1" '{decision: "deny", reason: $r}'; exit 0 ;;
    cursor) jq -n --arg r "$1" '{permission: "deny", user_message: $r, agent_message: $r}'; exit 0 ;;
    *) printf '%s\n' "$1" >&2; exit 2 ;;
  esac
}
# shellcheck disable=SC2329,SC2317  # helper may be unused in a given hook
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

if ! command -v jq >/dev/null 2>&1; then
  echo "SDD hook warning: jq not found; failure-learning suggestion skipped." >&2
  exit 0
fi

# Only shell tools: Claude Code/Codex "Bash", Cursor "Shell", Antigravity
# "run_command"; an empty tool name (Cursor afterShellExecution, explicit
# SDD_HOOK_COMMAND) is accepted when a command is present.
case "$sdd_tool" in
  ""|Bash|PowerShell|Shell|shell|bash|run_command) ;;
  *) exit 0 ;;
esac

cmd="$sdd_command"
[ -n "$cmd" ] || exit 0

# Only watch validation-style commands. Adapt this pattern to the project's
# real test/lint/typecheck commands during onboarding.
watch_pattern='run-tests\.sh|run-lint\.sh|npm (run )?test|npx (vitest|jest)|pytest|go test|cargo test'
printf '%s' "$cmd" | grep -Eq "$watch_pattern" || exit 0

# Failure signal. On PostToolUseFailure the call already failed; otherwise
# look for a failure marker in the tool result (SDD_HOOK_FAILED=1 forces it,
# e.g. from a wrapper that knows the exit code). The result field name and
# shape vary between harnesses and versions — verify against the installed
# version before enabling (see README.md).
if [ "$sdd_event" = "PostToolUseFailure" ] || [ "${SDD_HOOK_FAILED:-0}" = "1" ]; then
  failed="yes"
else
  failed=$(printf '%s' "$sdd_input" | jq -r '
    (.tool_response // .tool_output // .toolResult // {}) as $r
    | if ($r | type) == "string" then (if ($r | test("(?i)(error|failed|exit code [1-9])")) then "yes" else "no" end)
      elif ($r | type) != "object" then "no"
      elif ($r.success? == false) then "yes"
      elif ((($r.exit_code? // $r.exitCode? // 0) | tonumber?) // 0) != 0 then "yes"
      else "no" end' 2>/dev/null | tr -d '\r' || echo "no")
fi
[ "$failed" = "yes" ] || exit 0

cmd_hash=$(printf '%s' "$cmd" | cksum | awk '{print $1}')
state_dir="${TMPDIR:-/tmp}/sdd-failure-learning"
mkdir -p "$state_dir"
state_file="$state_dir/${sdd_session}-${cmd_hash}.count"

count=0
if [ -f "$state_file" ]; then
  count=$(cat "$state_file")
fi
count=$((count + 1))
printf '%s' "$count" > "$state_file"

# Suggest once per session and command: on the second failure only.
[ "$count" -eq 2 ] || exit 0

sdd_context "The command \`$cmd\` has failed more than once in this session. If the repeated failure comes from a wrong assumption or a project convention, consider running the failure-learning skill to propose a reusable lesson. Advisory only: any memory write requires the developer to approve the exact entry text first."
exit 0
