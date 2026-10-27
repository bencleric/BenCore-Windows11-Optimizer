# BenCore safe, read-only compatibility diagnostics. Does NOT apply optimizations.
$ErrorActionPreference='Stop'
$failed=$false
Write-Host 'BenCore v1.0 -- Windows compatibility and syntax diagnostics' -ForegroundColor Cyan
foreach ($name in @('BenCore.ps1','BenCore.Engine.psm1','Test-BenCore.ps1')) {
    $file=Join-Path $PSScriptRoot $name
    $tokens=$null; $parseErrors=$null
    [void][System.Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$parseErrors)
    if (@($parseErrors).Count -gt 0) {
        $failed=$true
        Write-Host "FAIL: $name" -ForegroundColor Red
        foreach ($err in $parseErrors) { Write-Host ('  ' + $err.Message) -ForegroundColor Red }
    } else { Write-Host "PASS: $name parses correctly" -ForegroundColor Green }
}
try {
    Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
    [xml]$ui=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'BenCore.UI.xaml') -Encoding UTF8 -Raw
    $reader=New-Object System.Xml.XmlNodeReader($ui)
    $win=[Windows.Markup.XamlReader]::Load($reader)
    if (-not $win.FindName('TxtRAM')) { throw 'Dashboard control missing.' }
    $win.Close()
    Write-Host 'PASS: WPF dashboard loads.' -ForegroundColor Green
} catch {
    Write-Host "FAIL: WPF dashboard: $($_.Exception.Message)" -ForegroundColor Red
    $failed=$true
}
try {
    Import-Module (Join-Path $PSScriptRoot 'BenCore.Engine.psm1') -Force
    $info=Get-BenCoreSystemInfo
    $options=@(Get-BenCoreOptions)
    $preview=@(Get-BenCorePreview -Ids @('animations'))
    if ($options.Count -lt 5 -or $preview.Count -lt 1) { throw 'Engine did not return expected settings.' }
    Write-Host "PASS: System scan ($($info.RAMTotalGB) GB RAM, suggested profile: $($info.Profile))." -ForegroundColor Green
    Write-Host "PASS: $($options.Count) optional optimization categories loaded; registry preview works." -ForegroundColor Green
} catch {
    Write-Host "FAIL: Engine check: $($_.Exception.Message)" -ForegroundColor Red
    $failed=$true
}
Write-Host ''
if ($failed) { Write-Host 'Some checks failed. Do not optimize this PC yet; share these results.' -ForegroundColor Red; exit 1 }
Write-Host 'Basic compatibility checks passed. This is not a substitute for testing Apply/Restore on a spare PC.' -ForegroundColor Green
exit 0
