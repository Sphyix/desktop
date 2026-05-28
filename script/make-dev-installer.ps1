# Builds GitHub Desktop and produces a Windows installer with a "-dev"
# name suffix so it installs side-by-side with the official GitHub Desktop
# instead of replacing it.
#
# Output: dist\installer\GitHubDesktop-devSetup-x64.exe
#
# Usage:
#   .\script\make-dev-installer.ps1            # build:prod + package
#   .\script\make-dev-installer.ps1 -Install   # also run yarn install first

[CmdletBinding()]
param(
    [switch]$Install,
    [string]$Suffix = '-dev'
)

# Keep going on non-terminating errors (e.g. electron-packager writing
# progress to stderr would otherwise abort the script under
# ErrorActionPreference=Stop). We check $LASTEXITCODE explicitly instead.
$ErrorActionPreference = 'Continue'

# Run from the repo root regardless of where the caller cwd is.
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

function Invoke-Step($Name, [scriptblock]$Block) {
    Write-Host ""
    Write-Host "===== $Name =====" -ForegroundColor Cyan
    & $Block
    if ($LASTEXITCODE -ne 0) {
        Write-Host "$Name failed (exit $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# Env that affects naming + reliability. Must be set for both build and
# package so the dist path and Squirrel identifier line up.
$env:DESKTOP_FORK_SUFFIX = $Suffix
$env:SKIP_PLAYWRIGHT_FFMPEG = '1'

# Point npm/yarn at a current node-gyp so VS 2026 and Node 24 are detected.
$globalNodeGyp = Join-Path (npm root -g) 'node-gyp\bin\node-gyp.js'
if (Test-Path $globalNodeGyp) {
    $env:npm_config_node_gyp = $globalNodeGyp
}

Write-Host "Repo:      $repoRoot"
Write-Host "Suffix:    $Suffix"
Write-Host "node:      $(node -v)"
Write-Host "yarn:      $(yarn -v)"

if ($Install) {
    Invoke-Step 'yarn install' { yarn install }
}

Invoke-Step 'yarn build:prod' { yarn build:prod }
Invoke-Step 'yarn package'    { yarn package }

# Squirrel writes Setup.exe, RELEASES and the nupkg directly into dist/
# (not dist/installer/, despite what getWindowsStandalonePath suggests).
$installerDir = Join-Path $repoRoot 'dist'
Write-Host ""
Write-Host "===== Output =====" -ForegroundColor Green
Get-ChildItem $installerDir -File |
    Where-Object { $_.Name -notin @('bundle-size.json', 'renderer.report.html') } |
    Select-Object Name, @{N='SizeMB';E={[math]::Round($_.Length / 1MB, 1)}} |
    Format-Table -AutoSize

$setupExe = Get-ChildItem $installerDir -Filter "GitHubDesktop${Suffix}Setup-*.exe" |
    Select-Object -First 1
if ($setupExe) {
    Write-Host ""
    Write-Host "Installer: $($setupExe.FullName)" -ForegroundColor Green
}
