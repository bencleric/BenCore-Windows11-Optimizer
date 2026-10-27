# Security policy

## Scope and current status

BenCore v1.0 makes optional, current-user Windows registry changes and maintains local backup files. It is an initial release and has not undergone third-party security review or complete Windows 11 integration testing.

## Reporting security problems

If the repository supports GitHub private vulnerability reports, use **Security → Report a vulnerability**. Otherwise, contact the repository owner privately through a channel they have explicitly published. **Do not** post exploit details, sensitive logs, passwords, private paths or personal information in public Issues.

## Safe operation

- Inspect downloaded scripts before running them.
- Test on a spare computer or a VM snapshot before applying to production workstations.
- Avoid running unknown copies or modified scripts as administrator.
- BenCore does not require administrator privileges for its present changes.
- Use Recovery to restore sessions where possible. Backups are limited to prior registry values and do not replace a full-device backup.
- Local logs and session backups can contain computer or program information; sanitize before sharing.
