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
    'Python.Python.3.13'
    'OpenJS.NodeJS.LTS'
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
)

$failed = @()
foreach ($id in $apps) {
    Write-Host "`n== $id ==" -ForegroundColor Cyan
    winget install --id $id --exact --silent --accept-package-agreements --accept-source-agreements
    # 0 = installed, -1978335189 = already installed / no newer version
    if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne -1978335189) { $failed += $id }
}

Write-Host ""
if ($failed) {
    Write-Host "Failed (try manually with 'winget search'):" -ForegroundColor Yellow
    $failed | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "All apps installed." -ForegroundColor Green
}
