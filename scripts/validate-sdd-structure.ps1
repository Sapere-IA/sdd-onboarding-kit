#!/usr/bin/env pwsh
# PowerShell port of validate-sdd-structure.sh, for Windows-primary teams.
# Requires neither bash nor jq: uses native PowerShell and ConvertFrom-Json.
# Behaviour matches the bash version, except tasks.json state-machine
# validation always runs (there is no jq to be missing), so the harness is
# not quietly weakened on Windows.
#
# Run from the project root, or set SDD_PROJECT_DIR (CLAUDE_PROJECT_DIR and
# CURSOR_PROJECT_DIR are honored too). Harness-neutral: SDD_HARNESS_DIR is the
# primary harness directory (default .claude; e.g. .cursor, .opencode, .agents,
# .codex), SDD_SKILLS_DIR the skills directory when it differs from
# $SDD_HARNESS_DIR/skills (Codex: .agents/skills). Exit code 0 = passed,
# 1 = failed. Works on Windows PowerShell 5.1 and PowerShell 7+.

if ($env:SDD_PROJECT_DIR) { $projectDir = $env:SDD_PROJECT_DIR }
elseif ($env:CLAUDE_PROJECT_DIR) { $projectDir = $env:CLAUDE_PROJECT_DIR }
elseif ($env:CURSOR_PROJECT_DIR) { $projectDir = $env:CURSOR_PROJECT_DIR }
else { $projectDir = (Get-Location).Path }
Set-Location -LiteralPath $projectDir

