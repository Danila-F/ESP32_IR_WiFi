param(
    [Parameter(Mandatory = $true)]
    [string]$BusId
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command usbipd -ErrorAction SilentlyContinue)) {
    throw "Command 'usbipd' not found. Install usbipd-win first."
}

Write-Host "Detaching USB device $BusId from WSL..."
usbipd detach --busid $BusId

Write-Host "Done."
