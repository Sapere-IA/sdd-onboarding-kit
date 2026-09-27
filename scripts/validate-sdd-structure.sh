#!/usr/bin/env bash
set -euo pipefail

# Harness-neutral structure validator.
#   SDD_HARNESS_DIR  primary harness directory (default .claude; e.g. .cursor,
#                    .opencode, .agents, or .codex for Codex).
#   SDD_SKILLS_DIR   skills directory when it differs from $SDD_HARNESS_DIR/skills
#                    (Codex: .agents/skills).
#   SDD_PROJECT_DIR  project root (falls back to CLAUDE_PROJECT_DIR,
#                    CURSOR_PROJECT_DIR, then the current directory).
PROJECT_DIR="${SDD_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-$(pwd)}}}"
cd "$PROJECT_DIR"

HARNESS_DIR="${SDD_HARNESS_DIR:-.claude}"
HARNESS_DIR="${HARNESS_DIR%/}"
SKILLS_DIR="${SDD_SKILLS_DIR:-$HARNESS_DIR/skills}"
SKILLS_DIR="${SKILLS_DIR%/}"
AGENTS_DIR="$HARNESS_DIR/agents"

missing=0

check_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "Missing file: $path" >&2
    missing=1
  fi
}

check_dir() {
  local path="$1"
  if [[ ! -d "$path" ]]; then
    echo "Missing directory: $path" >&2
    missing=1
  fi
}

# Instruction file: AGENTS.md is canonical; a legacy CLAUDE.md-only install is accepted.
if [[ ! -f "AGENTS.md" && ! -f "CLAUDE.md" ]]; then
  echo "Missing file: AGENTS.md (or a legacy CLAUDE.md)" >&2
  missing=1
fi
# When both exist, CLAUDE.md must be the import stub.
if [[ -f "AGENTS.md" && -f "CLAUDE.md" ]] && ! head -n 1 "CLAUDE.md" | grep -q '^@AGENTS.md'; then
  echo "CLAUDE.md exists alongside AGENTS.md but does not start with '@AGENTS.md' (expected the import stub)." >&2
  missing=1
fi
check_file "decisions/answers.md"
check_dir "$AGENTS_DIR"
# Agent files: markdown in most harnesses, .toml in Codex.
check_agent() {
  local name="$1"
  if [[ ! -f "$AGENTS_DIR/$name.md" && ! -f "$AGENTS_DIR/$name.toml" && ! -f "$AGENTS_DIR/$name/agent.md" ]]; then
    echo "Missing agent: $AGENTS_DIR/$name.md (or .toml)" >&2
    missing=1
  fi
}
check_agent "leader"
check_agent "spec-author"
check_agent "implementer"
check_agent "reviewer"
check_dir "$SKILLS_DIR/sdd-workflow"
check_file "$SKILLS_DIR/sdd-workflow/SKILL.md"
check_file "$SKILLS_DIR/sdd-workflow/workflow.md"
check_file "$SKILLS_DIR/sdd-workflow/spec-format.md"
check_file "$SKILLS_DIR/sdd-workflow/task-state-machine.md"
check_file "$SKILLS_DIR/sdd-workflow/review-checklist.md"
check_dir "$SKILLS_DIR/sdd-workflow/templates"
check_file "$SKILLS_DIR/sdd-workflow/templates/spec.css"
check_file "$SKILLS_DIR/sdd-workflow/templates/spec.js"
check_file "$SKILLS_DIR/sdd-workflow/templates/spec-shell.html.template"
check_file "$SKILLS_DIR/sdd-workflow/templates/requirements.md.template"
check_file "$SKILLS_DIR/sdd-workflow/templates/design.md.template"
check_file "$SKILLS_DIR/sdd-workflow/templates/tasks.md.template"
check_file "$SKILLS_DIR/sdd-workflow/templates/review.md.template"
check_dir "specs"
check_file "tasks.json"
check_file "history.md"
check_dir "scripts"
check_file "scripts/run-tests.sh"
check_file "scripts/run-lint.sh"

