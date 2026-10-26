Clean Windows 11 Pro install and setup for my notebook. Plain scripts, no dotfile manager.

```
install/
  autounattend.xml   hands-off Windows install (EN UI, US + SK QWERTY keyboard, local account BB)
  firstlogon.ps1     run once by autounattend: regional settings, then debloat.ps1
  debloat.ps1        removes junk apps, turns off Copilot/Recall/widgets/ads, dev settings - rerun after big updates
  apps.ps1           installs apps (winget, Scoop for standalone CLI tools, PS modules), enables Hyper-V - rerun any time
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
   **Unplug every other USB drive** (backup disks, card readers) before booting the installer - only the install stick may be connected.
3. The ZBook's NVMe runs on the standard Windows NVMe driver (Intel VMD is off), so setup sees the disk without extra drivers. Leave VMD off in the BIOS; if you ever turn it on, setup needs the HP Intel RST/VMD driver (put it in a `$WinPEDriver$` folder in the USB root).

## Make the USB

1. Download the Windows 11 **26H2** ISO (or Media Creation Tool) from microsoft.com, English (United States), x64.
2. Write it to a USB stick (8 GB+).
3. Copy **this whole repository** to the USB root, then copy `install\autounattend.xml` to the USB root as well:
   ```
   E:\autounattend.xml
   E:\install\firstlogon.ps1
   E:\install\debloat.ps1
   E:\install\apps.ps1
   ...
   ```

## Install

1. Boot from the USB (F9 boot menu on HP). Keep the stick plugged in until the desktop appears. Setup runs on its own, offline (no Wi-Fi page):
   - wipes disk 0, installs Pro
   - removes the junk apps from the image before the first profile exists (log: `C:\Windows\Temp\bb-debloat-system.log`)
   - creates local account **BB** with an empty password, logs in once and runs `firstlogon.ps1`: English (World) formats, home location Czech Republic, US + Slovak QWERTY keyboard, then `debloat.ps1` (log: `C:\Windows\Temp\bb-firstlogon.log`)

   If the installer ignores the answer file (asks for language/disk), pick **Previous version of Setup** on its first screen.
2. **Check before going further** (a reinstall is cheap now, painful later):
   - `C:\Windows\Temp\bb-firstlogon.log` shows `DeviceRegion = 75`. That is the EEA region (Edge uninstallable, DMA choices) and only a reset can change it.
   - Activation: Settings → System → Activation says active (HP firmware Pro key). If not, in an admin shell: `slmgr /ipk <key>` with the key from `(Get-CimInstance SoftwareLicensingService).OA3xOriginalProductKey`.
3. **Set a password / PIN right away** (Settings → Accounts → Sign-in options). Then connect Wi-Fi.
4. Windows Update until nothing is left, including Advanced options → Optional updates (HP drivers and firmware come this way too). Then rerun `debloat.ps1` (see below) - some apps can arrive with updates.
5. `install\apps.ps1` in a **normal** (not admin) PowerShell - Scoop refuses to install as admin. Restart afterwards (Hyper-V).
   Then HP drivers, BIOS and firmware with **HP Image Assistant** (installed by `apps.ps1`; no HP Support Assistant needed). On AC power, in an admin shell:
   ```powershell
   C:\SWSetup\HPImageAssistant\HPImageAssistant.exe /Operation:Analyze /Action:Install /Selection:All /Category:Drivers,BIOS,Firmware /Silent /ReportFolder:C:\Temp\HPIA
   ```
   Restart afterwards. Rerun every 2-3 months (`winget upgrade HP.ImageAssistant` first).
6. Python and Node through their managers: `uv python install`, `fnm install --lts`.
7. Office: get `setup.exe` from the Office Deployment Tool (microsoft.com), then `setup.exe /configure config\office\office.xml`. Sign in to OneDrive and Teams.
8. BitLocker. First check WinRE in an admin shell: `reagentc /info` must say **Enabled**, with a location on `partition4` (the recovery partition Windows creates after C: on first boot). Then Control Panel → BitLocker Drive Encryption → Turn on, and save the recovery key **in Vaultwarden**.
9. New SSH key (don't copy the old one), add it to the agent and GitHub:
   ```powershell
   ssh-keygen -t ed25519
   ssh-add $HOME\.ssh\id_ed25519
   gh ssh-key add $HOME\.ssh\id_ed25519.pub
   ```
10. Copy settings from `config/` (PowerShell profile → `$PROFILE`). Set the terminal font to **JetBrainsMono Nerd Font** (Windows Terminal → Settings → Defaults → Appearance) so starship and Terminal-Icons show icons.
11. Optional: `install\devdrive.ps1` (admin) for a Dev Drive, then keep projects on it.

## After a big Windows update

If apps or ads come back, run (as admin):

```powershell
powershell -ExecutionPolicy Bypass -File .\install\debloat.ps1
```
