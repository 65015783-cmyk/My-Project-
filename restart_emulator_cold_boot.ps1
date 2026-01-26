# Script to restart emulator with cold boot
Write-Host "=== Restarting Emulator with Cold Boot ===" -ForegroundColor Cyan
Write-Host ""

# Find ADB path
$adbPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe"
)

$adb = $null
foreach ($path in $adbPaths) {
    if (Test-Path $path) {
        $adb = $path
        break
    }
}

if (-not $adb) {
    Write-Host "ERROR: ADB not found." -ForegroundColor Red
    exit 1
}

# Find emulator executable
$emulatorPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe",
    "$env:ANDROID_HOME\emulator\emulator.exe",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\emulator\emulator.exe"
)

$emulator = $null
foreach ($path in $emulatorPaths) {
    if (Test-Path $path) {
        $emulator = $path
        break
    }
}

if (-not $emulator) {
    Write-Host "ERROR: Emulator executable not found." -ForegroundColor Red
    Write-Host "Please restart emulator manually from Android Studio with 'Cold Boot Now'" -ForegroundColor Yellow
    exit 1
}

# List available AVDs
Write-Host "Available Android Virtual Devices:" -ForegroundColor Yellow
& $emulator -list-avds

Write-Host "`n=== Manual Steps Required ===" -ForegroundColor Yellow
Write-Host "To restart emulator with cold boot:" -ForegroundColor White
Write-Host ""
Write-Host "Option 1: From Android Studio" -ForegroundColor Cyan
Write-Host "  1. Open Android Studio" -ForegroundColor White
Write-Host "  2. Go to Tools > Device Manager" -ForegroundColor White
Write-Host "  3. Find your emulator (sdk gphone64 x86 64)" -ForegroundColor White
Write-Host "  4. Click the dropdown menu (three dots)" -ForegroundColor White
Write-Host "  5. Select 'Cold Boot Now'" -ForegroundColor White
Write-Host ""
Write-Host "Option 2: From Command Line" -ForegroundColor Cyan
Write-Host "  Run this command (replace AVD_NAME with your emulator name):" -ForegroundColor White
Write-Host "  emulator -avd AVD_NAME -wipe-data" -ForegroundColor Green
Write-Host ""
Write-Host "After emulator starts, run: flutter run" -ForegroundColor Green