# Exactly one spec renderer must be installed (Node or Python).
if [[ ! -f "scripts/render-spec.mjs" && ! -f "scripts/render_spec.py" ]]; then
  echo "Missing spec renderer: scripts/render-spec.mjs or scripts/render_spec.py" >&2
  missing=1
fi

if [[ "$missing" -ne 0 ]]; then
  echo "SDD structure validation failed." >&2
  exit 1
fi

# Check for unresolved {{PLACEHOLDER}} tokens in the instruction files and the
# harness directories. Any per-instance template file (*.template under a
# templates/ directory) is exempt: its placeholders are instantiated per
# feature/commit/PR, not during onboarding. This covers the sdd-workflow spec
# templates AND pack templates such as <skills>/git-discipline/templates/*.template.
# The literal {{PLACEHOLDER}} token is also exempt: skill docs use it as the
# generic name for the placeholder convention, not as a real placeholder.
scan_targets=()
for t in AGENTS.md CLAUDE.md "$HARNESS_DIR" "$SKILLS_DIR"; do
  [[ -e "$t" ]] && scan_targets+=("$t")
done
unresolved=$(grep -Rn "{{[A-Z0-9_]*}}" "${scan_targets[@]}" 2>/dev/null \
  | grep -v "/sdd-workflow/templates/" \
  | grep -vE "/templates/[^/]+\.template:" \
  | grep -v "{{PLACEHOLDER}}" || true)
if [[ -n "$unresolved" ]]; then
  echo "$unresolved" >&2
  echo "Unresolved template placeholders found in the instruction files or the harness directory ($HARNESS_DIR)." >&2
  exit 1
fi

# Check for unresolved {{PLACEHOLDER}} tokens in instantiated spec sources
# (markdown is the source of truth; rendered .html files are gitignored artifacts).
if find specs -name "*.md" -exec grep -l "{{[A-Z0-9_]*}}" {} + 2>/dev/null | grep -q .; then
  echo "Unresolved template placeholders found in spec markdown files:" >&2
  find specs -name "*.md" -exec grep -l "{{[A-Z0-9_]*}}" {} + 2>/dev/null >&2
  exit 1
fi

# Every spec markdown source must start with YAML frontmatter.
missing_fm=$(find specs -name "*.md" ! -name "README.md" 2>/dev/null | while read -r f; do
  head -n 1 "$f" | grep -q '^---$' || echo "$f"
done)
if [[ -n "$missing_fm" ]]; then
  echo "Spec markdown files missing YAML frontmatter:" >&2
  echo "$missing_fm" >&2
  exit 1
fi

# Validate tasks.json against its own state machine. State is read from JSON
# only — spec files are never parsed. Skipped with a warning if jq is
# unavailable.
if command -v jq >/dev/null 2>&1; then
  if ! jq -e . tasks.json >/dev/null 2>&1; then
    echo "tasks.json is not valid JSON." >&2
    exit 1
  fi

  INVALID_STATUSES=$(jq -r '
    (.state_machine // ["pending","spec_draft","spec_ready","human_approved","in_progress","review","done","rejected","blocked"]) as $sm
    | .tasks[]?
    | select((.status // "") as $s | ($sm | index($s)) == null)
    | "\(.id // "?"): invalid status \"\(.status // "missing")\""
  ' tasks.json)
  if [[ -n "$INVALID_STATUSES" ]]; then
    echo "tasks.json contains statuses outside the configured state machine:" >&2
    echo "$INVALID_STATUSES" >&2
    exit 1
  fi

  MISSING_APPROVALS=$(jq -r '
    ["human_approved","in_progress","review","done"] as $approved_states
    | .tasks[]?
    | select((.approval.required // false) == true)
    | select((.status // "") as $s | ($approved_states | index($s)) != null)
    | select((.approval.approved_by // null) == null)
    | "\(.id // "?"): status \"\(.status)\" requires approval but approval.approved_by is null"
  ' tasks.json)
  if [[ -n "$MISSING_APPROVALS" ]]; then
    echo "tasks.json contains approved/in-progress tasks without recorded human approval:" >&2
    echo "$MISSING_APPROVALS" >&2
    exit 1
  fi
else
  echo "Warning: jq not found; skipped tasks.json state-machine validation." >&2
fi

echo "SDD structure validation passed."
