param(
    [string]$BusId
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Command '$Name' not found. Install it first."
    }
}

Require-Command -Name "usbipd"

$usbipdList = usbipd list
$deviceLines = $usbipdList | Where-Object {
    $_ -match "COM\d" -or
    $_ -match "CP210" -or
    $_ -match "CH340" -or
    $_ -match "FTDI" -or
    $_ -match "Silicon Labs" -or
    $_ -match "UART" -or
    $_ -match "Espressif" -or
    $_ -match "USB Serial"
}

if (-not $BusId) {
    if ($deviceLines.Count -eq 1) {
        $BusId = ($deviceLines[0] -split "\s+")[0]
    } else {
        Write-Host ""
        Write-Host "Detected USB serial-like devices:"
        $deviceLines | ForEach-Object { Write-Host "  $_" }
        Write-Host ""
        throw "Pass the bus ID explicitly: .\\tools\\attach-esp32.ps1 -BusId <BUSID>"
    }
}

Write-Host "Binding USB device $BusId to WSL..."
usbipd bind --busid $BusId

Write-Host "Attaching USB device $BusId to WSL..."
usbipd attach --wsl --busid $BusId

Write-Host ""
Write-Host "Done. If the dev container was already running, rebuild or reopen it."
