Clean Windows 11 Pro install and setup for my notebook. Plain scripts, no dotfile manager.

```
install/
  autounattend.xml   hands-off Windows install except the disk page (EN UI, US + SK QWERTY keyboard, local account BB)
  firstlogon.ps1     run once by autounattend: regional settings, then debloat.ps1
  debloat.ps1        removes junk apps, turns off Copilot/Recall/widgets/ads, dev settings - rerun after big updates
  apps.ps1           installs apps (winget, Scoop for standalone CLI tools, PS modules), enables Hyper-V - rerun any time
  devdrive.ps1       optional: creates a Dev Drive for projects
config/              settings to copy by hand (PowerShell profile, Office)
```

## Before the reinstall

1. **Back up** anything on C: you want to keep (Desktop, Downloads, `%USERPROFILE%\.claude`, `.ssh`, `.gitconfig`, VS Code profile export) to **B:** (backup partition, 300 GB, same NVMe). B: survives the reinstall, but it is on the same disk - keep anything irreplaceable on the NAS too (disk failure or theft takes both).
2. **Know your partitions.** `autounattend.xml` never touches the disk - setup stops at the disk page and you pick (see Install). Give B: the volume label **Backup** so it is obvious there, and note the layout in the current Windows:
   ```powershell
   Get-Partition -DiskNumber 0 | Sort-Object Offset | Format-Table PartitionNumber, DriveLetter, Type, @{n='GB';e={[math]::Round($_.Size/1GB,1)}}
   ```
   **Unplug every other USB drive** (backup disks, card readers) before booting the installer - only the install stick may be connected, so the disk page shows just the NVMe and the stick.
   If B: is BitLocker-encrypted, have its **recovery key in Vaultwarden** - after the reinstall it stays locked until you enter it.
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

1. Boot from the USB (F9 boot menu on HP). Keep the stick plugged in until the desktop appears. Setup stops **once**, at "Select location to install Windows 11" (Disk 0 = the 1.9 TB KIOXIA):
   - **Leave alone:** System (~0.5 GB), MSR (~0.1 GB), Recovery (~1 GB, maybe two), **Backup (300 GB)**.
   - Select the old **Windows** partition (~1.6-1.9 TB) → **Delete**.
   - Select the **Unallocated space** it leaves → **Next**. Setup creates the partition and reuses the existing System and Recovery ones.
   - On a new, empty SSD: just select the unallocated disk → **Next**.

   From there it runs on its own, offline (no Wi-Fi page):
   - removes the junk apps from the image before the first profile exists (log: `C:\Windows\Temp\bb-debloat-system.log`)
   - creates local account **BB** with an empty password, logs in once and runs `firstlogon.ps1`: English (World) formats, home location Czech Republic, US + Slovak QWERTY keyboard, gives the backup partition its **B:** letter back, then `debloat.ps1` (log: `C:\Windows\Temp\bb-firstlogon.log`)

   If the installer ignores the answer file (asks for language, product key or edition), pick **Previous version of Setup** on its first screen.
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
8. BitLocker. First check WinRE in an admin shell: `reagentc /info` must say **Enabled**, with a location on a Recovery partition (`...\partitionN\Recovery\WindowsRE`, N not the C: partition). Then Control Panel → BitLocker Drive Encryption → Turn on, and save the recovery key **in Vaultwarden**. For B:, if it was encrypted before, unlock it with its recovery key, then turn on auto-unlock (`Enable-BitLockerAutoUnlock -MountPoint B:`); if not, encrypt it too and save that key as well.
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
