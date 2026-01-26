# Script to start emulator with clean data
Write-Host "=== Starting Emulator with Clean Data ===" -ForegroundColor Cyan
Write-Host ""

$emulatorPath = "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe"

if (-not (Test-Path $emulatorPath)) {
    Write-Host "ERROR: Emulator not found at $emulatorPath" -ForegroundColor Red
    exit 1
}

# List available AVDs
Write-Host "Available AVDs:" -ForegroundColor Yellow
$avds = & $emulatorPath -list-avds
$avds | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }

Write-Host "`nStarting emulator with wipe-data..." -ForegroundColor Yellow
Write-Host "This will delete all data on the emulator!" -ForegroundColor Red
Write-Host ""

# Try to start the first AVD with wipe-data
if ($avds.Count -gt 0) {
    $firstAvd = $avds[0]
    Write-Host "Starting: $firstAvd" -ForegroundColor Green
    Write-Host "Please wait for emulator to boot (this may take 1-2 minutes)..." -ForegroundColor Yellow
    Write-Host ""
    
    # Start emulator in background
    Start-Process -FilePath $emulatorPath -ArgumentList "-avd", $firstAvd, "-wipe-data" -WindowStyle Normal
    
    Write-Host "Emulator is starting..." -ForegroundColor Green
    Write-Host "Wait until you see the Android home screen, then run: flutter run" -ForegroundColor Cyan
} else {
    Write-Host "ERROR: No AVDs found!" -ForegroundColor Red
}
