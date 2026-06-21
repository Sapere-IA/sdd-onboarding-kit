#!/usr/bin/env pwsh
# PowerShell port of validate-sdd-structure.sh, for Windows-primary teams.
# Requires neither bash nor jq: uses native PowerShell and ConvertFrom-Json.
# Behaviour matches the bash version, except tasks.json state-machine
# validation always runs (there is no jq to be missing), so the harness is
# not quietly weakened on Windows.
#
# Run from the project root, or set CLAUDE_PROJECT_DIR. Exit code 0 = passed,
# 1 = failed. Works on Windows PowerShell 5.1 and PowerShell 7+.

if ($env:CLAUDE_PROJECT_DIR) { $projectDir = $env:CLAUDE_PROJECT_DIR }
else { $projectDir = (Get-Location).Path }
Set-Location -LiteralPath $projectDir

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

$requiredFiles = @(
  'CLAUDE.md',
  'decisions/answers.md',
  '.claude/agents/leader.md',
  '.claude/agents/spec-author.md',
  '.claude/agents/implementer.md',
  '.claude/agents/reviewer.md',
  '.claude/skills/sdd-workflow/SKILL.md',
  '.claude/skills/sdd-workflow/workflow.md',
  '.claude/skills/sdd-workflow/spec-format.md',
  '.claude/skills/sdd-workflow/task-state-machine.md',
  '.claude/skills/sdd-workflow/review-checklist.md',
  '.claude/skills/sdd-workflow/templates/spec.css',
  '.claude/skills/sdd-workflow/templates/spec.js',
  'tasks.json',
  'history.html',
  'scripts/run-tests.sh',
  'scripts/run-lint.sh'
)
$requiredDirs = @(
  '.claude/agents',
  '.claude/skills/sdd-workflow',
  '.claude/skills/sdd-workflow/templates',
  'specs',
  'scripts'
)
foreach ($f in $requiredFiles) { Test-RequiredFile $f }
foreach ($d in $requiredDirs) { Test-RequiredDir $d }

if ($missing) {
  [Console]::Error.WriteLine('SDD structure validation failed.'); exit 1
}

# Check for unresolved {{PLACEHOLDER}} tokens in CLAUDE.md and .claude/.
# Any per-instance template file (*.template under a templates/ directory) is
# exempt, as is the literal {{PLACEHOLDER}} token used in skill docs.
$placeholder = '\{\{[A-Z0-9_]*\}\}'
$targets = @('CLAUDE.md')
if (Test-Path -LiteralPath '.claude' -PathType Container) {
  $targets += (Get-ChildItem -LiteralPath '.claude' -Recurse -File | ForEach-Object { $_.FullName })
}
$unresolved = @()
foreach ($file in $targets) {
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }
  $norm = ($file -replace '\\', '/')
  if ($norm -match '/\.claude/skills/sdd-workflow/templates/') { continue }
  if ($norm -match '/templates/[^/]+\.template$') { continue }
  $hits = Select-String -LiteralPath $file -Pattern $placeholder -AllMatches
  foreach ($h in $hits) {
    if ($h.Line -match '\{\{PLACEHOLDER\}\}') { continue }
    $unresolved += ('{0}:{1}:{2}' -f $norm, $h.LineNumber, $h.Line.Trim())
  }
}
if ($unresolved.Count -gt 0) {
  $unresolved | ForEach-Object { [Console]::Error.WriteLine($_) }
  [Console]::Error.WriteLine('Unresolved template placeholders found in CLAUDE.md or .claude/.')
  exit 1
}

# Check for unresolved {{PLACEHOLDER}} tokens in generated HTML spec files.
if (Test-Path -LiteralPath 'specs' -PathType Container) {
  $specHits = Get-ChildItem -LiteralPath 'specs' -Recurse -File -Filter '*.html' |
    Where-Object { Select-String -LiteralPath $_.FullName -Pattern $placeholder -Quiet }
  if ($specHits) {
    [Console]::Error.WriteLine('Unresolved template placeholders found in HTML spec files:')
    $specHits | ForEach-Object { [Console]::Error.WriteLine(($_.FullName -replace '\\', '/')) }
    exit 1
  }
}

# Validate tasks.json against its own state machine. State is read from JSON
# only — spec HTML files are never parsed.
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
