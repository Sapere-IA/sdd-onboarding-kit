#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

echo "SDD init check"
echo "Project: $PROJECT_DIR"

required=("CLAUDE.md" ".claude/agents" ".claude/skills/sdd-workflow" "specs" "tasks.json" "history.md")

missing=0
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
