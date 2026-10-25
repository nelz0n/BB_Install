<#
  BB_Toolkit - apps.ps1
  Installs everyday apps with winget. Edit the list, run again any time -
  apps that are already installed are skipped.

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
    'DaxStudio.DaxStudio'
    'TabularEditor.TabularEditor'

    # --- AI ---
    'Anthropic.Claude'

    # --- Work / everyday ---
    'Microsoft.Teams'
    'Dropbox.Dropbox'
    'Google.Chrome'
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

Write-Host ""
if ($failed) {
    Write-Host "Failed (try manually with 'winget search'):" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "All apps installed." -ForegroundColor Green
}
