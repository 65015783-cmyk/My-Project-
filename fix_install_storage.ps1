# Script to fix INSTALL_FAILED_INSUFFICIENT_STORAGE error
Write-Host "=== Fixing INSTALL_FAILED_INSUFFICIENT_STORAGE ===" -ForegroundColor Cyan
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
    Write-Host "ERROR: ADB not found. Please check your Android SDK installation." -ForegroundColor Red
    Write-Host "Make sure Android SDK is installed and ADB is in your PATH." -ForegroundColor Yellow
    exit 1
}

# Check if device is connected
Write-Host "`nChecking connected devices..." -ForegroundColor Yellow
$devices = & $adb devices
Write-Host $devices

$deviceCount = ($devices | Select-String "device$" | Measure-Object).Count
if ($deviceCount -eq 0) {
    Write-Host "`nERROR: No device connected!" -ForegroundColor Red
    Write-Host "Please start your emulator first, then run this script again." -ForegroundColor Yellow
    exit 1
}

$packageName = "com.example.hummans"

# Step 1: Uninstall old app
Write-Host "`n[Step 1] Uninstalling old app ($packageName)..." -ForegroundColor Yellow
$uninstallResult = & $adb uninstall $packageName 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "App uninstalled successfully!" -ForegroundColor Green
} else {
    Write-Host "App may not be installed (this is OK)" -ForegroundColor Yellow
}

# Step 2: Clear app data (if app still exists)
Write-Host "`n[Step 2] Clearing app data..." -ForegroundColor Yellow
& $adb shell pm clear $packageName 2>$null | Out-Null

# Step 3: Clean up temporary files
Write-Host "`n[Step 3] Cleaning up temporary files..." -ForegroundColor Yellow
& $adb shell "rm -rf /data/local/tmp/*" 2>$null | Out-Null
& $adb shell "rm -rf /sdcard/Download/*.apk" 2>$null | Out-Null
& $adb shell "rm -rf /sdcard/Android/data/*/cache/*" 2>$null | Out-Null

# Step 4: Check storage space
Write-Host "`n[Step 4] Checking storage space..." -ForegroundColor Yellow
$storage = & $adb shell df -h /data 2>$null
Write-Host $storage

# Step 5: Clear system cache (requires root, but try anyway)
Write-Host "`n[Step 5] Attempting to clear system cache..." -ForegroundColor Yellow
& $adb shell "pm trim-caches 500M" 2>$null | Out-Null

# Step 6: Check available space again
Write-Host "`n[Step 6] Final storage check..." -ForegroundColor Yellow
$finalStorage = & $adb shell df -h /data 2>$null
Write-Host $finalStorage

Write-Host "`n=== Cleanup Complete! ===" -ForegroundColor Green
Write-Host "Now try running: flutter run" -ForegroundColor Cyan
Write-Host ""
Write-Host "If the error persists, you may need to:" -ForegroundColor Yellow
Write-Host "1. Wipe emulator data from Android Studio Device Manager" -ForegroundColor White
Write-Host "2. Create a new emulator with more storage (8GB+ recommended)" -ForegroundColor White
Write-Host "3. Restart the emulator with 'Cold Boot Now'" -ForegroundColor White
