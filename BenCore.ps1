# BenCore v1.0 | Optimize the Core. Unleash the Performance.
# Developed by Benie Mansueto Vison
# Launch with Start-BenCore.cmd on Windows 11 (Windows PowerShell 5.1, STA).
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2.0

if ($env:OS -ne 'Windows_NT') { throw 'BenCore requires Windows.' }
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    throw 'BenCore needs a single-threaded apartment (STA). Launch Start-BenCore.cmd.'
}
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Import-Module (Join-Path $PSScriptRoot 'BenCore.Engine.psm1') -Force -ErrorAction Stop

[xml]$xaml = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'BenCore.UI.xaml') -Raw -Encoding UTF8
$reader = New-Object System.Xml.XmlNodeReader($xaml)
$script:Window = [Windows.Markup.XamlReader]::Load($reader)
$script:Controls = @{}
@(
    'NavDashboard','NavOptimize','NavStartup','NavRecovery','NavAbout',
    'BtnRefresh','BtnGoOptimize','BtnGoStartup','BtnWindowsStorage',
    'TxtDevice','TxtHardware','TxtSuggestedProfile','TxtRAM','TxtUsed','TxtFree','TxtProcesses',
    'TxtDiskInfo','TxtStatus','GridProcesses','CboProfile','PanelOptions',
    'BtnPreview','BtnApply','GridStartup','BtnStartupSettings','BtnStartupRefresh',
    'BtnStartupDisable','BtnStartupEnable','GridSessions','BtnOpenLogs','BtnOpenBackups',
    'BtnRecoveryRefresh','BtnRestoreSelected','PageDashboard','PageOptimize','PageStartup',
    'PageRecovery','PageAbout'
) | ForEach-Object {
    $control = $script:Window.FindName($_)
    if ($null -eq $control) { throw "Missing user interface control: $_" }
    $script:Controls[$_] = $control
}
$script:OptionChecks = @{}
$script:Pages = @('Dashboard','Optimize','Startup','Recovery','About')

function Set-BenCoreStatus {
    param([string]$Message)
    $script:Controls['TxtStatus'].Text = $Message
}

function Show-BenCoreError {
    param([string]$Message)
    try { Write-BenCoreLog -Level 'ERROR' -Message $Message } catch { }
    Set-BenCoreStatus "Error: $Message"
    [System.Windows.MessageBox]::Show($script:Window, $Message, 'BenCore - Action not completed', 'OK', 'Error') | Out-Null
}

