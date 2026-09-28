<#
.SYNOPSIS
  One-click restore of WoW WTF from a backup created by backup-wow.ps1.

.DESCRIPTION
  Validates the backup, backs up the CURRENT state first (so you can undo an undo),
  then restores WTF.

.PARAMETER BackupDir  The timestamped backup folder (containing WTF\).
.PARAMETER ConfigOnly Restore only Config.wtf instead of the whole WTF tree.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File restore-wow.ps1 -BackupDir "D:\World of Warcraft\_WoW-FPS-Backup\2026-09-28_19-50-12"
  powershell -ExecutionPolicy Bypass -File restore-wow.ps1 -BackupDir "<...>" -ConfigOnly
#>
param(
    [Parameter(Mandatory = $true)][string]$BackupDir,
    [string]$VersionDir,
    [switch]$ConfigOnly
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $BackupDir)) { throw "Backup dir not found: $BackupDir" }
$srcWtf = Join-Path $BackupDir 'WTF'
if (-not (Test-Path $srcWtf)) { throw "Backup is missing WTF folder: $srcWtf" }

$stateFile = Join-Path $BackupDir 'system-state.json'
$versionDir = $null
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    $versionDir = $state.wow.versionDir
}
if (-not $versionDir -or -not (Test-Path $versionDir)) {
    if (-not $VersionDir) { throw "Cannot determine target version dir. Pass -VersionDir explicitly." }
    $versionDir = $VersionDir
    if (-not (Test-Path $versionDir)) { throw "Path not found: $versionDir" }
}

if (Get-Process -Name 'Wow','WowClassic','WowClassicEra' -ErrorAction SilentlyContinue) {
    throw 'World of Warcraft is running. Close the game before restoring.'
}

$destWtf = Join-Path $versionDir 'WTF'

# ---- safety net: snapshot current state before overwriting ----
$baseDir = Split-Path $versionDir -Parent
$preRoot = Join-Path $baseDir '_WoW-FPS-Backup'
$preDir  = Join-Path $preRoot ("pre-restore_" + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
New-Item -ItemType Directory -Path $preDir -Force | Out-Null
if (Test-Path $destWtf) { Copy-Item $destWtf (Join-Path $preDir 'WTF') -Recurse -Force }
Write-Host "Current state saved to: $preDir" -ForegroundColor Cyan

if ($ConfigOnly) {
    $src = Join-Path $BackupDir 'Config.wtf'
    if (-not (Test-Path $src)) { throw "Backup has no standalone Config.wtf: $src" }
    Copy-Item $src (Join-Path $destWtf 'Config.wtf') -Force
    Write-Host 'Config.wtf restored.' -ForegroundColor Green
} else {
    New-Item -ItemType Directory -Path $destWtf -Force | Out-Null
    Copy-Item (Join-Path $srcWtf '*') $destWtf -Recurse -Force
    Write-Host 'WTF restored.' -ForegroundColor Green
}

Write-Host ''
Write-Host 'RESTORE COMPLETE' -ForegroundColor Green
Write-Host "  restored from : $BackupDir"
Write-Host "  into          : $destWtf"
Write-Host "  undo this     : powershell -ExecutionPolicy Bypass -File restore-wow.ps1 -BackupDir `"$preDir`""
Write-Host ''
Write-Host 'Windows / NVIDIA changes are NOT undone by this script.' -ForegroundColor Yellow
Write-Host 'Use system-state.json and your screenshots to revert those manually.' -ForegroundColor Yellow
