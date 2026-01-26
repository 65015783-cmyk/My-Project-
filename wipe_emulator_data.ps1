# Script to wipe emulator data via ADB
Write-Host "=== Wiping Emulator Data ===" -ForegroundColor Cyan
Write-Host "WARNING: This will delete ALL data on the emulator!" -ForegroundColor Red
Write-Host ""

# Find ADB path
$adbPaths = @(
    "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe",
    "$env:ANDROID_HOME\platform-tools\adb.exe",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\platform-tools\adb.exe",
    "C:\Users\$env:USERNAME\AppData\Local\Android\Sdk\platform-tools\adb.exe"
)

$adb = $null
foreach ($path in $adbPaths) {
    if (Test-Path $path) {
        $adb = $path
        Write-Host "Found ADB at: $adb" -ForegroundColor Green
        break
    }
}

if (-not $adb) {
    Write-Host "ERROR: ADB not found." -ForegroundColor Red
    exit 1
}

# Check devices
Write-Host "`nChecking connected devices..." -ForegroundColor Yellow
$devices = & $adb devices
Write-Host $devices

$deviceCount = ($devices | Select-String "device$" | Measure-Object).Count
if ($deviceCount -eq 0) {
    Write-Host "`nERROR: No device connected!" -ForegroundColor Red
    exit 1
}

# Check if it's an emulator
$isEmulator = ($devices | Select-String "emulator").Count -gt 0
if (-not $isEmulator) {
    Write-Host "`nWARNING: This script is designed for emulators only!" -ForegroundColor Yellow
    Write-Host "Detected device may be a physical device. Aborting for safety." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== IMPORTANT: Manual Steps Required ===" -ForegroundColor Yellow
Write-Host "ADB cannot directly wipe emulator data safely." -ForegroundColor White
Write-Host "Please follow these steps:" -ForegroundColor White
Write-Host ""
Write-Host "Method 1: Wipe from Android Studio (Recommended)" -ForegroundColor Cyan
Write-Host "  1. Open Android Studio" -ForegroundColor White
Write-Host "  2. Go to Tools > Device Manager (or View > Tool Windows > Device Manager)" -ForegroundColor White
Write-Host "  3. Find your emulator (sdk gphone64 x86 64)" -ForegroundColor White
Write-Host "  4. Click the dropdown menu (three dots) next to the emulator" -ForegroundColor White
Write-Host "  5. Select 'Wipe Data'" -ForegroundColor White
Write-Host "  6. Confirm the action" -ForegroundColor White
Write-Host "  7. Wait for emulator to restart" -ForegroundColor White
Write-Host "  8. Then run: flutter run" -ForegroundColor White
Write-Host ""
Write-Host "Method 2: Cold Boot from Android Studio" -ForegroundColor Cyan
Write-Host "  1. Close the emulator completely" -ForegroundColor White
Write-Host "  2. In Device Manager, click the dropdown menu" -ForegroundColor White
Write-Host "  3. Select 'Cold Boot Now'" -ForegroundColor White
Write-Host "  4. This will start fresh without user data" -ForegroundColor White
Write-Host ""
Write-Host "Method 3: Delete and Recreate Emulator" -ForegroundColor Cyan
Write-Host "  1. In Device Manager, click the dropdown menu" -ForegroundColor White
Write-Host "  2. Select 'Delete'" -ForegroundColor White
Write-Host "  3. Create a new emulator with 8GB+ storage" -ForegroundColor White
Write-Host "  4. Use Pixel 6 or similar device with more storage" -ForegroundColor White
Write-Host ""

# Try to free up more space by clearing caches
Write-Host "Attempting to free up space by clearing caches..." -ForegroundColor Yellow
& $adb shell "pm trim-caches 1G" 2>$null | Out-Null
& $adb shell "rm -rf /data/dalvik-cache/*" 2>$null | Out-Null
& $adb shell "rm -rf /cache/*" 2>$null | Out-Null

Write-Host "`nChecking storage after cleanup..." -ForegroundColor Yellow
$storage = & $adb shell df -h /data 2>$null
Write-Host $storage

Write-Host "`n=== Next Steps ===" -ForegroundColor Green
Write-Host "If you still get INSTALL_FAILED_INSUFFICIENT_STORAGE:" -ForegroundColor Yellow
Write-Host "  → Use Method 1 (Wipe Data) from Android Studio" -ForegroundColor White
Write-Host "  → Or create a new emulator with more storage (8GB+)" -ForegroundColor White
