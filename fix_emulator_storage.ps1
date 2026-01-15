# Script to fix insufficient storage on Android Emulator
Write-Host "=== Fixing Emulator Storage Issue ===" -ForegroundColor Cyan

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
        Write-Host "Found ADB at: $adb" -ForegroundColor Green
        break
    }
}

if (-not $adb) {
    Write-Host "ERROR: ADB not found. Please check your Android SDK installation." -ForegroundColor Red
    exit 1
}

# Check if device is connected
Write-Host "`nChecking connected devices..." -ForegroundColor Yellow
& $adb devices

# Uninstall the app
Write-Host "`nUninstalling com.example.hummans..." -ForegroundColor Yellow
& $adb uninstall com.example.hummans
if ($LASTEXITCODE -eq 0) {
    Write-Host "App uninstalled successfully!" -ForegroundColor Green
} else {
    Write-Host "App may not be installed, or uninstall failed (this is OK if app doesn't exist)" -ForegroundColor Yellow
}

# Clear app data (if app still exists)
Write-Host "`nClearing app data..." -ForegroundColor Yellow
& $adb shell pm clear com.example.hummans 2>$null

# Check storage
Write-Host "`nChecking storage space..." -ForegroundColor Yellow
& $adb shell df -h /data

# Clean up temporary files
Write-Host "`nCleaning up temporary files..." -ForegroundColor Yellow
& $adb shell rm -rf /data/local/tmp/* 2>$null
& $adb shell rm -rf /sdcard/Download/*.apk 2>$null

Write-Host "`n=== Done! Try running 'flutter run' again ===" -ForegroundColor Green

