<#
.SYNOPSIS
  Backs up WoW WTF folder, Config.wtf and Windows/NVIDIA state before any change.

.PARAMETER WowPath
  WoW root folder. Accepts either the base install dir or a version dir
  (e.g. D:\World of Warcraft  or  D:\World of Warcraft\_retail_).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File backup-wow.ps1 -WowPath "D:\World of Warcraft\_retail_"
#>
param(
    [string]$WowPath,
    [switch]$Force   # back up even while the game is running (config may be stale)
)

$ErrorActionPreference = 'Stop'

# ---- resolve version dir ----
if (-not $WowPath) {
    $probe = @(
        'C:\Program Files\World of Warcraft', 'C:\Program Files (x86)\World of Warcraft',
        'D:\World of Warcraft', 'D:\Games\World of Warcraft', 'E:\World of Warcraft',
        'D:\Battle.net\World of Warcraft', 'C:\Battle.net\World of Warcraft'
    )
    foreach ($base in $probe) {
        foreach ($sub in @('_retail_', '_classic_', '_classic_era_', '_classic_titan_')) {
            if (Test-Path (Join-Path $base $sub)) { $WowPath = Join-Path $base $sub; break }
        }
        if ($WowPath) { break }
    }
    if (-not $WowPath) { throw 'Could not locate WoW. Pass -WowPath explicitly.' }
}

$exeNames = @('Wow.exe', 'WowClassic.exe', 'WowClassicEra.exe', 'WowB.exe')
$hasExe = @($exeNames | Where-Object { Test-Path (Join-Path $WowPath $_) }).Count -gt 0
if ($hasExe) {
    $versionDir = $WowPath
    $baseDir    = Split-Path $WowPath -Parent
} else {
    # base dir given - find first version dir present
    $found = $null
    foreach ($sub in @('_retail_', '_classic_', '_classic_era_', '_classic_titan_')) {
        if (Test-Path (Join-Path $WowPath $sub)) { $found = Join-Path $WowPath $sub; break }
    }
    if (-not $found) { throw "No WoW executable and no version subfolder under '$WowPath'." }
    $versionDir = $found
    $baseDir    = $WowPath
}

$wtfDir = Join-Path $versionDir 'WTF'
if (-not (Test-Path $wtfDir)) { throw "WTF folder not found: $wtfDir" }

# ---- refuse to back up while the game is running -----------------
# WoW rewrites Config.wtf when it exits, so a backup taken while it is
# running can be stale. Non-interactive by design: no Read-Host prompts.
$running = @(Get-Process -Name 'Wow','WowClassic','WowClassicEra','WowB' -ErrorAction SilentlyContinue)
if ($running.Count -gt 0 -and -not $Force) {
    Write-Host 'WARNING: World of Warcraft is running.' -ForegroundColor Yellow
    Write-Host '  The game rewrites Config.wtf on exit, so a backup taken now may be stale' -ForegroundColor Yellow
    Write-Host '  and any config edit made now would be overwritten.' -ForegroundColor Yellow
    Write-Host '  Close the game and re-run, or pass -Force to back up anyway.' -ForegroundColor Yellow
    exit 1
}

$stamp    = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
$backupRoot = Join-Path $baseDir '_WoW-FPS-Backup'
$dest     = Join-Path $backupRoot $stamp
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# ---- copy WTF ----
Write-Host "Backing up WTF -> $dest\WTF" -ForegroundColor Cyan
Copy-Item -Path $wtfDir -Destination (Join-Path $dest 'WTF') -Recurse -Force

# ---- standalone Config.wtf ----
$cfgSrc = Join-Path $wtfDir 'Config.wtf'
if (Test-Path $cfgSrc) { Copy-Item $cfgSrc -Destination (Join-Path $dest 'Config.wtf') -Force }

# ---- system state snapshot ----
$active = (powercfg /getactivescheme 2>$null | Out-String).Trim()
$guid = ''
if ($active -match '([0-9a-fA-F-]{36})') { $guid = $Matches[1] }
$hwSch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode' -ErrorAction SilentlyContinue).HwSchMode
$gm    = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled' -ErrorAction SilentlyContinue).AutoGameModeEnabled
$gpu   = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like '*NVIDIA*' } | Select-Object -First 1

$state = [ordered]@{
    timestamp  = (Get-Date -Format 'o')
    windows    = [ordered]@{
        powerPlanGuid = $guid
        powerPlanRaw  = $active
        gameMode      = $gm
        hwSchMode     = $hwSch
    }
    nvidia     = [ordered]@{
        gpuName        = $gpu.Name
        driverVersion  = $gpu.DriverVersion
        driverDate     = $gpu.DriverDate
        wowAppProfile  = $null
        note           = 'NVIDIA Control Panel settings cannot be read by script - screenshot them before changing.'
    }
    wow        = [ordered]@{
        versionDir    = $versionDir
        configPath    = $cfgSrc
        wtfPath       = $wtfDir
    }
}
$state | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $dest 'system-state.json') -Encoding UTF8

# ---- manifest ----
$manifest = @()
$manifest += 'WoW FPS Optimizer - backup manifest'
$manifest += "created : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$manifest += "version dir : $versionDir"
$manifest += "backup dir  : $dest"
$manifest += ''
$manifest += 'contents:'
$manifest += '  WTF\                 full WTF tree (includes Config.wtf)'
$manifest += '  Config.wtf           standalone copy for quick rollback'
$manifest += '  system-state.json    Windows / NVIDIA / WoW original state'
$manifest += ''
$manifest += 'restore command:'
$manifest += "  powershell -ExecutionPolicy Bypass -File restore-wow.ps1 -BackupDir `"$dest`""
$manifest -join "`r`n" | Set-Content -Path (Join-Path $dest 'MANIFEST.txt') -Encoding UTF8

Write-Host ''
Write-Host 'Backup complete.' -ForegroundColor Green
Write-Host "  Location : $dest"
Write-Host "  Restore  : powershell -ExecutionPolicy Bypass -File restore-wow.ps1 -BackupDir `"$dest`"" -ForegroundColor Cyan
Write-Host ''
Write-Host 'IMPORTANT: NVIDIA Control Panel settings are not captured by this script.' -ForegroundColor Yellow
Write-Host 'Screenshot each tab before changing anything there.' -ForegroundColor Yellow
