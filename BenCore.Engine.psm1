# BenCore v1.0 - per-user, reversible Windows 11 optimizer
# Developed by Benie Mansueto Vison
# Windows PowerShell 5.1 / Windows 11. No changes to Defender, services or Windows Update.
Set-StrictMode -Version 2.0

$script:Root = Join-Path $env:LOCALAPPDATA 'BenCore'
$script:SessionDir = Join-Path $script:Root 'Sessions'
$script:LogDir = Join-Path $script:Root 'Logs'
$script:DisabledStartupPath = Join-Path $script:Root 'disabled-startup.json'
foreach ($folder in @($script:Root, $script:SessionDir, $script:LogDir)) {
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder -Force | Out-Null }
}

function Write-BenCoreLog {
    param([string]$Message, [string]$Level = 'INFO')
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $path = Join-Path $script:LogDir ('BenCore-' + (Get-Date -Format 'yyyy-MM-dd') + '.log')
    Add-Content -LiteralPath $path -Encoding UTF8 -Value "[$stamp][$Level] $Message"
}

function Save-BenCoreJson {
    param([string]$Path, [object]$Data)
    $temp = "$Path.tmp"
    $json = ConvertTo-Json -InputObject $Data -Depth 15
    Set-Content -LiteralPath $temp -Value $json -Encoding UTF8
    Move-Item -LiteralPath $temp -Destination $Path -Force
}

function Get-BenCoreRegistryValue {
    param([string]$Path, [string]$Name)
    $key = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($null -eq $key -or @($key.GetValueNames()) -notcontains $Name) {
        return [pscustomobject]@{ Exists = $false; Value = $null; Kind = '' }
    }
    return [pscustomobject]@{
        Exists = $true
        Value = $key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        Kind = $key.GetValueKind($Name).ToString()
    }
}

function Set-BenCoreRegistryValue {
    param([string]$Path, [string]$Name, [object]$Value, [string]$Kind = 'DWord')
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Kind -Force -ErrorAction Stop | Out-Null
}

function Restore-BenCoreRegistryValue {
    param([object]$Change)
    if ($Change.OldExists) {
        Set-BenCoreRegistryValue -Path $Change.Path -Name $Change.Name -Value $Change.OldValue -Kind $Change.OldKind
    } else {
        Remove-ItemProperty -LiteralPath $Change.Path -Name $Change.Name -ErrorAction SilentlyContinue
    }
}

