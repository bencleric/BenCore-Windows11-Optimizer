# BenCore v1.0 — User guide

## Dashboard

The main page shows a snapshot of operating system details, CPU, total and free RAM, memory-usage percentage, system-drive capacity, process count and a list of memory-heavy processes. Select **Refresh** to request a new snapshot. These values are informational, not an automated speed test.

## Optimize

Profiles are suggested from installed RAM:

| Profile | Typical recommendation | Selected options |
|---|---|---|
| Lite | About 6 GB RAM or less | Animations, transparency, suggestions, Widgets, advertising ID, search highlights |
| Balanced | Approximately 8–16 GB RAM | Animations, transparency, suggestions, advertising ID |
| Workstation | Approximately 24 GB RAM and above | Suggestions, advertising ID |

**Important:** The underlying profile thresholds are implementation defaults, not official Windows memory recommendations. Profiles only pre-select checkboxes. You may select or deselect each setting before any change is applied.

### Exact setting categories

- **Lighter animations:** menu display delay, taskbar animations and minimize animations.
- **Reduce transparency:** Windows transparency effects.
- **Reduce suggestions:** selected ContentDeliveryManager promotional values.
- **Hide taskbar Widgets:** hides the taskbar entry without uninstalling Widgets.
- **Disable personalized advertising ID:** privacy preference rather than a speed optimization.
- **Hide search highlights:** stops selected dynamic search content.
- **Reduce Microsoft Edge background activity:** current-user Edge startup boost/background-mode policies; may display **Managed by your organization**.
- **Disable background game capture:** user settings for Game DVR; avoid if you record game clips.

**Preview changes** is read-only. **Apply selected optimizations** stores prior values and asks for confirmation. Signing out/in may be necessary before appearance settings take effect.

## Startup Apps

The table shows entries from `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` and entries previously disabled by BenCore. Select an item and choose **Disable** or **Restore**. BenCore saves the original startup command before removing it. Conflicting names are not overwritten automatically.

This does not manage system-wide entries, scheduled tasks, Windows services or startup-folder shortcuts. For those, use Windows **Settings → Apps → Startup** or Task Manager and exercise caution.

## Recovery

The Recovery list shows previous sessions. Select a session and restore it. BenCore compares each current value to what it previously applied and skips values since modified by another application/user. Startup changes are tracked separately via `disabled-startup.json` and restored from **Startup Apps**, not via a registry session.

## About

Product: **BenCore**  
Tagline: **Optimize the Core. Unleash the Performance.**  
Developer: **Benie Mansueto Vison**  
Current source release: **v1.0**

## Frequently asked questions

**Will this increase my installed RAM?** No. It cannot add physical RAM or guarantee better frame rates.

**Does it disable Defender or Windows Update?** No.

**Can I use it on a 4 GB PC?** Yes, the interface is intended to be compatible with supported Windows 11 systems, but the improvement may be small. Close unnecessary apps, manage startups, keep enough storage free, and consider an SSD/RAM upgrade where supported.

**Why is a setting not changing?** Windows build differences or corporate policies can override it.

**Does it delete apps or files?** It does not uninstall packages or run cleanup of personal files.

**Why is there no installer or EXE?** v1.0 is a PowerShell/WPF application launched through `Start-BenCore.cmd`.

**Is it fully tested?** Not yet; basic offline checks are not a substitute for end-to-end Windows tests.
