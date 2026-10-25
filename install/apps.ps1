<#
  BB_Toolkit - apps.ps1
  Installs everyday apps with winget and enables Hyper-V. Edit the list, run
  again any time - apps that are already installed are skipped.

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

    # --- Work / everyday ---
    'Microsoft.Teams'
    'Microsoft.WindowsApp'                 # Remote Desktop (Windows App)
    'Google.GoogleDrive'
    'Google.Chrome'
    'alexx2000.DoubleCommander'
    '7zip.7zip'

    # --- Home ---
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

# --- Hyper-V (Windows feature, not a winget app; needs a restart) ---
Write-Host "`n== Hyper-V ==" -ForegroundColor Cyan
$hv = (Get-CimInstance Win32_OptionalFeature -Filter "Name='Microsoft-Hyper-V'").InstallState
if ($hv -eq 1) {
    Write-Host "Already enabled."
} else {
    $p = Start-Process dism.exe -Verb RunAs -Wait -PassThru `
        -ArgumentList '/Online /Enable-Feature /FeatureName:Microsoft-Hyper-V-All /All /NoRestart'
    # 3010 = enabled, restart required
    if ($p.ExitCode -in 0, 3010) { Write-Host "Enabled - restart to finish." -ForegroundColor Yellow }
    else { $failed += "Hyper-V (dism exit $($p.ExitCode))" }
}

Write-Host ""
if ($failed) {
    Write-Host "Failed (try manually with 'winget search'):" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "All apps installed." -ForegroundColor Green
}
