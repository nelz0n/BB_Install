Clean Windows 11 Pro install and setup for my notebook. Plain scripts, no dotfile manager.

```
install/
  autounattend.xml   hands-off Windows install (EN UI, SK keyboard, local account BB)
  debloat.ps1        removes junk apps, turns off Copilot/Recall/widgets/ads - rerun after big updates
  apps.ps1           installs apps with winget - rerun any time
config/              settings to copy by hand (PowerShell profile, VS Code, Claude)
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
3. Windows Update until nothing is left; HP Image Assistant for HP drivers + BIOS.
4. `install\apps.ps1`.
5. Office via ODT (classic Outlook), sign in to OneDrive and Teams.
6. Turn on BitLocker (Settings → Privacy & security → Device encryption / BitLocker) and back up the recovery key.
7. Copy settings from `config/`.

## After a big Windows update

If apps or ads come back, run (as admin):

```powershell
powershell -ExecutionPolicy Bypass -File .\install\debloat.ps1
```
