cd C:\Dev\desktop
$env:DESKTOP_FORK_SUFFIX = "-dev"
Write-Host "===== build:prod ====="
yarn build:prod *> build.log
$buildExit = $LASTEXITCODE
Write-Host "build:prod exit=$buildExit"
Get-Content build.log -Tail 6
Write-Host "===== dist after build:prod ====="
Get-ChildItem dist | Select-Object Name
if ($buildExit -ne 0) { exit $buildExit }
Write-Host "===== yarn package ====="
yarn package *> package.log
$packageExit = $LASTEXITCODE
Write-Host "package exit=$packageExit"
Get-Content package.log -Tail 12
Write-Host "===== dist after package ====="
Get-ChildItem -Recurse -Depth 1 dist | Select-Object FullName, Length | Format-Table -AutoSize
