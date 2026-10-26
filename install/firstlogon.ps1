#Requires -RunAsAdministrator
<#
  BB_Toolkit - firstlogon.ps1
  Run once by autounattend.xml at the first logon of BB (log: C:\Windows\Temp\bb-firstlogon.log).
  Not meant to be rerun by hand - for that use debloat.ps1.
#>

$ErrorActionPreference = 'Continue'

# Auto-logon off for good (unattend LogonCount=1 would allow a second auto-logon)
$wl = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
Set-ItemProperty $wl AutoAdminLogon '0'
Set-ItemProperty $wl AutoLogonCount 0 -Type DWord
Remove-ItemProperty $wl DefaultPassword -ErrorAction SilentlyContinue

# Regional settings. Setup ran with cs-CZ so the device region is Czech Republic
# (EEA - DMA choices); now switch the formats to English (World) like before.
Write-Host "`n== Regional settings ==" -ForegroundColor Cyan
Set-Culture en-001
Set-WinHomeLocation -GeoId 75                       # Czech Republic
$langs = New-WinUserLanguageList en-US              # English UI, US keyboard (default)
$langs.Add('sk')
$langs[1].InputMethodTips.Clear()
$langs[1].InputMethodTips.Add('041B:0001041B')      # Slovak (QWERTY)
Set-WinUserLanguageList $langs -Force
# Same for the sign-in screen and new accounts
Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true
# Must be 75 (or another EEA country). If not, reinstall now - it can only be changed by a reset.
$region = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Control Panel\DeviceRegion' -ErrorAction SilentlyContinue).DeviceRegion
Write-Host "  DeviceRegion = $region"

& (Join-Path $PSScriptRoot 'debloat.ps1')

# Reload the taskbar/Explorer settings written by debloat.ps1
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
