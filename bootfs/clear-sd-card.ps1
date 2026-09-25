# ShowPlayPI: removes all partitions of this SD card and creates one empty partition - the card is like new.
# Started by Clear-SD-Card.cmd on the boot partition. Works only on the ShowPlayPI card it was started from:
# the checks run first, administrator rights are only requested for the change itself.

param(
    [Parameter(Mandatory = $true)][string]$Drive,
    [int]$ConfirmedDisk = -1
)

$ErrorActionPreference = 'Stop'
$MaxSize = 256GB
$Label = 'SDCARD'

function Stop-WithMessage([string]$Message) {
    Write-Host ''
    Write-Host $Message -ForegroundColor Red
    Read-Host 'Press Enter to close' | Out-Null
    exit 1
}

# The card this script was started from - with all safety checks
function Get-ShowPlayPICard([string]$Letter) {
    try {
        $partition = Get-Partition -DriveLetter $Letter
    } catch {
        Stop-WithMessage "Drive $($Letter): was not found - nothing was changed."
    }
    $disk = Get-Disk -Number $partition.DiskNumber
    $partitions = @(Get-Partition -DiskNumber $disk.Number)

    if ($disk.IsBoot -or $disk.IsSystem) {
        Stop-WithMessage 'This is a system disk of this computer - nothing was changed.'
    }
    if ($disk.BusType -notin 'USB', 'SD', 'MMC') {
        Stop-WithMessage "This is not a memory card (bus type $($disk.BusType)) - nothing was changed."
    }
    if ($disk.Size -gt $MaxSize) {
        Stop-WithMessage 'The disk is larger than 256 GB and is therefore not treated as a ShowPlayPI card - nothing was changed.'
    }
    if ((Get-Volume -DriveLetter $Letter).FileSystemLabel -ne 'bootfs' -or -not ($partitions | Where-Object MbrType -eq 131)) {
        Stop-WithMessage 'This card does not contain a ShowPlayPI system - nothing was changed.'
    }
    return $disk
}

$letter = $Drive.TrimEnd(':', '\')
$disk = Get-ShowPlayPICard $letter
$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($ConfirmedDisk -lt 0) {
    Write-Host 'ShowPlayPI - clear SD card' -ForegroundColor Yellow
    Write-Host ''
    Write-Host ('Card: {0}, {1:N1} GB' -f $disk.FriendlyName, ($disk.Size / 1GB))
    foreach ($partition in Get-Partition -DiskNumber $disk.Number) {
        $name = (Get-Volume -Partition $partition -ErrorAction SilentlyContinue).FileSystemLabel
        if (-not $name -and $partition.MbrType -eq 131) { $name = 'Linux system' }
        Write-Host ('  Partition {0}: {1,6:N1} GB  {2}' -f $partition.PartitionNumber, ($partition.Size / 1GB), $name)
    }
    Write-Host ''
    Write-Host 'All partitions of this card are removed. Afterwards the card is empty,' -ForegroundColor Yellow
    Write-Host "with one partition '$Label', and can be used or flashed again." -ForegroundColor Yellow
    Write-Host ''
    if ((Read-Host 'Type DELETE to continue') -ne 'DELETE') {
        Stop-WithMessage 'Cancelled - nothing was changed.'
    }

    if (-not $isAdmin) {
        # The change needs administrator rights; the elevated copy checks the card again
        Start-Process powershell -Verb RunAs -ArgumentList @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"",
            '-Drive', $letter, '-ConfirmedDisk', $disk.Number)
        exit 0
    }
} elseif ($ConfirmedDisk -ne $disk.Number) {
    Stop-WithMessage 'The card has changed in the meantime - nothing was changed.'
}

# SD standard: FAT32 up to 32 GB, exFAT above
$fileSystem = if ($disk.Size -le 32GB) { 'fat32' } else { 'exfat' }
$commands = Join-Path $env:TEMP 'showplaypi-clear-sd-card.txt'
@(
    "select disk $($disk.Number)"
    'clean'
    'create partition primary'
    "format fs=$fileSystem quick label=$Label"
    'assign'
) | Set-Content -Path $commands -Encoding Ascii

Write-Host ''
Write-Host 'Removing the partitions ...'
diskpart /s $commands | Out-Null
$exitCode = $LASTEXITCODE
Remove-Item $commands -ErrorAction SilentlyContinue

if ($exitCode -ne 0) {
    Stop-WithMessage "diskpart reported an error (exit code $exitCode). Remove and insert the card, then try again."
}

Write-Host ''
Write-Host "Done: the card is empty (one $($fileSystem.ToUpper()) partition '$Label')." -ForegroundColor Green
Read-Host 'Press Enter to close' | Out-Null
