# BB PowerShell 7 profile - copy to $PROFILE
#   Copy-Item .\config\powershell\Microsoft.PowerShell_profile.ps1 $PROFILE -Force
# Every tool is optional: if it is not installed yet, that line is skipped.

function Test-Cmd([string]$Name) { [bool](Get-Command $Name -ErrorAction SilentlyContinue) }

# Starship prompt + zoxide (z <folder>)
if (Test-Cmd starship) { Invoke-Expression (&starship init powershell) }
if (Test-Cmd zoxide)   { Invoke-Expression (& { (zoxide init powershell | Out-String) }) }

# fnm - Node version manager (must be early in profile)
if (Test-Cmd fnm) { fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression }

# uv - tab completion
if (Test-Cmd uv) { (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression }

# Terminal Icons
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# gsudo (Scoop puts the module on PSModulePath, winget installs it under Program Files)
$gsudoWinget = "$env:ProgramFiles\gsudo\Current\gsudoModule.psd1"
if (Get-Module -ListAvailable gsudoModule) { Import-Module gsudoModule }
elseif (Test-Path $gsudoWinget)            { Import-Module $gsudoWinget }

# uv tools / Claude Code on PATH (once - nested shells inherit it)
$localBin = "$env:USERPROFILE\.local\bin"
if ($env:PATH -notlike "*$localBin*") { $env:PATH = "$localBin;$env:PATH" }

# PSReadLine - better history and completion (interactive console only;
# prediction errors out when output is redirected, e.g. scripts calling pwsh)
if (-not [Console]::IsOutputRedirected) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
}

# Aliases
if (Test-Cmd bat)   { Set-Alias cat bat }
if (Test-Cmd rg)    { Set-Alias grep rg }
if (Test-Cmd gsudo) { Set-Alias sudo gsudo }

# Functions
function which($cmd) { (Get-Command $cmd).Source }
function touch($f) {
    # update the timestamp if the file exists, create it otherwise (never truncate)
    if (Test-Path $f) { (Get-Item $f).LastWriteTime = Get-Date }
    else { New-Item -ItemType File $f | Out-Null }
}
function New-PyProject {
    param([string]$Name)
    uv init $Name --package                # also runs git init
    Set-Location $Name
    uv python pin 3.13
    uv add polars pyarrow duckdb httpx python-dotenv
    uv add --dev ruff pytest
    git add -A
    git commit -m "chore: scaffold uv project"
}
function Update-Pwsh {
    # Runs outside pwsh; the installer asks to close open pwsh windows (incl. Claude Code)
    Start-Process powershell.exe -ArgumentList '-NoProfile', '-Command',
        'winget upgrade --id Microsoft.PowerShell --exact; pause'
}
