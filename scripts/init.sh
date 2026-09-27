#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${SDD_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-$(pwd)}}}"
cd "$PROJECT_DIR"

# SDD_HARNESS_DIR: primary harness directory (default .claude); SDD_SKILLS_DIR
# when skills live elsewhere (Codex: .agents/skills).
HARNESS_DIR="${SDD_HARNESS_DIR:-.claude}"
HARNESS_DIR="${HARNESS_DIR%/}"
SKILLS_DIR="${SDD_SKILLS_DIR:-$HARNESS_DIR/skills}"

echo "SDD init check"
echo "Project: $PROJECT_DIR"

required=("$HARNESS_DIR/agents" "$SKILLS_DIR/sdd-workflow" "specs" "tasks.json" "history.md")

missing=0
if [[ ! -e "AGENTS.md" && ! -e "CLAUDE.md" ]]; then
  echo "Missing: AGENTS.md (or a legacy CLAUDE.md)" >&2
  missing=1
fi
for path in "${required[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Missing: $path" >&2
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo "SDD init failed: required files are missing." >&2
  exit 1
fi

echo "SDD init check passed."
