Clean Windows 11 Pro install and setup for my notebook. Plain scripts, no dotfile manager.

```
install/
  autounattend.xml   hands-off Windows install (EN UI, SK keyboard, local account BB)
  debloat.ps1        removes junk apps, turns off Copilot/Recall/widgets/ads, dev settings - rerun after big updates
  apps.ps1           installs apps (winget + Scoop), enables Hyper-V - rerun any time
  devdrive.ps1       optional: creates a Dev Drive for projects
config/              settings to copy by hand (PowerShell profile, Office)
```

## Before the reinstall

1. **Back up** anything on C: you want to keep (Desktop, Downloads, `%USERPROFILE%\.claude`, `.ssh`, `.gitconfig`, VS Code profile export).
2. **Check disk 0 first.** `autounattend.xml` wipes **disk 0** without asking. In the current Windows run:
   ```powershell
   Get-Disk | Format-Table Number, FriendlyName, Size, PartitionStyle
   ```
   Disk 0 must be the system drive, not the one with VMs/games/projects. NVMe numbering in the installer usually matches, but not always. If unsure, switch to manual disk selection by deleting the `<DiskConfiguration>` and `<ImageInstall>` blocks from `autounattend.xml`; setup will then ask where to install.
3. Download HP drivers for the storage controller (Intel RST/VMD) from HP support in case setup does not see the disk.

## Make the USB

1. Download the Windows 11 ISO (or Media Creation Tool) from microsoft.com, English (United States), x64.
2. Write it to a USB stick (8 GB+).
3. Copy **this whole repository** to the USB root, then copy `install\autounattend.xml` to the USB root as well:
   ```
   E:\autounattend.xml
   E:\install\debloat.ps1
   E:\install\apps.ps1
   ...
   ```

## Install

1. Boot from the USB (F9 boot menu on HP). Setup runs on its own: wipes disk 0, installs Pro, creates local account **BB** with an empty password, logs in once and runs `debloat.ps1` (log: `C:\Windows\Temp\bb-debloat.log`).
2. **Set a password / PIN right away** (Settings → Accounts → Sign-in options).
3. Windows Update until nothing is left; HP Image Assistant for HP drivers + BIOS. Then rerun `debloat.ps1` (see below) - some apps (new Outlook, Teams, Copilot) arrive after the first login.
4. `install\apps.ps1` in a **normal** (not admin) PowerShell - Scoop refuses to install as admin. Restart afterwards (Hyper-V).
5. Python and Node through their managers: `uv python install`, `fnm install --lts`.
6. Office: get `setup.exe` from the Office Deployment Tool (microsoft.com), then `setup.exe /configure config\office\office.xml`. Sign in to OneDrive and Teams.
7. Turn on BitLocker (Settings → Privacy & security → Device encryption / BitLocker) and save the recovery key **in Vaultwarden**.
8. New SSH key (don't copy the old one), add it to the agent and GitHub:
   ```powershell
   ssh-keygen -t ed25519
   ssh-add $HOME\.ssh\id_ed25519
   gh ssh-key add $HOME\.ssh\id_ed25519.pub
   ```
9. Copy settings from `config/` (PowerShell profile → `$PROFILE`).
10. Optional: `install\devdrive.ps1` (admin) for a Dev Drive, then keep projects on it.

## After a big Windows update

If apps or ads come back, run (as admin):

```powershell
powershell -ExecutionPolicy Bypass -File .\install\debloat.ps1
```
