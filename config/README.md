# config/

Settings that should be the same on every machine. For now they are simply copied by hand to where they belong.

| File | Copy to / use |
|---|---|
| `powershell/Microsoft.PowerShell_profile.ps1` | `$PROFILE` (PowerShell 7) |
| `office/office.xml` | `setup.exe /configure office\office.xml` (Office Deployment Tool) |

Planned (add when you actually need them):

| File | Copy to |
|---|---|
| `vscode/` (exported "BB" profile) | VS Code → Profiles → Import |
| `claude/settings.json`, MCP config | `%USERPROFILE%\.claude\` |

No passwords, keys or tokens in here - the repo is public. Secrets live in Vaultwarden.