# Only documented, per-user changes are available. All are optional and reversible.
$script:Options = @(
    [pscustomobject]@{
        Id='animations'; Title='Lighter animations'; Category='Desktop'; Impact='Low';
        Description='Reduce menu and taskbar animations. Mostly improves perceived responsiveness.';
        Changes=@(
            @{Path='HKCU:\Control Panel\Desktop\WindowMetrics'; Name='MinAnimate'; Value='0'; Kind='String'},
            @{Path='HKCU:\Control Panel\Desktop'; Name='MenuShowDelay'; Value='100'; Kind='String'},
            @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarAnimations'; Value=0; Kind='DWord'}
        )
    },
    [pscustomobject]@{
        Id='transparency'; Title='Reduce transparency effects'; Category='Desktop'; Impact='Low';
        Description='Turns off acrylic/transparency effects for the current Windows user.';
        Changes=@(@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'; Name='EnableTransparency'; Value=0; Kind='DWord'})
    },
    [pscustomobject]@{
        Id='suggestions'; Title='Reduce Windows promotional suggestions'; Category='Privacy'; Impact='Low';
        Description='Disables selected consumer recommendations and silent suggested-app installs.';
        Changes=@(
            @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338388Enabled'; Value=0; Kind='DWord'},
            @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SubscribedContent-338389Enabled'; Value=0; Kind='DWord'},
            @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SilentInstalledAppsEnabled'; Value=0; Kind='DWord'},
            @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; Name='SystemPaneSuggestionsEnabled'; Value=0; Kind='DWord'}
        )
    },
    [pscustomobject]@{
        Id='widgets'; Title='Hide taskbar Widgets'; Category='Desktop'; Impact='Low';
        Description='Hides the Widgets button; does not uninstall the component.';
        Changes=@(@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; Name='TaskbarDa'; Value=0; Kind='DWord'})
    },
    [pscustomobject]@{
        Id='ads'; Title='Disable personalized advertising ID'; Category='Privacy'; Impact='Low';
        Description='Turns off the per-user Windows advertising identifier.';
        Changes=@(@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; Name='Enabled'; Value=0; Kind='DWord'})
    },
    [pscustomobject]@{
        Id='search'; Title='Hide search highlights'; Category='Desktop'; Impact='Low';
        Description='Disables dynamic search-box highlights when this Windows build supports the setting.';
        Changes=@(@{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings'; Name='IsDynamicSearchBoxEnabled'; Value=0; Kind='DWord'})
    },
    [pscustomobject]@{
        Id='edge'; Title='Reduce Microsoft Edge background activity'; Category='Browser'; Impact='Medium';
        Description='Turns off Edge startup boost/background mode using user policies. Edge may show Managed by your organization.';
        Changes=@(
            @{Path='HKCU:\Software\Policies\Microsoft\Edge'; Name='StartupBoostEnabled'; Value=0; Kind='DWord'},
            @{Path='HKCU:\Software\Policies\Microsoft\Edge'; Name='BackgroundModeEnabled'; Value=0; Kind='DWord'}
        )
    },
    [pscustomobject]@{
        Id='gamecapture'; Title='Disable background game capture'; Category='Gaming'; Impact='Medium';
        Description='Disables per-user background game capture, which is not suitable if you record gameplay.';
        Changes=@(
            @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR'; Name='AppCaptureEnabled'; Value=0; Kind='DWord'},
            @{Path='HKCU:\System\GameConfigStore'; Name='GameDVR_Enabled'; Value=0; Kind='DWord'}
        )
    }
)

function Get-BenCoreOptions { return $script:Options }
function Get-BenCorePaths { return [pscustomobject]@{ Root=$script:Root; Logs=$script:LogDir; Sessions=$script:SessionDir } }

function Get-BenCoreSystemInfo {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
    $total = [double]$os.TotalVisibleMemorySize * 1KB
    $free = [double]$os.FreePhysicalMemory * 1KB
    $driveID = $env:SystemDrive
    $drive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$driveID'" -ErrorAction SilentlyContinue
    $top = @(Get-Process -ErrorAction SilentlyContinue | Sort-Object WorkingSet64 -Descending | Select-Object -First 6 | ForEach-Object {
        [pscustomobject]@{ Name=$_.ProcessName; RAM=('{0:N0} MB' -f ($_.WorkingSet64/1MB)); PID=$_.Id }
    })
    $totalGB = [math]::Round($total/1GB, 1)
    $freeGB = [math]::Round($free/1GB, 1)
    $usedPercent = if ($total -gt 0) { [math]::Round((($total - $free)/$total)*100, 0) } else { 0 }
    $profile = if ($totalGB -le 6.5) { 'Lite' } elseif ($totalGB -lt 23.5) { 'Balanced' } else { 'Workstation' }
    return [pscustomobject]@{
        Computer=$env:COMPUTERNAME; Windows=$os.Caption; Version=$os.Version;
        CPU=if ($cpu) {$cpu.Name.Trim()} else {'Unavailable'};
        RAMTotalGB=$totalGB; RAMFreeGB=$freeGB; RAMUsedPercent=$usedPercent;
        DriveFreeGB=if ($drive) {[math]::Round(($drive.FreeSpace/1GB),1)} else {0};
        DriveTotalGB=if ($drive) {[math]::Round(($drive.Size/1GB),1)} else {0};
        ProcessCount=@(Get-Process -ErrorAction SilentlyContinue).Count;
        Profile=$profile; TopProcesses=$top; Timestamp=(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
}

function Get-BenCoreProfileOptions {
    param([ValidateSet('Lite','Balanced','Workstation')][string]$Profile)
    switch ($Profile) {
        'Lite' { return @('animations','transparency','suggestions','widgets','ads','search') }
        'Balanced' { return @('animations','transparency','suggestions','ads') }
        'Workstation' { return @('suggestions','ads') }
    }
}

function Get-BenCorePreview {
    param([string[]]$Ids)
    $result = @()
    foreach ($option in $script:Options) {
        if (@($Ids) -notcontains $option.Id) { continue }
        foreach ($target in @($option.Changes)) {
            $old = Get-BenCoreRegistryValue -Path $target.Path -Name $target.Name
            $unchanged = $old.Exists -and ($old.Kind -eq $target.Kind) -and ([string]$old.Value -ceq [string]$target.Value)
            $result += [pscustomobject]@{
                Option=$option.Title; Path=$target.Path; Name=$target.Name;
                Before=if ($old.Exists) {[string]$old.Value} else {'(not set)'};
                After=[string]$target.Value;
                Action=if ($unchanged) {'Already set'} else {'Will change'}
            }
        }
    }
    return $result
}

function Invoke-BenCoreOptimize {
    param([string[]]$Ids)
    $known = @($script:Options | ForEach-Object { $_.Id })
    foreach ($id in @($Ids)) { if ($known -notcontains $id) { throw "Unknown optimization: $id" } }
    $changes = New-Object 'System.Collections.Generic.List[object]'
    $session = [pscustomobject]@{
        Id=[guid]::NewGuid().ToString('N'); CreatedAt=(Get-Date).ToString('s');
        Status='Prepared'; Selected=@($Ids); Changes=@(); Error='';
        Note='Per-user registry changes only. Restart or sign out to see all UI changes.'
    }
    $file = Join-Path $script:SessionDir ($session.CreatedAt.Replace(':','-')+'-'+$session.Id+'.json')
    foreach ($option in $script:Options) {
        if (@($Ids) -notcontains $option.Id) { continue }
        foreach ($target in @($option.Changes)) {
            $old = Get-BenCoreRegistryValue -Path $target.Path -Name $target.Name
            if ($old.Exists -and $old.Kind -eq $target.Kind -and ([string]$old.Value -ceq [string]$target.Value)) { continue }
            $changes.Add([pscustomobject]@{
                Id=$option.Id; Path=$target.Path; Name=$target.Name;
                OldExists=$old.Exists; OldValue=$old.Value; OldKind=$old.Kind;
                NewValue=$target.Value; NewKind=$target.Kind
            })
        }
    }
    $session.Changes = @($changes.ToArray())
    Save-BenCoreJson -Path $file -Data $session  # durable backup BEFORE changing the registry
    $completed = New-Object 'System.Collections.Generic.List[object]'
    try {
        foreach ($change in $session.Changes) {
            # Add to rollback list first, so an exception after a partial write cannot strand a change.
            $completed.Add($change)
            Set-BenCoreRegistryValue -Path $change.Path -Name $change.Name -Value $change.NewValue -Kind $change.NewKind
        }
        $session.Status='Applied'
        Save-BenCoreJson -Path $file -Data $session
        Write-BenCoreLog "Applied session $($session.Id) with $($completed.Count) registry changes."
        return [pscustomobject]@{ Ok=$true; Count=$completed.Count; File=$file; Message='Optimizations applied. Sign out/in if UI changes do not appear.' }
    } catch {
        $errorMessage=$_.Exception.Message
        $rollbackErrors=@()
        $reverse=@($completed.ToArray()); [array]::Reverse($reverse)
        foreach ($change in $reverse) {
            try { Restore-BenCoreRegistryValue -Change $change }
            catch { $rollbackErrors += $_.Exception.Message }
        }
        $session.Status=if ($rollbackErrors.Count -gt 0) {'RollbackFailed'} else {'RolledBack'}
        $session.Error="$errorMessage | rollback: $($rollbackErrors -join '; ')"
        Save-BenCoreJson -Path $file -Data $session
        Write-BenCoreLog "Optimization failed: $($session.Error)" 'ERROR'
        throw "BenCore could not finish: $($session.Error)"
    }
}

function Get-BenCoreSessions {
    $result=@()
    foreach ($f in @(Get-ChildItem -LiteralPath $script:SessionDir -Filter '*.json' -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)) {
        try {
            $entry = Get-Content -LiteralPath $f.FullName -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            $result += [pscustomobject]@{ Date=$entry.CreatedAt; Status=$entry.Status; Changes=@($entry.Changes).Count; Id=$entry.Id; File=$f.FullName }
        } catch { Write-BenCoreLog "Unreadable session backup: $($f.Name)" 'WARN' }
    }
    return $result
}

function Restore-BenCoreSession {
    param([string]$File)
    $resolved = [System.IO.Path]::GetFullPath($File)
    $sessionRoot = [System.IO.Path]::GetFullPath($script:SessionDir).TrimEnd('\') + '\'
    if (-not $resolved.StartsWith($sessionRoot, [StringComparison]::OrdinalIgnoreCase)) { throw 'Restore file must be within the BenCore Sessions folder.' }
    $session = Get-Content -LiteralPath $resolved -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
    if (@('Applied','PartiallyRestored','Prepared','RollbackFailed') -notcontains $session.Status) { throw 'This session is not eligible for restore.' }
    $errors=@(); $restored=0; $skipped=0
    $entries=@($session.Changes); [array]::Reverse($entries)
    foreach ($change in $entries) {
        try {
            $current = Get-BenCoreRegistryValue -Path $change.Path -Name $change.Name
            # Do not overwrite settings the user (or another application) changed since optimization.
            if (-not $current.Exists -or $current.Kind -ne $change.NewKind -or [string]$current.Value -cne [string]$change.NewValue) {
                $skipped++; continue
            }
            Restore-BenCoreRegistryValue -Change $change
            $restored++
        } catch { $errors += $_.Exception.Message }
    }
    $session.Status = if ($skipped -gt 0 -or $errors.Count -gt 0) { 'PartiallyRestored' } else { 'Restored' }
    $session | Add-Member -NotePropertyName LastRestore -NotePropertyValue (Get-Date).ToString('s') -Force
    $session | Add-Member -NotePropertyName LastRestoreSummary -NotePropertyValue "Restored=$restored Skipped=$skipped Errors=$($errors.Count)" -Force
    Save-BenCoreJson -Path $resolved -Data $session
    Write-BenCoreLog "Restore $($session.Id): restored=$restored; skipped=$skipped; errors=$($errors.Count)"
    return [pscustomobject]@{ Restored=$restored; Skipped=$skipped; Errors=$errors; Status=$session.Status }
}

function Restore-BenCoreLastSession {
    $latest=Get-BenCoreSessions | Where-Object { @('Applied','PartiallyRestored','Prepared','RollbackFailed') -contains $_.Status } | Select-Object -First 1
    if ($null -eq $latest) { throw 'No applied BenCore session is available to restore.' }
    return Restore-BenCoreSession -File $latest.File
}

# Startup app control: HKCU Run only (does not touch scheduled tasks or machine-wide apps).
$script:RunPath='HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
function Read-BenCoreDisabledStartup {
    if (-not (Test-Path -LiteralPath $script:DisabledStartupPath)) { return @() }
    try {
        $record=Get-Content -LiteralPath $script:DisabledStartupPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
        return @($record.Items | Where-Object { $null -ne $_ })
    } catch { throw "Cannot read saved startup applications. $($_.Exception.Message)" }
}
function Save-BenCoreDisabledStartup { param([object[]]$Items)
    Save-BenCoreJson -Path $script:DisabledStartupPath -Data ([pscustomobject]@{Items=@($Items)})
}
function Get-BenCoreStartupEntries {
    $result=@()
    $reg=Get-Item -LiteralPath $script:RunPath -ErrorAction SilentlyContinue
    if ($reg) {
        foreach ($name in @($reg.GetValueNames() | Sort-Object)) {
            $v=Get-BenCoreRegistryValue -Path $script:RunPath -Name $name
            $result += [pscustomobject]@{ Name=$name; Status='Enabled'; Command=[string]$v.Value; Kind=$v.Kind }
        }
    }
    foreach ($saved in @(Read-BenCoreDisabledStartup)) {
        $exists=Get-BenCoreRegistryValue -Path $script:RunPath -Name $saved.Name
        $result += [pscustomobject]@{ Name=[string]$saved.Name; Status=if ($exists.Exists) {'Conflict'} else {'Disabled'}; Command=[string]$saved.Command; Kind=[string]$saved.Kind }
    }
    return @($result | Sort-Object Name,Status)
}
function Set-BenCoreStartupEnabled {
    param([string]$Name, [bool]$Enabled)
    if ([string]::IsNullOrWhiteSpace($Name)) { throw 'Select a startup entry first.' }
    $disabled=@(Read-BenCoreDisabledStartup)
    $saved=@($disabled | Where-Object { $_.Name -ceq $Name } | Select-Object -First 1)
    $current=Get-BenCoreRegistryValue -Path $script:RunPath -Name $Name
    if ($Enabled) {
        if ($saved.Count -eq 0) { throw 'No BenCore-disabled entry found for this name.' }
        if ($current.Exists) { throw 'A startup entry with the same name already exists. Nothing was overwritten.' }
        $entry=$saved[0]
        if (@('String','ExpandString') -notcontains $entry.Kind) { throw 'Unsupported startup value type. No change made.' }
        Set-BenCoreRegistryValue -Path $script:RunPath -Name $Name -Value $entry.Command -Kind $entry.Kind
        try { Save-BenCoreDisabledStartup -Items @($disabled | Where-Object { $_.Name -cne $Name }) }
        catch { Remove-ItemProperty -LiteralPath $script:RunPath -Name $Name -ErrorAction SilentlyContinue; throw }
        Write-BenCoreLog "Restored startup entry '$Name'."
        return
    }
    if (-not $current.Exists) { throw 'Startup entry no longer exists. Refresh the list.' }
    if (@('String','ExpandString') -notcontains $current.Kind) { throw 'Only string and expandable-string startup values can be safely managed.' }
    if ($saved.Count -gt 0) { throw 'A saved entry with this name already exists. Resolve conflict before proceeding.' }
    $newList=@($disabled) + @([pscustomobject]@{ Name=$Name; Command=[string]$current.Value; Kind=$current.Kind; DisabledAt=(Get-Date).ToString('s') })
    Save-BenCoreDisabledStartup -Items $newList
    try { Remove-ItemProperty -LiteralPath $script:RunPath -Name $Name -ErrorAction Stop }
    catch { Save-BenCoreDisabledStartup -Items $disabled; throw }
    Write-BenCoreLog "Disabled startup entry '$Name' (recoverable)."
}

Export-ModuleMember -Function Get-BenCoreOptions,Get-BenCorePaths,Get-BenCoreSystemInfo,Get-BenCoreProfileOptions,Get-BenCorePreview,Invoke-BenCoreOptimize,Get-BenCoreSessions,Restore-BenCoreLastSession,Restore-BenCoreSession,Get-BenCoreStartupEntries,Set-BenCoreStartupEnabled,Write-BenCoreLog
