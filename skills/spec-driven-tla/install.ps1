# Install the spec-driven + TLA+ sub-agent workflow into a target project (Windows).
# Run from the target project root, or pass a target dir. Idempotent.
# Usage: powershell -ExecutionPolicy Bypass -File install.ps1 [target-dir]
param([string]$Target = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
$SkillDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Target
Write-Host "== spec-driven-tla -> $Target =="

# 1. Sub-agent definitions.
New-Item -ItemType Directory -Force -Path .claude\agents | Out-Null
Get-ChildItem (Join-Path $SkillDir 'templates\agents\*.md') | ForEach-Object {
  $dest = Join-Path '.claude\agents' $_.Name
  if (Test-Path $dest) { Write-Host "[ok] agent exists (kept): $($_.Name)" }
  else { Copy-Item $_.FullName $dest; Write-Host "[ok] added agent: $($_.Name)" }
}

# 2. TLA+ model directory.
New-Item -ItemType Directory -Force -Path specs\tla | Out-Null
if (-not (Test-Path specs\tla\.gitkeep)) { New-Item -ItemType File specs\tla\.gitkeep | Out-Null }
Write-Host '[ok] specs/tla ready'

# 3. OpenSpec init if absent.
if (Test-Path openspec) { Write-Host '[ok] openspec already initialized' }
elseif (Get-Command openspec -ErrorAction SilentlyContinue) { openspec init; Write-Host '[ok] openspec initialized' }
else { Write-Host '[!!] openspec CLI not found. Install it, then run: openspec init' }

# 4. TLA+ toolchain.
if (Get-Command tlc -ErrorAction SilentlyContinue) { Write-Host '[ok] tlc present' }
else {
  Write-Host '[..] installing TLA+ toolchain (bundled)'
  & (Join-Path $SkillDir 'scripts\install-tlaplus.ps1')
}
Write-Host '== done =='
