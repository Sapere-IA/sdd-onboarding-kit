#!/usr/bin/env bash
set -euo pipefail

# Targeted validation hook (example, disabled by default).
#
# After an edit, map the changed file to a targeted check instead of the
# full suite: frontend changes -> frontend checks, backend changes ->
# backend tests, schema changes -> migration checks. Wired to the post-edit
# event of the harness (PostToolUse with matcher Edit|Write in Claude
# Code/Codex, afterFileEdit in Cursor, ...). Never blocks the edit.
#
# Modes (VALIDATION_MODE environment variable, default below):
#   suggest (default) - advisory: inject a reminder naming the matching
#                       check. Suggested once per session per command.
#   run               - execute the matching check synchronously and
#                       report the result. Slow checks will delay the
#                       session; keep the mapped commands fast and
#                       side-effect-free (this hook is classified
#                       advisory because the edit is never blocked, but a
#                       mapped command that rewrites files would make it
#                       mutating — do not map formatters or generators
#                       here without explicit opt-in).

VALIDATION_MODE="${VALIDATION_MODE:-suggest}"

# "path-pattern (extended regex) :: command" — first match wins.
# EXAMPLES ONLY: replace patterns and commands with the project's real
# ones during onboarding. Never map a command that was not confirmed.
RULES=(
  '^(src/)?(frontend|components|pages|ui)/|\.(tsx|jsx|css|scss)$ :: npm run test:frontend'
  '^(src/)?(backend|server|api)/ :: npm run test:backend'
  '^(db/)?(migrations|schema)/ :: npm run check:migrations'
)

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

if ! command -v jq >/dev/null 2>&1; then
  echo "SDD hook warning: jq not found; targeted validation skipped." >&2
  exit 0
fi

file_path="$sdd_file"
[ -n "$file_path" ] || exit 0

rel_path="${file_path#"$sdd_project_dir"/}"

cmd=""
for rule in "${RULES[@]}"; do
  pattern="${rule%% :: *}"
  candidate="${rule##* :: }"
  if printf '%s' "$rel_path" | grep -Eq "$pattern"; then
    cmd="$candidate"
    break
  fi
done
[ -n "$cmd" ] || exit 0

if [ "$VALIDATION_MODE" = "run" ]; then
  result="passed"
  output=$(cd "$sdd_project_dir" && bash -c "$cmd" 2>&1) || result="FAILED"
  tail_output=$(printf '%s' "$output" | tail -n 20)
  sdd_context "Targeted check for \`$rel_path\`: \`$cmd\` $result.
$tail_output"
  exit 0
fi

# suggest mode: once per session per command.
cmd_hash=$(printf '%s' "$cmd" | cksum | awk '{print $1}')
state_dir="${TMPDIR:-/tmp}/sdd-targeted-validation"
mkdir -p "$state_dir"
state_file="$state_dir/${sdd_session}-${cmd_hash}.suggested"
[ -f "$state_file" ] && exit 0
: > "$state_file"

sdd_context "\`$rel_path\` changed. The targeted check for this area is \`$cmd\` — consider running it before moving on (cheaper than the full suite)."
exit 0
