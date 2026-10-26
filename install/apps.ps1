<#
  BB_Toolkit - apps.ps1
  Installs apps and enables Hyper-V. Edit the lists, run again any time -
  anything already installed is skipped.

    winget     runtimes, anything other tools link to, GUI apps
    Scoop      standalone CLI tools only (nothing else depends on them)
    PSGallery  PowerShell modules used by the profile

  Usage (normal PowerShell, NOT admin - Scoop refuses to run elevated;
  winget/dism ask for elevation where needed):
    powershell -ExecutionPolicy Bypass -File .\install\apps.ps1

  Find a package:  winget search <name>  /  scoop search <name>
#>

$failed = @()

# Scoop shims and the PS profile need local scripts allowed
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue

# --- winget ---
$apps = @(
    # --- Shell / dev runtimes ---
    'Microsoft.PowerShell'
    'Microsoft.VisualStudioCode'
    'Git.Git'
    'GitHub.cli'
    'gerardog.gsudo'
    'astral-sh.uv'                         # Python via uv (uv python install)
    'Schniz.fnm'                           # Node versions via fnm
    'Oven-sh.Bun'
    'Microsoft.DotNet.SDK.10'
    'JohnMacFarlane.Pandoc'
    'DEVCOM.JetBrainsMonoNerdFont'         # terminal font for starship / Terminal-Icons

    # --- Power BI ---
    'Microsoft.PowerBI'

    # --- AI ---
    'Anthropic.Claude'
    'Anthropic.ClaudeCode'                 # claude CLI

    # --- Work / everyday ---
    'Microsoft.Teams'
    'Microsoft.WindowsApp'                 # Remote Desktop (Windows App)
    'Google.GoogleDrive'
    'Google.Chrome'
    'alexx2000.DoubleCommander'
    '7zip.7zip'
    'Microsoft.PowerToys'
    'Devolutions.UniGetUI'                 # one window to update winget + scoop apps
    'HP.ImageAssistant'                    # HP drivers/BIOS/firmware -> C:\SWSetup\HPImageAssistant

    # --- Home ---
    'Bitwarden.Bitwarden'                  # desktop app - point it at Vaultwarden
    'Bitwarden.CLI'                        # bw, for Vaultwarden secrets
    'Tailscale.Tailscale'                  # NAS access
    'Bambulab.Bambustudio'                 # A1 mini slicer
    'OpenSCAD.OpenSCAD'                    # parametric 3D models
    'Loxone.LoxoneConfig'                  # Miniserver config
    'Valve.Steam'
)

# Extra winget arguments per package
$extraArgs = @{
    # MSI into Program Files\PowerShell\7 - winget now picks the MSIX build by default
    'Microsoft.PowerShell' = '--installer-type', 'wix'
}

# On a fresh install winget only appears once the Store has registered App Installer
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget not found - update "App Installer" in Microsoft Store, then run again.'
}

foreach ($id in $apps) {
    Write-Host "`n== $id ==" -ForegroundColor Cyan
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements $extraArgs[$id]
    # 0 = installed, -1978335189 = no newer version, -1978335135 = already installed
    if ($LASTEXITCODE -notin 0, -1978335189, -1978335135) { $failed += $id }
}

# Pick up PATH changes from the installers above (git for Scoop buckets, etc.)
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

# --- Scoop: standalone CLI tools ---
$scoopApps = @(
    'starship', 'zoxide', 'bat', 'ripgrep', 'fd', 'fzf', 'less', 'delta',
    'jq', 'just', 'duckdb'
    'ghostscript', 'poppler', 'qpdf'       # PDF tools (used by Claude document skills)
)

Write-Host "`n== Scoop ==" -ForegroundColor Cyan
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    try { Invoke-RestMethod https://get.scoop.sh | Invoke-Expression }
    catch { $failed += "Scoop ($_)" }
}
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$env:USERPROFILE\scoop" }
    foreach ($a in $scoopApps) {
        if (Test-Path "$scoopRoot\apps\$a") { Write-Host "  $a already installed"; continue }
        scoop install $a
        if ($LASTEXITCODE -ne 0) { $failed += "scoop $a" }
    }
}

# --- PowerShell modules (installed for pwsh 7, not Windows PowerShell) ---
$modules = @('Terminal-Icons')
$pwsh = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'
Write-Host "`n== PowerShell modules ==" -ForegroundColor Cyan
if (Test-Path $pwsh) {
    foreach ($m in $modules) {
        & $pwsh -NoProfile -Command "if (-not (Get-Module -ListAvailable $m)) { Install-PSResource $m -Scope CurrentUser -TrustRepository }"
        if ($LASTEXITCODE -ne 0) { $failed += "module $m" }
    }
} else { $failed += 'PowerShell modules (pwsh 7 not found)' }

# --- Git: use Windows OpenSSH so keys in ssh-agent work ---
$git = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
if (Test-Path $git) { & $git config --global core.sshCommand 'C:/Windows/System32/OpenSSH/ssh.exe' }

# --- Windows features (not winget apps; need a restart) ---
$features = @(
    'Microsoft-Hyper-V-All'                # Hyper-V
)
foreach ($f in $features) {
    Write-Host "`n== $f ==" -ForegroundColor Cyan
    $state = (Get-CimInstance Win32_OptionalFeature -Filter "Name='$f'").InstallState
    if ($state -eq 1) { Write-Host "Already enabled."; continue }
    $p = Start-Process dism.exe -Verb RunAs -Wait -PassThru `
        -ArgumentList "/Online /Enable-Feature /FeatureName:$f /All /NoRestart"
    # 3010 = enabled, restart required
    if ($p.ExitCode -in 0, 3010) { Write-Host "Enabled - restart to finish." -ForegroundColor Yellow }
    else { $failed += "$f (dism exit $($p.ExitCode))" }
}

Write-Host ""
if ($failed) {
    Write-Host "Failed (try manually with 'winget search' / 'scoop search'):" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "All apps installed." -ForegroundColor Green
}
