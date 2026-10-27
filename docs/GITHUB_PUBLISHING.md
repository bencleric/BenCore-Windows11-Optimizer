# How to publish BenCore on GitHub

These instructions assume the account owner is `bencleric` and the intended repository is `BenCore-Windows11-Optimizer`. The GitHub repository must be created and files pushed before it exists publicly.

## Recommended repository settings

| GitHub field | Value |
|---|---|
| Owner | `bencleric` |
| Repository name | `BenCore-Windows11-Optimizer` |
| Description | `BenCore is a modern Windows 11 optimization tool featuring a WPF dashboard, RAM-aware profiles, startup management, system diagnostics, and reversible performance tweaks.` |
| Visibility | **Public** if you want anyone to inspect/download it; otherwise **Private** |
| Start with template | **No template** |
| Add README | **Off** (provided in project) |
| Add .gitignore | **No .gitignore** (provided in project) |
| Add license | **No license** until you choose one (see `docs/LICENSING.md`) |

Suggested repository topics (add in **About → gear icon** after creation): `windows11`, `powershell`, `wpf`, `system-optimization`, `desktop-application`, `startup-manager`, `low-ram`, `windows-utilities`.

## Method A — GitHub website (easiest)

1. Sign in to GitHub and open <https://github.com/new>.
2. Enter the settings above and select **Create repository**. Leave initialization options off because the source already includes the README and `.gitignore`.
3. Extract the **BenCore_GitHub_Ready.zip** archive to its own folder on your PC.
4. Open the newly created GitHub repository. Select **uploading an existing file**, or **Add file → Upload files**.
5. Drag **the contents of the extracted folder** into GitHub's upload area, including source scripts, `.github` and `docs`. GitHub accepts folders; make sure `README.md` is in the repository **root**, not nested under an extra folder named after the ZIP.
6. Enter commit message `Initial release: BenCore v1.0 Windows 11 Optimizer` and commit directly to `main` for this initial empty repository.
7. Verify the repository homepage shows the rendered README and that `BenCore.ps1`, `BenCore.Engine.psm1`, `BenCore.UI.xaml`, launchers and `docs/` are visible.
8. Open **Actions**. The workflow **Validate BenCore source** may run; check it for syntax/XML problems. A green check does not mean system tuning has been tested on Windows 11.
9. Add repository topics, optional social preview image, and licensing only after choosing the appropriate terms.

**Important:** Do **not** upload only the ZIP as the main source tree. GitHub will treat it as a binary download and will not render the README or display the source code inside the ZIP. You can optionally attach the ZIP under **Releases** later.

## Method B — Git command line (recommended for future updates)

Install Git for Windows, sign in to GitHub using Git Credential Manager in the browser when prompted, and open PowerShell in the **extracted project root**.

First create an empty repository on GitHub using the settings above. Then run:

```powershell
git init -b main
git add .
git commit -m "Initial release: BenCore v1.0 Windows 11 Optimizer"
git remote add origin https://github.com/bencleric/BenCore-Windows11-Optimizer.git
git push -u origin main
```

If Git asks for author identity, configure a suitable name/email for commits (`git config user.name` / `git config user.email`). Use the GitHub browser authentication flow; **do not paste credentials or access tokens into chat or commit them to the repository**.

For later local edits:

```powershell
git status
git add .
git commit -m "Document BenCore improvements"
git push
```

## Optional release download

After reviewing and testing the app on a Windows 11 test machine, open **Releases → Draft a new release**, create tag `v1.0.0`, write accurate release notes and attach a ready-to-run ZIP if desired. Do not label an untested build as production-safe.

## Check before publishing

- Review every `.ps1`, `.psm1`, `.cmd` and `.xaml` file.
- Remove sensitive information from logs, screenshots or backups (none should be included).
- Never commit passwords, tokens, API keys, private IPs or end-user data.
- Run `Run-Diagnostics.cmd` and exercise apply/restore on a spare Windows PC/VM.
- Decide whether the project needs a license; public visibility alone is **not** an open-source license.
