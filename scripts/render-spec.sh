#!/bin/sh
# render-spec.sh — bundle SDD markdown documents into a self-contained HTML page.
#
# Usage:
#   sh scripts/render-spec.sh <spec-dir | file.md> [more paths...] [--assets DIR]
#
#   - A directory (a feature spec folder) becomes ONE page, <dir>/spec.html,
#     holding every *.md file in it that starts with YAML frontmatter
#     (feedback.md excluded): overview, one tab per document, per-item feedback.
#   - A single file (history.md, architecture.md …) becomes <name>.html next to it.
#   - --assets DIR points at the folder with spec-shell.html.template, spec.css
#     and spec.js. Default: walk up from each path looking for
#     <harness-dir>/skills/sdd-workflow/templates/ ($SDD_HARNESS_DIR, .claude,
#     .codex, .cursor, .opencode, .agents), then the kit layout (templates/specs/).
#
# No runtime needed (POSIX sh, sed, awk): the markdown is embedded verbatim and
# rendered in the browser by spec.js. Conventions: skills/sdd-workflow/spec-format.md.
# KEEP IN SYNC with scripts/render-spec.ps1.

set -eu

usage() {
  echo "Usage: sh render-spec.sh <spec-dir | file.md> [...] [--assets DIR]" >&2
  exit 1
}

script_dir=$(cd "$(dirname "$0")" && pwd)
assets=""

# First pass: options.
prev=""
for arg in "$@"; do
  if [ "$prev" = "--assets" ]; then assets=$arg; fi
  case "$arg" in -h|--help) usage ;; esac
  prev=$arg
done
[ $# -gt 0 ] || usage

# Find the assets folder for a path (file or directory).
find_assets() {
  if [ -n "$assets" ]; then
    [ -f "$assets/spec.js" ] || { echo "assets not found in $assets" >&2; return 1; }
    printf '%s\n' "$assets"
    return 0
  fi
  dir=$(cd "$1" && pwd)
  while :; do
    for h in ${SDD_HARNESS_DIR:-} .claude .codex .cursor .opencode .agents; do
      candidate="$dir/$h/skills/sdd-workflow/templates"
      if [ -f "$candidate/spec.js" ]; then printf '%s\n' "$candidate"; return 0; fi
    done
    parent=$(dirname "$dir")
    [ "$parent" = "$dir" ] && break
    dir=$parent
  done
  if [ -f "$script_dir/../templates/specs/spec.js" ]; then
    (cd "$script_dir/../templates/specs" && pwd)
    return 0
  fi
  echo "assets not found for $1 (use --assets DIR)" >&2
  return 1
}

# Keep only characters that are safe in an HTML attribute and an awk replacement.
safe() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-'; }

has_frontmatter() { head -n 1 "$1" | grep -q '^---'; }

# Append one markdown file to the sources buffer. "</script" is escaped so the
# document cannot close its own <script> block; spec.js reverses it.
embed() {
  {
    printf '<script type="text/markdown" data-file="%s">\n' "$(safe "$(basename "$1")")"
    sed 's#</[sS][cC][rR][iI][pP][tT]#<\\/script#g' "$1"
    printf '\n</script>\n'
  } >> "$sources"
}

# Fill the shell template: {{CSS}}, {{JS}}, {{SOURCES}} lines are replaced by
# file contents; {{TITLE}}, {{SLUG}}, {{MODE}} by sanitized values.
assemble() { # assets_dir mode slug out
  shell="$1/spec-shell.html.template"
  [ -f "$shell" ] || { echo "missing $shell" >&2; return 1; }
  if ! grep -q '{{SOURCES}}' "$shell"; then
    echo "$shell predates SDD kit 3.0.0 (no {{SOURCES}}); update the harness (sdd-update skill)" >&2
    return 1
  fi
  awk -v css="$1/spec.css" -v js="$1/spec.js" -v src="$sources" -v mode="$2" -v slug="$3" '
    function cat(f,   l) { while ((getline l < f) > 0) print l; close(f) }
    /\{\{CSS\}\}/     { cat(css); next }
    /\{\{JS\}\}/      { cat(js); next }
    /\{\{SOURCES\}\}/ { cat(src); next }
    { gsub(/\{\{TITLE\}\}/, slug); gsub(/\{\{SLUG\}\}/, slug); gsub(/\{\{MODE\}\}/, mode); print }
  ' "$shell" > "$4.tmp"
  mv "$4.tmp" "$4"
}

sources=$(mktemp "${TMPDIR:-/tmp}/sdd-render.XXXXXX")
trap 'rm -f "$sources"' EXIT

# Spec documents in tab order; any other frontmatter document follows.
ORDER="requirements open-questions assumptions design tasks acceptance-tests review"

status=0
skip=""
for path in "$@"; do
  if [ "$skip" = 1 ]; then skip=""; continue; fi
  if [ "$path" = "--assets" ]; then skip=1; continue; fi
  : > "$sources"
  if [ -d "$path" ]; then
    dir=${path%/}
    a=$(find_assets "$dir") || { status=1; continue; }
    count=0
    for name in $ORDER; do
      f="$dir/$name.md"
      if [ -f "$f" ] && has_frontmatter "$f"; then embed "$f"; count=$((count + 1)); fi
    done
    for f in "$dir"/*.md; do
      [ -f "$f" ] || continue
      base=$(basename "$f" .md)
      case " $ORDER feedback " in *" $base "*) continue ;; esac
      if has_frontmatter "$f"; then embed "$f"; count=$((count + 1)); fi
    done
    if [ "$count" -eq 0 ]; then echo "skip (no frontmatter documents): $path" >&2; continue; fi
    out="$dir/spec.html"
    assemble "$a" spec "$(safe "$(basename "$(cd "$dir" && pwd)")")" "$out" || { status=1; continue; }
    echo "rendered $count documents -> $out"
  elif [ -f "$path" ]; then
    a=$(find_assets "$(dirname "$path")") || { status=1; continue; }
    embed "$path"
    out="${path%.md}.html"
    assemble "$a" single "$(safe "$(basename "$path" .md)")" "$out" || { status=1; continue; }
    echo "rendered $(basename "$path") -> $out"
  else
    echo "skip (not found): $path" >&2
    status=1
  fi
done
exit $status
