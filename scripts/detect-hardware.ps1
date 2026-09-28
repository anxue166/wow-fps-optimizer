<#
.SYNOPSIS
  Read-only hardware / Windows / NVIDIA / WoW detection for WoW FPS tuning.

.DESCRIPTION
  Collects CPU, memory, GPU, display, power plan, Game Mode, HAGS, NVIDIA driver,
  WoW install path and Config.wtf. Performs NO writes anywhere.

.PARAMETER Json
  Emit machine-readable JSON instead of a human report.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File detect-hardware.ps1
  powershell -ExecutionPolicy Bypass -File detect-hardware.ps1 -Json
#>
param([switch]$Json)

$ErrorActionPreference = 'SilentlyContinue'

function Get-MemGB {
    param([double]$Bytes)
    if ($Bytes -le 0) { return 0 }
    return [math]::Round($Bytes / 1GB, 1)
}

$report = [ordered]@{}

# ---------------- CPU ----------------
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$report.cpu = [ordered]@{
    name                 = $cpu.Name.Trim()
    cores                = $cpu.NumberOfCores
    logicalProcessors    = $cpu.NumberOfLogicalProcessors
    maxClockMHz          = $cpu.MaxClockSpeed
    smtEnabled           = ($cpu.NumberOfLogicalProcessors -gt $cpu.NumberOfCores)
}

# ---------------- Memory ----------------
$sticks = @(Get-CimInstance Win32_PhysicalMemory)
$totalGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
$report.memory = [ordered]@{
    totalGB        = $totalGB
    stickCount     = $sticks.Count
    singleChannel  = ($sticks.Count -eq 1)
    speedsMHz      = ($sticks | ForEach-Object { $_.ConfiguredClockSpeed }) -join ','
    jedecSpeedMHz  = (($sticks | ForEach-Object { $_.Speed }) -join ',')
    note           = 'ConfiguredClockSpeed is actual; Speed is JEDEC nominal. Check BIOS for XMP/EXPO.'
}

# ---------------- GPU ----------------
$gpu = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like '*NVIDIA*' } | Select-Object -First 1
if (-not $gpu) { $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1 }
$vramGB = 0
if ($gpu.AdapterRAM -gt 0) { $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 0) }
$smi = $null
$smiPath = Join-Path $env:SystemRoot 'System32\nvidia-smi.exe'
if (Test-Path $smiPath) {
    $smi = & $smiPath --query-gpu=name,memory.total,driver_version --format=csv,noheader 2>$null
}
$report.gpu = [ordered]@{
    name            = $gpu.Name
    vramGB_wmi      = $vramGB
    driverVersion   = $gpu.DriverVersion
    driverDate      = $gpu.DriverDate
    nvidiaSmi       = $smi
    vramNote        = 'AdapterRAM may be inaccurate on some systems; trust nvidia-smi memory.total.'
}

# ---------------- Display ----------------
Add-Type -AssemblyName System.Windows.Forms | Out-Null
$scr = [System.Windows.Forms.Screen]::PrimaryScreen
$report.display = [ordered]@{
    resolution      = "$($scr.Bounds.Width)x$($scr.Bounds.Height)"
    refreshRateHz   = $gpu.CurrentRefreshRate
    videoMode       = $gpu.VideoModeDescription
    monitorCount    = ([System.Windows.Forms.Screen]::AllScreens).Count
    refreshNote     = 'Confirm in Settings > System > Display > Advanced display. Many systems default to 60Hz.'
}

# ---------------- Windows power / game mode / HAGS ----------------
$active = (powercfg /getactivescheme 2>$null | Out-String).Trim()
$guid = ''
if ($active -match '([0-9a-fA-F-]{36})') { $guid = $Matches[1] }
$planName = switch ($guid) {
    '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c' { 'High performance' }
    'e9a42b02-d5df-448d-aa00-03f14749eb61' { 'Ultimate performance' }
    '381b4222-f694-41f0-9685-ff5bb260df2e' { 'Balanced' }
    'a1841308-3541-4fab-bc81-f71556f20b4a' { 'Power saver' }
    default { 'Unknown/custom' }
}
$gameMode = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\GameBar' -Name 'AutoGameModeEnabled').AutoGameModeEnabled
$hwSch    = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' -Name 'HwSchMode').HwSchMode
$report.windows = [ordered]@{
    osCaption        = (Get-CimInstance Win32_OperatingSystem).Caption
    osBuild          = (Get-CimInstance Win32_OperatingSystem).BuildNumber
    powerPlanGuid    = $guid
    powerPlanName    = $planName
    lowPowerPlan     = ($planName -in @('Balanced', 'Power saver', 'Unknown/custom'))
    gameModeEnabled  = $gameMode
    hwSchMode        = $hwSch
    hwSchMeaning     = if ($hwSch -eq 2) { 'HAGS ON' } elseif ($hwSch -eq 1) { 'HAGS OFF' } else { 'not set (OS default)' }
}