if ($env:SDD_HARNESS_DIR) { $harnessDir = $env:SDD_HARNESS_DIR.TrimEnd('/', '\') } else { $harnessDir = '.claude' }
if ($env:SDD_SKILLS_DIR) { $skillsDir = $env:SDD_SKILLS_DIR.TrimEnd('/', '\') } else { $skillsDir = "$harnessDir/skills" }
$agentsDir = "$harnessDir/agents"

$missing = $false
function Test-RequiredFile([string]$path) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    [Console]::Error.WriteLine("Missing file: $path"); $script:missing = $true
  }
}
function Test-RequiredDir([string]$path) {
  if (-not (Test-Path -LiteralPath $path -PathType Container)) {
    [Console]::Error.WriteLine("Missing directory: $path"); $script:missing = $true
  }
}

# Instruction file: AGENTS.md is canonical; a legacy CLAUDE.md-only install is accepted.
$hasAgents = Test-Path -LiteralPath 'AGENTS.md' -PathType Leaf
$hasClaude = Test-Path -LiteralPath 'CLAUDE.md' -PathType Leaf
if (-not $hasAgents -and -not $hasClaude) {
  [Console]::Error.WriteLine('Missing file: AGENTS.md (or a legacy CLAUDE.md)'); $missing = $true
}
if ($hasAgents -and $hasClaude) {
  $firstLine = Get-Content -LiteralPath 'CLAUDE.md' -TotalCount 1
  if (-not ($firstLine -match '^@AGENTS\.md')) {
    [Console]::Error.WriteLine("CLAUDE.md exists alongside AGENTS.md but does not start with '@AGENTS.md' (expected the import stub).")
    $missing = $true
  }
}
# Agent files: markdown in most harnesses, .toml in Codex.
function Test-RequiredAgent([string]$name) {
  if (-not (Test-Path -LiteralPath "$agentsDir/$name.md" -PathType Leaf) -and
      -not (Test-Path -LiteralPath "$agentsDir/$name.toml" -PathType Leaf) -and
      -not (Test-Path -LiteralPath "$agentsDir/$name/agent.md" -PathType Leaf)) {
    [Console]::Error.WriteLine("Missing agent: $agentsDir/$name.md (or .toml)"); $script:missing = $true
  }
}
foreach ($a in @('leader', 'spec-author', 'implementer', 'reviewer')) { Test-RequiredAgent $a }

$requiredFiles = @(
  'decisions/answers.md',
  "$skillsDir/sdd-workflow/SKILL.md",
  "$skillsDir/sdd-workflow/workflow.md",
  "$skillsDir/sdd-workflow/spec-format.md",
  "$skillsDir/sdd-workflow/task-state-machine.md",
  "$skillsDir/sdd-workflow/review-checklist.md",
  "$skillsDir/sdd-workflow/templates/spec.css",
  "$skillsDir/sdd-workflow/templates/spec.js",
  "$skillsDir/sdd-workflow/templates/spec-shell.html.template",
  "$skillsDir/sdd-workflow/templates/requirements.md.template",
  "$skillsDir/sdd-workflow/templates/design.md.template",
  "$skillsDir/sdd-workflow/templates/tasks.md.template",
  "$skillsDir/sdd-workflow/templates/review.md.template",
  "$skillsDir/bro/SKILL.md",
  "$skillsDir/closing/SKILL.md",
  'tasks.json',
  'history.md',
  'scripts/run-tests.sh',
  'scripts/run-lint.sh',
  'scripts/render-spec.sh'
)
$requiredDirs = @(
  $agentsDir,
  "$skillsDir/sdd-workflow",
  "$skillsDir/sdd-workflow/templates",
  'specs',
  'scripts'
)
foreach ($f in $requiredFiles) { Test-RequiredFile $f }
foreach ($d in $requiredDirs) { Test-RequiredDir $d }

if ($missing) {
  [Console]::Error.WriteLine('SDD structure validation failed.'); exit 1
}

# Check for unresolved {{PLACEHOLDER}} tokens in the instruction files and the
# harness directories. Any per-instance template file (*.template under a
# templates/ directory) is exempt, as is the literal {{PLACEHOLDER}} token used
# in skill docs.
$placeholder = '\{\{[A-Z0-9_]*\}\}'
$targets = @('AGENTS.md', 'CLAUDE.md')
foreach ($dir in @($harnessDir, $skillsDir) | Select-Object -Unique) {
  if (Test-Path -LiteralPath $dir -PathType Container) {
    $targets += (Get-ChildItem -LiteralPath $dir -Recurse -File | ForEach-Object { $_.FullName })
  }
}
$unresolved = @()
foreach ($file in $targets) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
  $norm = ($file -replace '\\', '/')
  if ($norm -match '/sdd-workflow/templates/') { continue }
  if ($norm -match '/templates/[^/]+\.template$') { continue }
  $hits = Select-String -LiteralPath $file -Pattern $placeholder -AllMatches
  foreach ($h in $hits) {
    if ($h.Line -match '\{\{PLACEHOLDER\}\}') { continue }
    $unresolved += ('{0}:{1}:{2}' -f $norm, $h.LineNumber, $h.Line.Trim())
  }
}
if ($unresolved.Count -gt 0) {
  $unresolved | ForEach-Object { [Console]::Error.WriteLine($_) }
  [Console]::Error.WriteLine("Unresolved template placeholders found in the instruction files or the harness directory ($harnessDir).")
  exit 1
}

# Check for unresolved {{PLACEHOLDER}} tokens in instantiated spec sources
# (markdown is the source of truth; rendered .html files are gitignored artifacts).
if (Test-Path -LiteralPath 'specs' -PathType Container) {
  $specHits = Get-ChildItem -LiteralPath 'specs' -Recurse -File -Filter '*.md' |
    Where-Object { Select-String -LiteralPath $_.FullName -Pattern $placeholder -Quiet }
  if ($specHits) {
    [Console]::Error.WriteLine('Unresolved template placeholders found in spec markdown files:')
    $specHits | ForEach-Object { [Console]::Error.WriteLine(($_.FullName -replace '\\', '/')) }
    exit 1
  }

  # Every spec markdown source must start with YAML frontmatter.
  $missingFm = Get-ChildItem -LiteralPath 'specs' -Recurse -File -Filter '*.md' |
    Where-Object { $_.Name -ne 'README.md' } |
    Where-Object { (Get-Content -LiteralPath $_.FullName -TotalCount 1) -ne '---' }
  if ($missingFm) {
    [Console]::Error.WriteLine('Spec markdown files missing YAML frontmatter:')
    $missingFm | ForEach-Object { [Console]::Error.WriteLine(($_.FullName -replace '\\', '/')) }
    exit 1
  }
}

# Validate tasks.json against its own state machine. State is read from JSON
# only — spec files are never parsed.
try {
  $tasks = Get-Content -LiteralPath 'tasks.json' -Raw | ConvertFrom-Json
} catch {
  [Console]::Error.WriteLine('tasks.json is not valid JSON.'); exit 1
}

$defaultSm = @('pending', 'spec_draft', 'spec_ready', 'human_approved', 'in_progress', 'review', 'done', 'rejected', 'blocked')
if ($tasks.state_machine) { $sm = $tasks.state_machine } else { $sm = $defaultSm }
$approvedStates = @('human_approved', 'in_progress', 'review', 'done')

$invalid = @()
$missingApprovals = @()
foreach ($t in $tasks.tasks) {
  if ($t.status) { $status = [string]$t.status } else { $status = '' }
  if ($t.id) { $id = $t.id } else { $id = '?' }
  if ($sm -notcontains $status) {
    if ($status) { $statusDisp = $status } else { $statusDisp = 'missing' }
    $invalid += ('{0}: invalid status "{1}"' -f $id, $statusDisp)
  }
  if ($t.approval -and ($t.approval.required -eq $true) -and ($approvedStates -contains $status)) {
    if ($null -eq $t.approval.approved_by) {
      $missingApprovals += ('{0}: status "{1}" requires approval but approval.approved_by is null' -f $id, $status)
    }
  }
}
if ($invalid.Count -gt 0) {
  [Console]::Error.WriteLine('tasks.json contains statuses outside the configured state machine:')
  $invalid | ForEach-Object { [Console]::Error.WriteLine($_) }
  exit 1
}
if ($missingApprovals.Count -gt 0) {
  [Console]::Error.WriteLine('tasks.json contains approved/in-progress tasks without recorded human approval:')
  $missingApprovals | ForEach-Object { [Console]::Error.WriteLine($_) }
  exit 1
}

Write-Output 'SDD structure validation passed.'
exit 0
