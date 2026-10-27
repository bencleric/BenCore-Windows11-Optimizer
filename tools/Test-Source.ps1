# Read-only source validation. Windows PowerShell 5.1 compatible.
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$scripts = @('BenCore.ps1', 'BenCore.Engine.psm1', 'Test-BenCore.ps1', 'tools/Test-Source.ps1')
$problem = $false
foreach ($rel in $scripts) {
    $path = Join-Path $repo $rel
    if (-not (Test-Path -LiteralPath $path)) { Write-Host "MISSING: $rel"; $problem=$true; continue }
    $tokens=$null; $errors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
    if (@($errors).Count -gt 0) {
        $problem=$true
        Write-Host "FAIL: $rel"
        $errors | ForEach-Object { Write-Host "  $($_.Message)" }
    } else { Write-Host "PASS: $rel parses" }
}
try {
    $xamlPath = Join-Path $repo 'BenCore.UI.xaml'
    [xml]$xaml = Get-Content -LiteralPath $xamlPath -Raw -Encoding UTF8
    if (-not $xaml.DocumentElement) { throw 'XAML has no root element.' }
    Write-Host 'PASS: XAML is well-formed XML'
} catch { $problem=$true; Write-Host "FAIL: XAML XML: $($_.Exception.Message)" }
foreach ($rel in @('Start-BenCore.cmd','Run-Diagnostics.cmd','README.md','docs/INSTALLATION.md','docs/USER_GUIDE.md')) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo $rel))) { $problem=$true; Write-Host "MISSING: $rel" }
}
if ($problem) { exit 1 }
Write-Host 'Static source validation passed. Integration and performance are NOT tested.'
exit 0