# ---------------- Top CPU consumers ----------------
$report.topProcesses = @(
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 12 |
    ForEach-Object { [ordered]@{ name = $_.Name; cpuSec = [math]::Round($_.CPU, 1); memMB = [math]::Round($_.WorkingSet64 / 1MB, 0) } }
)

# ---------------- WoW discovery ----------------
$candidates = @()
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
              'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall' |
    Get-ItemProperty |
    Where-Object { $_.DisplayName -like '*World of Warcraft*' } |
    ForEach-Object { if ($_.InstallLocation) { $candidates += $_.InstallLocation } }

$common = @(
    'C:\Program Files\World of Warcraft', 'C:\Program Files (x86)\World of Warcraft',
    'D:\World of Warcraft', 'D:\Games\World of Warcraft', 'E:\World of Warcraft',
    'D:\Battle.net\World of Warcraft', 'C:\Battle.net\World of Warcraft'
)
foreach ($c in $common) { if (Test-Path $c) { $candidates += $c } }

# Non-standard installs (e.g. E:\games\WoW, localized folder names):
# 1) ask a running WoW process where it lives - most reliable
foreach ($pn in @('Wow', 'WowClassic', 'WowClassicEra', 'WowB')) {
    $p = Get-Process -Name $pn -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($p -and $p.Path) { $candidates += (Split-Path (Split-Path $p.Path -Parent) -Parent) }
}
# 2) brute-force: scan root of every fixed drive for a dir containing a version subfolder
foreach ($d in (Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3').DeviceID) {
    foreach ($dir in (Get-ChildItem "$d\" -Directory -ErrorAction SilentlyContinue)) {
        if ($dir.Name -match 'World of Warcraft|Warcraft|Battle\.net|暴雪') {
            foreach ($sub in @('_retail_', '_classic_', '_classic_era_', '_classic_titan_', '_ptr_')) {
                if (Test-Path (Join-Path $dir.FullName $sub)) { $candidates += $dir.FullName; break }
            }
        }
    }
}
$candidates = $candidates | Where-Object { $_ } | Select-Object -Unique

$versions = @()
foreach ($base in $candidates) {
    foreach ($sub in @('_retail_', '_classic_', '_classic_era_', '_classic_titan_', '_ptr_')) {
        $p = Join-Path $base $sub
        $exe = @('Wow.exe', 'WowClassic.exe', 'WowClassicEra.exe', 'WowB.exe') | Where-Object { Test-Path (Join-Path $p $_) } | Select-Object -First 1
        if ($exe) {
            $versions += [ordered]@{
                exe            = $exe
                version    = $sub.Trim('_')
                path       = $p
                configWtf  = Join-Path $p 'WTF\Config.wtf'
                configExists = Test-Path (Join-Path $p 'WTF\Config.wtf')
                addonsDir  = Join-Path $p 'Interface\AddOns'
            }
        }
    }
}
$report.wow = [ordered]@{
    installCandidates = $candidates
    detectedVersions  = $versions
}

# ---------------- Config.wtf graphics values ----------------
$graphics = @()
foreach ($v in $versions) {
    if (-not $v.configExists) { continue }
    $lines = Get-Content $v.configWtf
    foreach ($l in $lines) {
        if ($l -match '^\s*SET\s+(\S+)\s+"?([^"]*)"?') {
            $k = $Matches[1]
            if ($k -match '^(gx|graphics|maxFPS|renderScale|raidGraphics|shadow|particle|liquid|SSAO|compute|outline|spell|view|env|ground|texture|projected|ray)') {
                $graphics += [ordered]@{ version = $v.version; key = $k; value = $Matches[2].Trim() }
            }
        }
    }
}
$report.wowGraphicsCvars = $graphics

# ---------------- Display-oriented warnings ----------------
$warn = @()
if ($report.display.refreshRateHz -and $report.display.refreshRateHz -le 60) {
    $warn += 'Display refresh rate is 60Hz or lower. If the monitor supports higher, raise it in Windows display settings first.'
}
if ($report.memory.singleChannel) { $warn += 'Only one memory stick detected - single channel mode significantly hurts 1% Low.' }
if ($report.memory.stickCount -ge 2 -and $report.memory.speedsMHz) {
    $first = ($report.memory.speedsMHz -split ',')[0]
    if ([int]$first -le 2400) { $warn += "Memory running at $first MHz - XMP/EXPO may be disabled in BIOS." }
}
if ($report.windows.lowPowerPlan) { $warn += "Power plan is '$planName' - CPU downclocking will hurt raid minimum FPS." }
if ($report.wow.detectedVersions.Count -eq 0) { $warn += 'No WoW installation detected automatically - pass the path manually.' }
$report.warnings = $warn

if ($Json) {
    $report | ConvertTo-Json -Depth 6
    exit 0
}

# ---------------- Human readable report ----------------
function Show-Section($title) {
    Write-Host ''
    Write-Host ('=' * 68) -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host ('=' * 68) -ForegroundColor Cyan
}

Show-Section 'CPU'
Write-Host ("  {0}" -f $report.cpu.name)
Write-Host ("  Cores: {0}   Threads: {1}   SMT: {2}" -f $report.cpu.cores, $report.cpu.logicalProcessors, $report.cpu.smtEnabled)

Show-Section 'MEMORY'
Write-Host ("  Total: {0} GB   Sticks: {1}   Single channel: {2}" -f $report.memory.totalGB, $report.memory.stickCount, $report.memory.singleChannel)
Write-Host ("  Running at: {0} MHz (JEDEC nominal: {1} MHz)" -f $report.memory.speedsMHz, $report.memory.jedecSpeedMHz)

Show-Section 'GPU'
Write-Host ("  {0}" -f $report.gpu.name)
Write-Host ("  VRAM (WMI): {0} GB    Driver: {1}" -f $report.gpu.vramGB_wmi, $report.gpu.driverVersion)
if ($report.gpu.nvidiaSmi) { Write-Host ("  nvidia-smi: {0}" -f $report.gpu.nvidiaSmi) }

Show-Section 'DISPLAY'
Write-Host ("  Resolution: {0}   Refresh: {1} Hz   Monitors: {2}" -f $report.display.resolution, $report.display.refreshRateHz, $report.display.monitorCount)

Show-Section 'WINDOWS'
Write-Host ("  {0} (build {1})" -f $report.windows.osCaption, $report.windows.osBuild)
Write-Host ("  Power plan: {0} ({1})" -f $report.windows.powerPlanName, $report.windows.powerPlanGuid)
Write-Host ("  Game Mode: {0}    HAGS: {1}" -f $report.windows.gameModeEnabled, $report.windows.hwSchMeaning)

Show-Section 'TOP CPU CONSUMERS'
$report.topProcesses | ForEach-Object { Write-Host ("  {0,-28} CPU {1,8}s   MEM {2,6} MB" -f $_.name, $_.cpuSec, $_.memMB) }

Show-Section 'WORLD OF WARCRAFT'
if ($report.wow.detectedVersions.Count -eq 0) {
    Write-Host '  No installation detected.'
} else {
    foreach ($v in $report.wow.detectedVersions) {
        Write-Host ("  [{0}] {1}" -f $v.version, $v.path)
        Write-Host ("        Config.wtf: {0} (exists: {1})" -f $v.configWtf, $v.configExists)
    }
}

if ($report.wowGraphicsCvars.Count -gt 0) {
    Show-Section 'CURRENT GRAPHICS CVARS'
    $report.wowGraphicsCvars | ForEach-Object { Write-Host ("  [{0}] {1} = {2}" -f $_.version, $_.key, $_.value) }
}

Show-Section 'WARNINGS'
if ($warn.Count -eq 0) { Write-Host '  None.' } else { $warn | ForEach-Object { Write-Host ("  [!] {0}" -f $_) -ForegroundColor Yellow } }

Write-Host ''
Write-Host 'READ-ONLY SCAN COMPLETE. Nothing was modified.' -ForegroundColor Green
Write-Host ''
