<#
.SYNOPSIS
  Scans the WoW AddOns folder and flags known performance-sensitive addons.

.PARAMETER WowPath  WoW version dir or base install dir.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scan-addons.ps1 -WowPath "D:\World of Warcraft\_retail_"
#>
param([string]$WowPath)

$ErrorActionPreference = 'Stop'

if (-not $WowPath) { $WowPath = (Get-Location).Path }

if (Test-Path (Join-Path $WowPath 'Wow.exe')) {
    $versionDir = $WowPath
} else {
    $found = $null
    foreach ($sub in @('_retail_', '_classic_', '_classic_era_')) {
        if (Test-Path (Join-Path $WowPath $sub)) { $found = Join-Path $WowPath $sub; break }
    }
    if (-not $found) { throw "Cannot resolve WoW version dir under '$WowPath'." }
    $versionDir = $found
}

$addons = Join-Path $versionDir 'Interface\AddOns'
if (-not (Test-Path $addons)) { throw "AddOns folder not found: $addons" }

$heavy = @{
    'WeakAuras'          = 'Top suspect. Use /wa p to sort auras by per-frame ms.'
    'WeakAurasOptions'   = 'Config module. Keep it disabled outside of edit sessions.'
    'Details'            = 'Combat log parsing. Use 1 window in raids, lower update rate.'
    'ElvUI'              = 'Full UI framework. Disable unused modules and unitframe effects.'
    'Plater'             = 'Nameplates. Limit auras shown, disable stacking, hide friendly plates.'
    'DBM-Core'           = 'Boss mods. Do not run alongside BigWigs.'
    'BigWigs'            = 'Boss mods. Do not run alongside DBM.'
    'Bagnon'             = 'Rebuilds the whole bag on every item change.'
    'ArkInventory'       = 'Rebuilds the whole bag on every item change.'
    'TradeSkillMaster'   = 'Huge dataset. Scans will stutter; disable during raids.'
    'AddOnSkins'         = 'Skins every UI element - cumulative overhead.'
    'Skada'              = 'Lighter damage meter alternative to Details.'
    'Tukui'              = 'UI framework.'
    'Bartender4'         = 'Action bars. Low impact usually.'
    'Kui_Nameplates'     = 'Nameplates.'
    'ThreatPlates'       = 'Nameplates.'
}

$rows = Get-ChildItem $addons -Directory | ForEach-Object {
    $size = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    if (-not $size) { $size = 0 }
    $toc = Join-Path $_.FullName ($_.Name + '.toc')
    $ver = ''
    if (Test-Path $toc) {
        $ver = (Select-String -Path $toc -Pattern '^##\s*Version:\s*(.+)' | Select-Object -First 1)
        if ($ver) { $ver = ($ver.Line -replace '^##\s*Version:\s*', '').Trim() }
    }
    $flag = ''
    if ($heavy.ContainsKey($_.Name)) { $flag = $heavy[$_.Name] }
    [pscustomobject]@{
        Name    = $_.Name
        SizeMB  = [math]::Round($size / 1MB, 1)
        Files   = (Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
        Version = $ver
        Flag    = $flag
    }
} | Sort-Object SizeMB -Descending

Write-Host ''
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host "  ADDON SCAN - $addons" -ForegroundColor Cyan
Write-Host ('=' * 78) -ForegroundColor Cyan
Write-Host ("  {0,-30} {1,8} {2,7}  {3}" -f 'ADDON', 'SIZE MB', 'FILES', 'NOTE')
Write-Host ('-' * 78)
foreach ($r in $rows) {
    $line = "  {0,-30} {1,8} {2,7}  {3}" -f $r.Name, $r.SizeMB, $r.Files, $r.Flag
    if ($r.Flag) { Write-Host $line -ForegroundColor Yellow } else { Write-Host $line }
}
Write-Host ('-' * 78)
Write-Host ("  total addons: {0}    total size: {1} MB" -f $rows.Count, [math]::Round(($rows | Measure-Object -Property SizeMB -Sum).Sum, 1))
Write-Host ''
Write-Host 'Large size does not always mean slow, but it is a good triage starting point.' -ForegroundColor Cyan
Write-Host 'For real numbers, run the baseline -> bisect procedure in references/addon-performance.md' -ForegroundColor Cyan
Write-Host 'Also run:  /console scriptErrors 1   and watch for Lua error spam in raid.' -ForegroundColor Yellow
Write-Host ''
