#Requires -RunAsAdministrator
<#
  BB_Toolkit - debloat.ps1
  Removes preinstalled apps and turns off Copilot, Recall, widgets, ads and web search.
  Safe to run again at any time - run it after every big Windows feature update
  (anything that brings back apps or settings).

  Usage (elevated PowerShell):
    powershell -ExecutionPolicy Bypass -File .\install\debloat.ps1
#>

$ErrorActionPreference = 'Continue'

# ----------------------------------------------------------------------------
# 1. Apps to remove (for the current user AND from the system image, so they
#    do not come back for new profiles). Edit this list freely.
# ----------------------------------------------------------------------------
$appsToRemove = @(
    'Clipchamp.Clipchamp'
    'Microsoft.BingNews'
    'Microsoft.BingWeather'
    'Microsoft.BingSearch'
    'Microsoft.Copilot'
    'Microsoft.GetHelp'
    'Microsoft.Getstarted'                 # Tips
    'Microsoft.MicrosoftOfficeHub'         # "Microsoft 365" ad app (real Office is installed separately)
    'Microsoft.MicrosoftSolitaireCollection'
    'Microsoft.MicrosoftStickyNotes'
    'Microsoft.OutlookForWindows'          # "new Outlook" - you use classic desktop Outlook
    'Microsoft.People'
    'Microsoft.PowerAutomateDesktop'
    'Microsoft.Todos'
    'Microsoft.WindowsFeedbackHub'
    'Microsoft.WindowsMaps'
    'Microsoft.WindowsSoundRecorder'
    'Microsoft.ZuneMusic'                  # Media Player
    'Microsoft.YourPhone'                  # Phone Link
    'MicrosoftCorporationII.QuickAssist'
    'MicrosoftWindows.CrossDevice'
    'Microsoft.549981C3F5F10'              # Cortana leftovers
    'MSTeams'                              # consumer Teams; company Teams is installed via apps.ps1
)
# Deliberately KEPT: Store, Xbox apps (games/Game Pass), Calculator, Photos,
# Snipping Tool, Notepad, Terminal, Paint.

Write-Host "`n== Removing apps ==" -ForegroundColor Cyan
foreach ($app in $appsToRemove) {
    $installed = Get-AppxPackage -AllUsers -Name $app -ErrorAction SilentlyContinue
    if ($installed) {
        $installed | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Write-Host "  removed       $app"
    }
    $prov = Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $app
    if ($prov) {
        $prov | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        Write-Host "  deprovisioned $app"
    }
}

# ----------------------------------------------------------------------------
# 2. Policies (HKLM\SOFTWARE\Policies) - these survive updates best.
# ----------------------------------------------------------------------------
function Set-Reg {
    param([string]$Path, [string]$Name, [object]$Value, [string]$Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

Write-Host "`n== Applying policies ==" -ForegroundColor Cyan
$P = 'HKLM:\SOFTWARE\Policies\Microsoft'

# Copilot
Set-Reg "$P\Windows\WindowsCopilot" 'TurnOffWindowsCopilot' 1
# Recall / AI snapshots
Set-Reg "$P\Windows\WindowsAI" 'DisableAIDataAnalysis' 1
Set-Reg "$P\Windows\WindowsAI" 'AllowRecallEnablement' 0
# Widgets
Set-Reg "$P\Dsh" 'AllowNewsAndInterests' 0
# Web/Bing results in Start search
Set-Reg "$P\Windows\Windows Search" 'DisableWebSearch' 1
Set-Reg "$P\Windows\Windows Search" 'ConnectedSearchUseWeb' 0
Set-Reg 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1
# Promoted apps / suggestions (honoured fully only on Enterprise/Education, harmless on Pro)
Set-Reg "$P\Windows\CloudContent" 'DisableWindowsConsumerFeatures' 1
Set-Reg "$P\Windows\CloudContent" 'DisableConsumerAccountStateContent' 1
Set-Reg "$P\Windows\CloudContent" 'DisableSoftLanding' 1
# Telemetry at the lowest level Pro allows
Set-Reg "$P\Windows\DataCollection" 'AllowTelemetry' 1
Set-Reg "$P\Windows\DataCollection" 'DoNotShowFeedbackNotifications' 1
# Advertising ID
Set-Reg "$P\Windows\AdvertisingInfo" 'DisabledByGroupPolicy' 1
# Edge: no first-run wizard, no shopping/sidebar noise
Set-Reg "$P\Edge" 'HideFirstRunExperience' 1
Set-Reg "$P\Edge" 'HubsSidebarEnabled' 0
Set-Reg "$P\Edge" 'EdgeShoppingAssistantEnabled' 0

# ----------------------------------------------------------------------------
# 3. Per-user settings (current user) - ads, tips, Start/taskbar.
# ----------------------------------------------------------------------------
Write-Host "`n== User settings ==" -ForegroundColor Cyan
$CDM = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($n in 'SilentInstalledAppsEnabled','SystemPaneSuggestionsEnabled','SoftLandingEnabled',
               'SubscribedContent-338388Enabled','SubscribedContent-338389Enabled',
               'SubscribedContent-353694Enabled','SubscribedContent-353696Enabled',
               'SubscribedContent-310093Enabled','PreInstalledAppsEnabled','OemPreInstalledAppsEnabled') {
    Set-Reg $CDM $n 0
}
$ADV = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Set-Reg $ADV 'TaskbarAl' 0              # Start button on the left
Set-Reg $ADV 'TaskbarDa' 0              # no widgets button
Set-Reg $ADV 'ShowCopilotButton' 0
Set-Reg $ADV 'HideFileExt' 0            # show file extensions
Set-Reg $ADV 'LaunchTo' 1               # Explorer opens "This PC"
Set-Reg $ADV 'Start_IrisRecommendations' 0
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'SearchboxTaskbarMode' 1   # search icon only
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
Set-Reg 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0

Write-Host "`nDone. Sign out and back in (or restart Explorer) to see all changes." -ForegroundColor Green
