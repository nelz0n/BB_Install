#Requires -RunAsAdministrator
<#
  BB_Toolkit - devdrive.ps1
  OPTIONAL. Creates a Dev Drive (ReFS, Defender performance mode) inside a
  growing VHDX file and mounts it at every boot. Put C:\Projects on it for
  faster git / node / builds.

  Usage (elevated PowerShell):
    powershell -ExecutionPolicy Bypass -File .\install\devdrive.ps1
    powershell -ExecutionPolicy Bypass -File .\install\devdrive.ps1 -SizeGB 200 -Letter P

  Afterwards move your projects to P:\ (or whatever letter you picked).
#>
param(
    [int]$SizeGB = 100,                        # max size; the file only grows as used
    [char]$Letter = 'P',
    [string]$Path = 'C:\DevDrive\DevDrive.vhdx'
)

$ErrorActionPreference = 'Stop'

if (Test-Path $Path) { throw "$Path already exists - nothing to do." }
if (Get-PSDrive -Name $Letter -ErrorAction SilentlyContinue) { throw "Drive ${Letter}: is already in use - pick another with -Letter." }

New-Item -ItemType Directory -Force (Split-Path $Path) | Out-Null

# Create + attach the VHDX (diskpart works without the Hyper-V module)
$dp = Join-Path $env:TEMP 'bb-devdrive.txt'
@"
create vdisk file="$Path" maximum=$($SizeGB * 1024) type=expandable
select vdisk file="$Path"
attach vdisk
"@ | Set-Content $dp -Encoding ASCII
diskpart /s $dp | Out-Null
Remove-Item $dp

$disk = Get-DiskImage -ImagePath $Path | Get-Disk
$disk | Initialize-Disk -PartitionStyle GPT
$disk | New-Partition -UseMaximumSize -DriveLetter $Letter |
    Format-Volume -DevDrive -FileSystem ReFS -NewFileSystemLabel 'DevDrive' -Confirm:$false | Out-Null

# Re-attach at every boot (VHDX files are not mounted automatically)
$action  = New-ScheduledTaskAction -Execute 'powershell.exe' `
    -Argument "-NoProfile -Command `"Mount-DiskImage -ImagePath '$Path'`""
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName 'BB Mount DevDrive' -Action $action -Trigger $trigger `
    -User 'SYSTEM' -RunLevel Highest -Force | Out-Null

Write-Host "Dev Drive ready at ${Letter}:\ (mounted at every boot)." -ForegroundColor Green
