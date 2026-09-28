<#
.SYNOPSIS
  Applies a graphics profile (A/B/C) to Config.wtf. Requires an existing backup.

.DESCRIPTION
  Strategy: keys already present in Config.wtf get their value replaced in place.
  Keys not present are appended inside a marked block so they can be removed cleanly.
  A change log is appended to the backup root.

.PARAMETER WowPath   WoW version dir (containing Wow.exe / WowClassic.exe) or base install dir.
.PARAMETER Profile   A = quality first, B = balanced, C = raid FPS.
.PARAMETER BackupDir Optional explicit backup dir. If omitted, the newest backup is required to exist.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File apply-profile.ps1 -WowPath "D:\World of Warcraft\_retail_" -Profile C
#>
param(
    [Parameter(Mandatory = $true)][string]$WowPath,
    [Parameter(Mandatory = $true)][ValidateSet('A','B','C','CA','CB','CC')][string]$Profile,
    [string]$BackupDir
)

$ErrorActionPreference = 'Stop'
$skillRoot  = Split-Path $PSScriptRoot -Parent
$key = $Profile.ToUpper()
$fileMap = @{
    'A'  = 'profile-a.wtf'
    'B'  = 'profile-b.wtf'
    'C'  = 'profile-c.wtf'
    'CA' = 'classic-a.wtf'
    'CB' = 'classic-b.wtf'
    'CC' = 'classic-c.wtf'
}
$profileFile = Join-Path $skillRoot ("templates\profiles\" + $fileMap[$key])

if (-not (Test-Path $profileFile)) { throw "Profile template not found: $profileFile" }

# ---- resolve version dir ----
$exeNames = @('Wow.exe', 'WowClassic.exe', 'WowClassicEra.exe', 'WowB.exe')
$hasExe = @($exeNames | Where-Object { Test-Path (Join-Path $WowPath $_) }).Count -gt 0
if ($hasExe) {
    $versionDir = $WowPath; $baseDir = Split-Path $WowPath -Parent
} else {
    $found = $null
    foreach ($sub in @('_retail_', '_classic_', '_classic_era_', '_classic_titan_')) {
        if (Test-Path (Join-Path $WowPath $sub)) { $found = Join-Path $WowPath $sub; break }
    }
    if (-not $found) { throw "Cannot resolve WoW version dir under '$WowPath'." }
    $versionDir = $found; $baseDir = $WowPath
}

$cfgPath = Join-Path $versionDir 'WTF\Config.wtf'
if (-not (Test-Path $cfgPath)) { throw "Config.wtf not found: $cfgPath" }

# ---- backup guard ----
$backupRoot = Join-Path $baseDir '_WoW-FPS-Backup'
if ($BackupDir) {
    if (-not (Test-Path $BackupDir)) { throw "BackupDir not found: $BackupDir" }
} else {
    if (-not (Test-Path $backupRoot)) {
        throw "No backup found at '$backupRoot'. Run backup-wow.ps1 first."
    }
    $BackupDir = Get-ChildItem $backupRoot -Directory | Sort-Object Name -Descending | Select-Object -First 1 | ForEach-Object { $_.FullName }
    if (-not $BackupDir) { throw "No backup folders in '$backupRoot'. Run backup-wow.ps1 first." }
}
Write-Host "Backup verified: $BackupDir" -ForegroundColor Green

# ---- game running guard ----
if (Get-Process -Name 'Wow','WowClassic','WowClassicEra' -ErrorAction SilentlyContinue) {
    throw 'World of Warcraft is running. Close the game before applying a profile.'
}

# ---- parse profile ----
$targets = @()
foreach ($line in Get-Content $profileFile) {
    $t = $line.Trim()
    if ($t -eq '' -or $t.StartsWith('#')) { continue }
    if ($t -match '^SET\s+(\S+)\s+"?([^"]*)"?') {
        $targets += [pscustomobject]@{ key = $Matches[1]; value = $Matches[2].Trim() }
    }
}
if ($targets.Count -eq 0) { throw "No SET lines parsed from $profileFile" }

# ---- load config ----
$lines = New-Object System.Collections.Generic.List[string]
$lines.AddRange([string[]](Get-Content $cfgPath))

$beginMark = '# BEGIN WoW-FPS-Optimizer managed block'
$endMark   = '# END WoW-FPS-Optimizer managed block'

# strip previous managed block
$cleaned = New-Object System.Collections.Generic.List[string]
$inBlock = $false
foreach ($l in $lines) {
    if ($l.Trim() -eq $beginMark) { $inBlock = $true; continue }
    if ($l.Trim() -eq $endMark)   { $inBlock = $false; continue }
    if (-not $inBlock) { $cleaned.Add($l) }
}

$changes = New-Object System.Collections.Generic.List[string]
$appended = New-Object System.Collections.Generic.List[string]

foreach ($t in $targets) {
    $pattern = '^\s*SET\s+' + [regex]::Escape($t.key) + '\s+'
    $idx = -1
    for ($i = 0; $i -lt $cleaned.Count; $i++) {
        if ($cleaned[$i] -match $pattern) { $idx = $i; break }
    }
    $newLine = 'SET {0} "{1}"' -f $t.key, $t.value
    if ($idx -ge 0) {
        $oldLine = $cleaned[$idx]
        $oldVal = ''
        if ($oldLine -match '"?([^"]*)"?\s*$') { $oldVal = $Matches[1].Trim() }
        if ($oldLine.Trim() -ne $newLine) {
            $changes.Add(("  {0}: {1} -> {2}" -f $t.key, $oldVal, $t.value))
            $cleaned[$idx] = $newLine
        }
    } else {
        $appended.Add($newLine)
        $changes.Add(("  {0}: (absent) -> {1}   [appended]" -f $t.key, $t.value))
    }
}

# ---- write ----
if ($appended.Count -gt 0) {
    if ($cleaned.Count -gt 0 -and $cleaned[$cleaned.Count - 1].Trim() -ne '') { $cleaned.Add('') }
    $cleaned.Add($beginMark)
    foreach ($a in $appended) { $cleaned.Add($a) }
    $cleaned.Add($endMark)
}

Copy-Item $cfgPath "$cfgPath.bak-preprofile" -Force
Set-Content -Path $cfgPath -Value $cleaned -Encoding UTF8

# ---- change log ----
$logPath = Join-Path (Split-Path $BackupDir -Parent) 'change-log.txt'
$log = New-Object System.Collections.Generic.List[string]
$log.Add("[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Profile $Profile applied to $cfgPath")
$log.Add("  backup: $BackupDir")
$log.AddRange($changes)
$log.Add('')
Add-Content -Path $logPath -Value $log -Encoding UTF8

Write-Host ''
Write-Host "Profile $Profile applied." -ForegroundColor Green
Write-Host "Changed:" -ForegroundColor Cyan
$changes | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host "Change log : $logPath" -ForegroundColor Cyan
Write-Host "Rollback   : Copy '$BackupDir\Config.wtf' over '$cfgPath', or run restore-wow.ps1" -ForegroundColor Cyan
Write-Host ''
Write-Host 'NOTE: account-level or character-level Config.wtf overrides may supersede these values.' -ForegroundColor Yellow
Write-Host 'Verify in game after launch.' -ForegroundColor Yellow
