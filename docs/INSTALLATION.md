# Installation and first-run tutorial

## 1. Download BenCore

Open the BenCore GitHub repository, select **Code → Download ZIP**, and save it to your Windows 11 computer. Alternatively, install Git and clone the repository.

Extract all files into a dedicated folder such as `C:\BenCore`. Do **not** run the commands inside a compressed ZIP or upload the ZIP itself as a substitute for GitHub source files.

If Windows displays **Unblock** in the ZIP's Properties window, review the source and publisher first. Only unblock software you trust.

## 2. Requirements

- Interactive Windows 11 desktop session
- Windows PowerShell 5.1 (`powershell.exe`, not PowerShell 7 `pwsh`)
- .NET Framework / WPF installed with Windows 11
- Normal user rights for the implemented HKCU settings

Do not use BenCore for the first time on a production PC, remote server or an organization-managed machine without permission.

## 3. Run a read-only diagnostic

Double-click `Run-Diagnostics.cmd` or open PowerShell in the extracted directory and run:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\Test-BenCore.ps1
```

The diagnostic checks PowerShell syntax, attempts to load the dashboard, runs a hardware scan and previews one set of settings. It does **not** apply optimizations.

Stop if any check fails. Save the error text (remove personal computer information before sharing).

## 4. Start the desktop application

Double-click `Start-BenCore.cmd`, or run:

```powershell
powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File .\BenCore.ps1
```

The dashboard opens as a WPF desktop window. No web server, browser or installer is used.

## 5. Apply carefully

1. Click **Dashboard → Refresh** to see hardware information.
2. Go to **Optimize**.
3. Review the suggested Lite, Balanced or Workstation profile.
4. Uncheck any feature you do not want. In particular, skip Edge policies if you dislike the managed-policy indication and skip Game DVR controls if you record gameplay.
5. Click **Preview changes** to inspect the exact proposed registry values.
6. Click **Apply selected optimizations** and explicitly approve.
7. If some Windows UI settings do not appear to change, sign out and back in or restart later.

## 6. Restore changes

1. Open **Recovery**.
2. Choose the correct session by date/time.
3. Click **Restore selected** and approve.
4. Check the count of restored, skipped and failed items.
5. Sign out/in if necessary for visual changes.

Recovery is a *best-effort registry-value undo*, not a substitute for a Windows system image or VM snapshot.

## 7. Where data is stored

```text
%LOCALAPPDATA%\BenCore\Logs
%LOCALAPPDATA%\BenCore\Sessions
%LOCALAPPDATA%\BenCore\disabled-startup.json
```

Backup sessions and logs belong to the Windows user who ran BenCore. Avoid publishing them directly on GitHub because they can contain environment or app information.

## 8. Removing BenCore

Restore desired settings and startup entries first, then close the application and delete the source folder. If you no longer need backup logs and history, delete `%LOCALAPPDATA%\BenCore` **after** confirming recovery is complete. Deleting the program folder alone does not automatically reverse prior settings.
