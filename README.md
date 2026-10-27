# BenCore

**Optimize the Core. Unleash the Performance.**

**Windows 11 Optimization Engine** · **Version 1.0**  
**Developed by Benie Mansueto Vison**

BenCore is a Windows desktop utility written in **Windows PowerShell 5.1** with a **WPF (Windows Presentation Foundation)** interface. It helps you examine your PC, review optional *current-user* Windows settings, manage selected startup applications, and restore changes from local backup sessions.

> **Release status: initial Windows testing required.** This source has been inspected and packaged, but the WPF app and its apply/restore workflows have **not been run end-to-end on a Windows 11 test machine** in the authoring environment. Run diagnostics and test on a spare PC or VM before using it on an important computer.

## Features

| Feature | What it does |
|---|---|
| Modern dashboard | Dark-themed desktop window; CPU, installed/free RAM, memory usage, drive space, process count and top memory-using processes (refresh on demand) |
| Automatic profile suggestion | Recommends Lite, Balanced or Workstation according to installed RAM; recommendations remain optional |
| Optimization preview | Lists each registry value and its proposed before/after state |
| Explicit approval | Does **not** modify settings until you select options and confirm |
| Startup manager | Disables and restores supported entries under the **current user's** Windows `Run` registry key |
| Recovery | Saves prior registry values before changing them; restore skips settings that were subsequently changed |
| Local logging | Stores session backups and logs under `%LOCALAPPDATA%\BenCore` |
| Compatibility diagnostics | Checks script syntax, loads XAML on Windows, scans system info and previews settings without applying changes |

## System requirements

- Windows 11 desktop/laptop (Windows 10 is not an officially tested target).
- **Windows PowerShell 5.1**, with .NET Framework and Windows Presentation Foundation (included in normal Windows 11 installations).
- A desktop user session. The dashboard uses WPF and is not a web application.
- No administrator permission is required for the included current-user registry settings. Organizational policy may block or override some changes.
- No installer, package manager, browser extension or external PowerShell module is required.

## Quick start

1. Download the source from **Code → Download ZIP** on this GitHub repository, or clone it.
2. Extract the files into a folder, for example `C:\BenCore` (do **not** try to run scripts inside the ZIP).
3. Review the source before executing it. If Windows blocks files downloaded from the internet, check **Properties → Unblock** for the downloaded ZIP, only if you trust this source, then extract again.
4. Double-click **`Run-Diagnostics.cmd`**. Check the results before continuing.
5. Double-click **`Start-BenCore.cmd`** to open the desktop dashboard.
6. On **Optimize**, select a profile, inspect the individual selections, click **Preview changes**, then **Apply selected optimizations** only if you approve.
7. Use **Recovery** to select a previous optimization session and restore saved values where safe to do so.

PowerShell alternative (from the extracted folder):

```powershell
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File .\Test-BenCore.ps1
powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File .\BenCore.ps1
```

`-ExecutionPolicy Bypass` is restricted to the **launched PowerShell process** by these commands; it does not set a persistent system execution policy. Review code before running unsigned scripts.

**Detailed documentation:** [Installation](docs/INSTALLATION.md) · [User guide](docs/USER_GUIDE.md) · [GitHub publishing tutorial](docs/GITHUB_PUBLISHING.md)

## Optimization categories

These are the eight categories currently implemented. They operate on selected **HKCU / current-user** registry values only.

| Category | Main behavior | Caveat |
|---|---|---|
| Lighter animations | Reduces selected menu/taskbar animation preferences | Primarily perceived responsiveness, not more CPU/RAM |
| Reduce transparency | Disables Windows transparency for this user | Appearance change |
| Reduce suggestions | Disables selected consumer promotional suggestions | Can differ across Windows builds |
| Hide Widgets | Hides Widgets on taskbar | Does not uninstall Widgets |
| Disable advertising ID | Disables per-user advertising ID | Privacy preference, not a speed boost |
| Hide search highlights | Disables dynamic search box highlights | May be ignored by some builds |
| Limit Edge background activity | Disables startup boost/background mode via user policies | Edge may report **Managed by your organization** |
| Disable background game capture | Disables user-level Game DVR recording controls | Do not select if you record gameplay |