function Show-BenCorePage {
    param([ValidateSet('Dashboard','Optimize','Startup','Recovery','About')][string]$Page)
    foreach ($key in $script:Pages) {
        $pageControl = $script:Controls['Page' + $key]
        $pageControl.Visibility = if ($key -eq $Page) {[System.Windows.Visibility]::Visible} else {[System.Windows.Visibility]::Collapsed}
        $button = $script:Controls['Nav' + $key]
        if ($key -eq $Page) { $button.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#223E56'); $button.Foreground=[System.Windows.Media.Brushes]::White }
        else { $button.Background=[System.Windows.Media.Brushes]::Transparent; $button.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString('#AAB9D3') }
    }
    if ($Page -eq 'Startup') { Refresh-BenCoreStartups }
    if ($Page -eq 'Recovery') { Refresh-BenCoreSessions }
    Set-BenCoreStatus "Viewing $Page • Nothing runs automatically."
}

function Refresh-BenCoreSnapshot {
    try {
        $info = Get-BenCoreSystemInfo
        $script:Controls['TxtDevice'].Text = "$($info.Computer)  •  $($info.Windows)"
        $script:Controls['TxtHardware'].Text = $info.CPU
        $script:Controls['TxtRAM'].Text = "$($info.RAMTotalGB) GB"
        $script:Controls['TxtUsed'].Text = "$($info.RAMUsedPercent)%"
        $script:Controls['TxtFree'].Text = "$($info.RAMFreeGB) GB"
        $script:Controls['TxtProcesses'].Text = [string]$info.ProcessCount
        $script:Controls['TxtSuggestedProfile'].Text = $info.Profile
        $script:Controls['TxtDiskInfo'].Text = "System drive free: $($info.DriveFreeGB) GB of $($info.DriveTotalGB) GB."
        $script:Controls['GridProcesses'].ItemsSource = @($info.TopProcesses)
        # Set suggested profile initially; later scans do not overwrite custom selections.
        if (-not $script:ProfileInitialized) {
            for ($index = 0; $index -lt $script:Controls['CboProfile'].Items.Count; $index++) {
                if ($script:Controls['CboProfile'].Items[$index].Content -eq $info.Profile) {
                    $script:Controls['CboProfile'].SelectedIndex=$index
                    break
                }
            }
            $script:ProfileInitialized=$true
        }
        Set-BenCoreStatus "Scan complete at $($info.Timestamp)."
    } catch { Show-BenCoreError "Cannot read system information: $($_.Exception.Message)" }
}

function Refresh-BenCoreStartups {
    try {
        $items=@(Get-BenCoreStartupEntries)
        $script:Controls['GridStartup'].ItemsSource = $items
        Set-BenCoreStatus "Found $($items.Count) current-user startup entries."
    } catch { Show-BenCoreError "Cannot load startup entries: $($_.Exception.Message)" }
}

function Refresh-BenCoreSessions {
    try {
        $items=@(Get-BenCoreSessions)
        $script:Controls['GridSessions'].ItemsSource = $items
        Set-BenCoreStatus "Found $($items.Count) local optimization sessions."
    } catch { Show-BenCoreError "Cannot load backup history: $($_.Exception.Message)" }
}

function New-BenCoreOptionCard {
    param([object]$Option)
    $border = New-Object System.Windows.Controls.Border
    $border.Background = ([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#151F34')
    $border.BorderBrush = ([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#27344C')
    $border.BorderThickness = [System.Windows.Thickness]::new(1)
    $border.CornerRadius = [System.Windows.CornerRadius]::new(12)
    $border.Padding = [System.Windows.Thickness]::new(18,13,18,13)
    $border.Margin = [System.Windows.Thickness]::new(0,0,0,9)
    $stack = New-Object System.Windows.Controls.StackPanel
    $top = New-Object System.Windows.Controls.DockPanel
    $check = New-Object System.Windows.Controls.CheckBox
    $check.Content = $Option.Title
    $check.FontWeight = [System.Windows.FontWeights]::SemiBold
    [System.Windows.Controls.DockPanel]::SetDock($check,[System.Windows.Controls.Dock]::Left)
    $top.Children.Add($check) | Out-Null
    $category = New-Object System.Windows.Controls.TextBlock
    $category.Text = "$( $Option.Category.ToUpperInvariant() )  •  IMPACT: $($Option.Impact.ToUpperInvariant())"
    $category.HorizontalAlignment = [System.Windows.HorizontalAlignment]::Right
    $category.Foreground = ([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#78C8DC')
    $category.FontSize=10
    $top.Children.Add($category) | Out-Null
    $stack.Children.Add($top) | Out-Null
    $desc = New-Object System.Windows.Controls.TextBlock
    $desc.Text = $Option.Description
    $desc.TextWrapping = [System.Windows.TextWrapping]::Wrap
    $desc.Foreground = ([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#91A3BE')
    $desc.Margin = [System.Windows.Thickness]::new(23,5,0,0)
    $desc.FontSize=12
    $stack.Children.Add($desc) | Out-Null
    $border.Child = $stack
    $script:OptionChecks[$Option.Id] = $check
    return $border
}

function Set-BenCoreProfile {
    $selected = $script:Controls['CboProfile'].SelectedItem
    if ($null -eq $selected) { return }
    $profile=[string]$selected.Content
    $ids=@(Get-BenCoreProfileOptions -Profile $profile)
    foreach ($key in @($script:OptionChecks.Keys)) {
        $script:OptionChecks[$key].IsChecked = ($ids -contains $key)
    }
    Set-BenCoreStatus "$profile profile loaded. Review selections before applying."
}

function Get-BenCoreSelectedIds {
    $ids=@()
    foreach ($option in @(Get-BenCoreOptions)) {
        if ($script:OptionChecks[$option.Id].IsChecked -eq $true) { $ids += $option.Id }
    }
    return $ids
}

function Show-BenCoreTextDialog {
    param([string]$Title, [string]$Text)
    $dialog = New-Object System.Windows.Window
    $dialog.Owner=$script:Window
    $dialog.Title=$Title
    $dialog.Width=900; $dialog.Height=580
    $dialog.MinWidth=650; $dialog.MinHeight=400
    $dialog.WindowStartupLocation='CenterOwner'
    $dialog.Background=([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#0F192C')
    $grid=New-Object System.Windows.Controls.Grid
    $grid.Margin=[System.Windows.Thickness]::new(19)
    $row1=New-Object System.Windows.Controls.RowDefinition
    $row1.Height=[System.Windows.GridLength]::new(1,[System.Windows.GridUnitType]::Star)
    $row2=New-Object System.Windows.Controls.RowDefinition
    $row2.Height=[System.Windows.GridLength]::new(48)
    $grid.RowDefinitions.Add($row1); $grid.RowDefinitions.Add($row2)
    $content=New-Object System.Windows.Controls.TextBox
    $content.Text=$Text
    $content.IsReadOnly=$true
    $content.AcceptsReturn=$true
    $content.TextWrapping=[System.Windows.TextWrapping]::NoWrap
    $content.VerticalScrollBarVisibility='Auto'
    $content.HorizontalScrollBarVisibility='Auto'
    $content.Background=([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#16243B')
    $content.Foreground=[System.Windows.Media.Brushes]::White
    $content.FontFamily=[System.Windows.Media.FontFamily]::new('Consolas')
    $content.FontSize=12
    $content.Padding=[System.Windows.Thickness]::new(13)
    $grid.Children.Add($content) | Out-Null
    $close=New-Object System.Windows.Controls.Button
    $close.Content='Close preview'
    $close.Width=125; $close.Height=35
    $close.HorizontalAlignment='Right'
    $close.Margin=[System.Windows.Thickness]::new(0,11,0,0)
    $close.Background=([System.Windows.Media.BrushConverter]::new()).ConvertFromString('#62D6F6')
    $close.Foreground=[System.Windows.Media.Brushes]::Black
    $close.Tag=$dialog
    $close.Add_Click({ param($sender,$eventArgs) $sender.Tag.Close() })
    [System.Windows.Controls.Grid]::SetRow($close,1)
    $grid.Children.Add($close) | Out-Null
    $dialog.Content=$grid
    $dialog.ShowDialog() | Out-Null
}

function Preview-BenCoreChanges {
    try {
        $ids=@(Get-BenCoreSelectedIds)
        if ($ids.Count -eq 0) {
            [System.Windows.MessageBox]::Show($script:Window,'No optimizations are selected.','BenCore Preview','OK','Information') | Out-Null
            return
        }
        $preview=@(Get-BenCorePreview -Ids $ids)
        $toChange=@($preview | Where-Object {$_.Action -eq 'Will change'}).Count
        $lines=@('BENCORE v1.0 - OPTIMIZATION PREVIEW','Optimize the Core. Unleash the Performance.',
            "Selected categories: $($ids.Count)","Values to modify: $toChange","Values already configured: $($preview.Count - $toChange)",
            '', 'NO CHANGES HAVE BEEN MADE.', 'All changes are for the current Windows user.', 'Settings may require sign-out or restart to be visible.','')
        foreach ($entry in $preview) {
            $lines+= "[$($entry.Action)] $($entry.Option)"
            $lines+= "  $($entry.Path)"
            $lines+= "  $($entry.Name) : $($entry.Before) -> $($entry.After)"
            $lines+=''
        }
        Show-BenCoreTextDialog -Title 'BenCore - Exact registry changes' -Text ($lines -join [Environment]::NewLine)
        Set-BenCoreStatus "Previewed $($preview.Count) values; $toChange changes proposed."
    } catch { Show-BenCoreError "Preview failed: $($_.Exception.Message)" }
}

function Apply-BenCoreChanges {
    try {
        $ids=@(Get-BenCoreSelectedIds)
        if ($ids.Count -eq 0) {
            [System.Windows.MessageBox]::Show($script:Window,'Select one or more options first.','BenCore','OK','Information') | Out-Null; return
        }
        $preview=@(Get-BenCorePreview -Ids $ids)
        $pending=@($preview | Where-Object {$_.Action -eq 'Will change'}).Count
        if ($pending -eq 0) {
            [System.Windows.MessageBox]::Show($script:Window,'All selected settings are already configured. No change is necessary.','BenCore','OK','Information') | Out-Null; return
        }
        $message="BenCore will change $pending per-user Windows registry values across $($ids.Count) selected categories.`n`nA backup will be saved BEFORE changes are applied. No system services or security protections will be disabled.`n`nProceed?"
        $answer=[System.Windows.MessageBox]::Show($script:Window,$message,'Confirm BenCore optimization','YesNo','Question')
        if ($answer -ne [System.Windows.MessageBoxResult]::Yes) { return }
        $script:Window.Cursor=[System.Windows.Input.Cursors]::Wait
        $result=Invoke-BenCoreOptimize -Ids $ids
        $script:Window.Cursor=[System.Windows.Input.Cursors]::Arrow
        Refresh-BenCoreSessions
        Refresh-BenCoreSnapshot
        [System.Windows.MessageBox]::Show($script:Window,"Saved backup and applied $($result.Count) values.`n`nA sign-out or restart may be needed for all effects.",'BenCore - Success','OK','Information') | Out-Null
        Set-BenCoreStatus "Applied $($result.Count) settings. Backup saved."
    } catch {
        $script:Window.Cursor=[System.Windows.Input.Cursors]::Arrow
        Show-BenCoreError "Optimization failed: $($_.Exception.Message)"
    }
}

function Change-BenCoreStartup {
    param([bool]$Enabled)
    try {
        $entry=$script:Controls['GridStartup'].SelectedItem
        if ($null -eq $entry) {
            [System.Windows.MessageBox]::Show($script:Window,'Choose an application in the table.','BenCore','OK','Information') | Out-Null; return
        }
        if ($entry.Status -eq 'Conflict') { throw 'The selected entry conflicts with a saved entry. BenCore will not overwrite it.' }
        if ($Enabled -and $entry.Status -ne 'Disabled') { throw 'Select a BenCore-disabled entry to restore.' }
        if (-not $Enabled -and $entry.Status -ne 'Enabled') { throw 'Select an enabled startup entry to disable.' }
        $verb=if ($Enabled) {'restore'} else {'disable'}
        $message="Do you want to $verb '$($entry.Name)' for your Windows account?`n`nThis only changes whether the program starts automatically when you sign in. It does not uninstall the program."
        if ([System.Windows.MessageBox]::Show($script:Window,$message,'BenCore - Startup manager','YesNo','Question') -ne 'Yes') { return }
        Set-BenCoreStartupEnabled -Name $entry.Name -Enabled:$Enabled
        Refresh-BenCoreStartups
        Set-BenCoreStatus "Startup application '$($entry.Name)' updated."
    } catch { Show-BenCoreError "Startup change failed: $($_.Exception.Message)" }
}

function Restore-BenCoreSelected {
    try {
        $entry=$script:Controls['GridSessions'].SelectedItem
        if ($null -eq $entry) {
            [System.Windows.MessageBox]::Show($script:Window,'Choose a session from the recovery list.','BenCore','OK','Information') | Out-Null; return
        }
        if (@('Applied','PartiallyRestored','Prepared','RollbackFailed') -notcontains $entry.Status) { throw 'This session has already been restored or was rolled back.' }
        $message="Restore session $($entry.Date)?`n`nOnly values still matching what BenCore previously set will be reverted. Changes made by another program are skipped."
        if ([System.Windows.MessageBox]::Show($script:Window,$message,'BenCore - Confirm restore','YesNo','Question') -ne 'Yes') { return }
        $result=Restore-BenCoreSession -File $entry.File
        Refresh-BenCoreSessions
        Refresh-BenCoreSnapshot
        $text="Registry values restored: $($result.Restored)`nSkipped because values have changed: $($result.Skipped)`nErrors: $(@($result.Errors).Count)"
        [System.Windows.MessageBox]::Show($script:Window,$text,'BenCore - Restore result','OK','Information') | Out-Null
        Set-BenCoreStatus "Restore: $($result.Restored) restored, $($result.Skipped) skipped."
    } catch { Show-BenCoreError "Restore failed: $($_.Exception.Message)" }
}

foreach ($option in @(Get-BenCoreOptions)) {
    $panel=New-BenCoreOptionCard -Option $option
    $script:Controls['PanelOptions'].Children.Add($panel) | Out-Null
}
$script:ProfileInitialized=$false
$script:Controls['CboProfile'].Add_SelectionChanged({ if ($script:OptionChecks.Count -gt 0) { Set-BenCoreProfile } })
Set-BenCoreProfile
$script:Controls['NavDashboard'].Add_Click({ Show-BenCorePage -Page 'Dashboard' })
$script:Controls['NavOptimize'].Add_Click({ Show-BenCorePage -Page 'Optimize' })
$script:Controls['NavStartup'].Add_Click({ Show-BenCorePage -Page 'Startup' })
$script:Controls['NavRecovery'].Add_Click({ Show-BenCorePage -Page 'Recovery' })
$script:Controls['NavAbout'].Add_Click({ Show-BenCorePage -Page 'About' })
$script:Controls['BtnRefresh'].Add_Click({ Refresh-BenCoreSnapshot })
$script:Controls['BtnGoOptimize'].Add_Click({ Show-BenCorePage -Page 'Optimize' })
$script:Controls['BtnGoStartup'].Add_Click({ Show-BenCorePage -Page 'Startup' })
$script:Controls['BtnWindowsStorage'].Add_Click({ try { Start-Process 'ms-settings:storage' } catch { Show-BenCoreError $_.Exception.Message } })
$script:Controls['BtnPreview'].Add_Click({ Preview-BenCoreChanges })
$script:Controls['BtnApply'].Add_Click({ Apply-BenCoreChanges })
$script:Controls['BtnStartupSettings'].Add_Click({ try { Start-Process 'ms-settings:startupapps' } catch { Show-BenCoreError $_.Exception.Message } })
$script:Controls['BtnStartupRefresh'].Add_Click({ Refresh-BenCoreStartups })
$script:Controls['BtnStartupDisable'].Add_Click({ Change-BenCoreStartup -Enabled $false })
$script:Controls['BtnStartupEnable'].Add_Click({ Change-BenCoreStartup -Enabled $true })
$script:Controls['BtnRecoveryRefresh'].Add_Click({ Refresh-BenCoreSessions })
$script:Controls['BtnRestoreSelected'].Add_Click({ Restore-BenCoreSelected })
$script:Controls['BtnOpenLogs'].Add_Click({
    try { $dir=(Get-BenCorePaths).Logs; Start-Process explorer.exe -ArgumentList ('"'+$dir+'"') }
    catch { Show-BenCoreError $_.Exception.Message }
})
$script:Controls['BtnOpenBackups'].Add_Click({
    try { $dir=(Get-BenCorePaths).Sessions; Start-Process explorer.exe -ArgumentList ('"'+$dir+'"') }
    catch { Show-BenCoreError $_.Exception.Message }
})

Show-BenCorePage -Page 'Dashboard'
Refresh-BenCoreSnapshot
$script:Window.ShowDialog() | Out-Null
