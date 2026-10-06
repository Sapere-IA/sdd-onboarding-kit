# render-spec.ps1 — bundle SDD markdown documents into a self-contained HTML page (Windows).
#
# Usage:
#   pwsh scripts/render-spec.ps1 <spec-dir | file.md> [more paths...] [-Assets DIR]
#
#   - A directory (a feature spec folder) becomes ONE page, <dir>/spec.html,
#     holding every *.md file in it that starts with YAML frontmatter
#     (feedback.md excluded): overview, one tab per document, per-item feedback.
#   - A single file (history.md, architecture.md …) becomes <name>.html next to it.
#   - -Assets DIR points at the folder with spec-shell.html.template, spec.css
#     and spec.js. Default: walk up from each path looking for
#     <harness-dir>/skills/sdd-workflow/templates/ ($env:SDD_HARNESS_DIR, .claude,
#     .codex, .cursor, .opencode, .agents), then the kit layout (templates/specs/).
#
# Works with Windows PowerShell 5.1 and PowerShell 7. The markdown is embedded
# verbatim and rendered in the browser by spec.js.
# KEEP IN SYNC with scripts/render-spec.sh.

param(
  [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)]
  [string[]] $Paths,
  [string] $Assets = ''
)

$ErrorActionPreference = 'Stop'
$order = @('requirements', 'open-questions', 'assumptions', 'design', 'tasks', 'acceptance-tests', 'review')
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Find-Assets([string] $start) {
  if ($Assets) {
    if (-not (Test-Path -LiteralPath (Join-Path $Assets 'spec.js'))) { throw "assets not found in $Assets" }
    return (Resolve-Path -LiteralPath $Assets).Path
  }
  $harnessDirs = @()
  if ($env:SDD_HARNESS_DIR) { $harnessDirs += $env:SDD_HARNESS_DIR }
  $harnessDirs += '.claude', '.codex', '.cursor', '.opencode', '.agents'
  $dir = (Resolve-Path -LiteralPath $start).Path
  while ($dir) {
    foreach ($h in $harnessDirs) {
      $candidate = Join-Path (Join-Path (Join-Path (Join-Path $dir $h) 'skills') 'sdd-workflow') 'templates'
      if (Test-Path -LiteralPath (Join-Path $candidate 'spec.js')) { return $candidate }
    }
    $parent = Split-Path -Parent $dir
    if (-not $parent -or $parent -eq $dir) { break }
    $dir = $parent
  }
  $kit = Join-Path (Join-Path (Join-Path $PSScriptRoot '..') 'templates') 'specs'
  if (Test-Path -LiteralPath (Join-Path $kit 'spec.js')) { return (Resolve-Path -LiteralPath $kit).Path }
  throw "assets not found for $start (use -Assets DIR)"
}

function Safe([string] $s) { return ($s -replace '[^A-Za-z0-9._-]', '-') }

function Read-Text([string] $path) { return [System.IO.File]::ReadAllText($path, $utf8) }

function Test-Frontmatter([string] $path) {
  $first = Get-Content -LiteralPath $path -TotalCount 1 -Encoding UTF8
  return ($null -ne $first -and $first.StartsWith('---'))
}

# "</script" is escaped so a document cannot close its own <script> block; spec.js reverses it.
function Embed([string] $path) {
  $text = (Read-Text $path) -replace '(?i)</script', '<\/script'
  return "<script type=`"text/markdown`" data-file=`"$(Safe (Split-Path -Leaf $path))`">`n$text`n</script>`n"
}

function Assemble([string] $assetsDir, [string] $mode, [string] $slug, [string] $sources, [string] $out) {
  $shellPath = Join-Path $assetsDir 'spec-shell.html.template'
  if (-not (Test-Path -LiteralPath $shellPath)) { throw "missing $shellPath" }
  $shell = Read-Text $shellPath
  if (-not $shell.Contains('{{SOURCES}}')) {
    throw "$shellPath predates SDD kit 3.0.0 (no {{SOURCES}}); update the harness (sdd-update skill)"
  }
  # String.Replace is literal: no regex or '$' substitution surprises in the inlined files.
  $html = $shell.Replace('{{TITLE}}', $slug).Replace('{{SLUG}}', $slug).Replace('{{MODE}}', $mode)
  $html = $html.Replace('{{CSS}}', (Read-Text (Join-Path $assetsDir 'spec.css')))
  $html = $html.Replace('{{JS}}', (Read-Text (Join-Path $assetsDir 'spec.js')))
  $html = $html.Replace('{{SOURCES}}', $sources)
  [System.IO.File]::WriteAllText($out, $html, $utf8)
}

$status = 0
foreach ($path in $Paths) {
  try {
    if (Test-Path -LiteralPath $path -PathType Container) {
      $dir = (Resolve-Path -LiteralPath $path).Path
      $assetsDir = Find-Assets $dir
      $sb = New-Object System.Text.StringBuilder
      $count = 0
      foreach ($name in $order) {
        $f = Join-Path $dir "$name.md"
        if ((Test-Path -LiteralPath $f) -and (Test-Frontmatter $f)) { [void]$sb.Append((Embed $f)); $count++ }
      }
      Get-ChildItem -LiteralPath $dir -Filter '*.md' -File | Sort-Object Name | ForEach-Object {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        if (($order -notcontains $base) -and $base -ne 'feedback' -and (Test-Frontmatter $_.FullName)) {
          [void]$sb.Append((Embed $_.FullName)); $count++
        }
      }
      if ($count -eq 0) { [Console]::Error.WriteLine("skip (no frontmatter documents): $path"); continue }
      $out = Join-Path $dir 'spec.html'
      Assemble $assetsDir 'spec' (Safe (Split-Path -Leaf $dir)) $sb.ToString() $out
      Write-Output "rendered $count documents -> $out"
    } elseif (Test-Path -LiteralPath $path -PathType Leaf) {
      $file = (Resolve-Path -LiteralPath $path).Path
      $assetsDir = Find-Assets (Split-Path -Parent $file)
      $out = [System.IO.Path]::ChangeExtension($file, '.html')
      Assemble $assetsDir 'single' (Safe ([System.IO.Path]::GetFileNameWithoutExtension($file))) (Embed $file) $out
      Write-Output "rendered $(Split-Path -Leaf $file) -> $out"
    } else {
      [Console]::Error.WriteLine("skip (not found): $path")
      $status = 1
    }
  } catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    $status = 1
  }
}
exit $status
