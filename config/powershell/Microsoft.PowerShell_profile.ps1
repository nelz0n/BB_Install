# BB PowerShell 7 profile - copy to $PROFILE
#   Copy-Item .\config\powershell\Microsoft.PowerShell_profile.ps1 $PROFILE -Force

# Node versions (fnm): switch automatically on cd into a folder with .node-version / .nvmrc
if (Get-Command fnm -ErrorAction SilentlyContinue) {
    fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# uv: tab completion
if (Get-Command uv -ErrorAction SilentlyContinue) {
    (& uv generate-shell-completion powershell) | Out-String | Invoke-Expression
}
