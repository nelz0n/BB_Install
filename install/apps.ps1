<#
  BB_Toolkit - apps.ps1
  Installs everyday apps with winget, Scoop, and enables Hyper-V. Edit the
  lists, run again any time - anything already installed is skipped.

  Usage (normal PowerShell; winget asks for elevation where needed):
    powershell -ExecutionPolicy Bypass -File .\install\apps.ps1

  Find a package id:  winget search <name>
#>

$apps = @(
    # --- Dev ---
    'Microsoft.PowerShell'
    'Microsoft.VisualStudioCode'
    'Git.Git'
    'GitHub.cli'
    'astral-sh.uv'                         # Python via uv (uv python install)
    'Schniz.fnm'                           # Node versions via fnm
    'Oven-sh.Bun'
    'Ollama.Ollama'

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

    # --- Home ---
    'Bitwarden.Bitwarden'                  # desktop app - point it at Vaultwarden
    'Bitwarden.CLI'                        # bw, for Vaultwarden secrets
    'Tailscale.Tailscale'                  # NAS access
    'Bambulab.Bambustudio'                 # A1 mini slicer
)

$failed = @()
foreach ($id in $apps) {
    Write-Host "`n== $id ==" -ForegroundColor Cyan
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    # 0 = installed, -1978335189 = no newer version, -1978335135 = already installed
    if ($LASTEXITCODE -notin 0, -1978335189, -1978335135) { $failed += $id }
}

# --- Scoop (must run as normal user, not admin) ---
Write-Host "`n== Scoop ==" -ForegroundColor Cyan
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "Already installed."
} else {
    try { Invoke-RestMethod https://get.scoop.sh | Invoke-Expression }
    catch { $failed += "Scoop ($_)" }
}

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
    Write-Host "Failed (try manually with 'winget search'):" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "All apps installed." -ForegroundColor Green
}