**Profiles are convenience selections, not guarantees.** Lite generally selects six low-impact options; Balanced selects four; Workstation selects two. You can change every selection before applying. Actual performance changes vary by hardware and workload, and some settings primarily affect appearance/privacy.

## What BenCore deliberately does *not* do

BenCore v1.0 does **not** disable Windows Update, Microsoft Defender, Windows Firewall, system services, networking, VPNs, Hyper-V, WSL, Docker, scheduled tasks, or drivers. It does not modify the pagefile, memory-compression configuration, Service Host grouping or boot settings. It does not uninstall Windows applications, clear user files, promise RAM gains, or download third-party software.

For a low-RAM PC, reviewing startup applications, using an SSD, maintaining sufficient free disk space and upgrading RAM (where supported) can matter far more than cosmetic registry tweaks.

## Startup application manager

The manager only handles supported `REG_SZ` / `REG_EXPAND_SZ` values in:

```text
HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run
```

It does not manage `HKLM` startup entries, Task Scheduler, Startup folders, services or every Startup Apps entry visible in Windows Settings. Apps may re-create their entries during an update. Disabled entries are saved so BenCore can restore them.

## Recovery, logs and privacy

```text
%LOCALAPPDATA%\BenCore\
  Logs\                    # Log files
  Sessions\                # Registry value backup sessions
  disabled-startup.json     # Disabled startup items for restoration
```

- Backup sessions record prior values **before** changes are applied. They are **not** full Windows restore points.
- Restore skips values modified by another program or user after BenCore ran.
- Make your own full-device backup or VM snapshot before broader testing.
- No remote API, analytics service, account sign-in or telemetry submission is implemented by BenCore's code.
- Logs and backups remain on the local PC unless you share them yourself. Review logs for machine details before posting them publicly.

## Project files

```text
BenCore.ps1                 # Dashboard controller and event handlers
BenCore.UI.xaml             # WPF user interface
BenCore.Engine.psm1         # Hardware scan, settings, sessions and startup logic
Start-BenCore.cmd           # App launcher
Run-Diagnostics.cmd        # Safe diagnostics launcher
Test-BenCore.ps1            # Read-only compatibility diagnostics
CHANGELOG.md                # Version history
docs/                       # Installation, usage and GitHub tutorials
tools/Test-Source.ps1       # Static source checks
.github/workflows/          # Windows GitHub Actions validation
```

## Troubleshooting

**Window does not open:** Extract the ZIP completely, then run `Run-Diagnostics.cmd` and read its output. Start BenCore in a regular interactive Windows session.  
**Registry option not visible:** Sign out/in or restart, and remember that managed PC policies can override user preferences.  
**Edge says 'Managed by your organization':** BenCore's optional Edge setting writes user policy values; restore the relevant BenCore session to undo them.  
**Restore skipped an item:** BenCore only restores values still matching what it applied, avoiding overwriting later changes.  
**An app still starts automatically:** It may be registered through a different mechanism not managed by BenCore.

More details: [User guide](docs/USER_GUIDE.md).

## Validation and known limitations

- Source XML, file layout and ZIP integrity have been checked outside Windows.
- A GitHub Actions workflow performs script parsing and XAML XML checks on a Windows runner after upload; this is **not** an integration/performance test.
- WPF GUI operations, registry changes and recovery must be tested on a Windows 11 VM/spare PC before deployment.
- No measured performance improvement is claimed or guaranteed.
- No standalone `.exe` or Windows installer is supplied in v1.0; use `Start-BenCore.cmd`.

## Author and project status

Developed by **Benie Mansueto Vison**.  
Tagline: **Optimize the Core. Unleash the Performance.**

BenCore is a separate PowerShell/WPF implementation. It does **not** bundle the original TBOK batch optimizers.

### Licensing

**No open-source license has been selected for this initial public-release package.** Public source availability does not automatically grant permission to redistribute or modify the code. Before inviting outside contributions or redistribution, the repository owner should add an appropriate `LICENSE` file (for example MIT if they wish to allow broad reuse). See [License decisions](docs/LICENSING.md).

**Security:** See [SECURITY.md](SECURITY.md). Do not disclose sensitive log data or personal information in public issues.
