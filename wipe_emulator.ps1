# Script to wipe emulator data
$adb = "C:\Users\LENOVO\AppData\Local\Android\Sdk\platform-tools\adb.exe"

Write-Host "=== Wiping Emulator Data ===" -ForegroundColor Cyan
Write-Host "This will delete all data on the emulator!" -ForegroundColor Yellow
Write-Host ""

# List devices
Write-Host "Connected devices:" -ForegroundColor Yellow
& $adb devices

Write-Host "`nTo wipe emulator data:" -ForegroundColor Green
Write-Host "1. Open Android Studio" -ForegroundColor White
Write-Host "2. Go to Device Manager (Tools > Device Manager)" -ForegroundColor White
Write-Host "3. Find your emulator (Pixel_3_API_35)" -ForegroundColor White
Write-Host "4. Click the dropdown menu (three dots) next to the emulator" -ForegroundColor White
Write-Host "5. Select 'Wipe Data'" -ForegroundColor White
Write-Host "6. Confirm the action" -ForegroundColor White
Write-Host "7. Wait for emulator to restart" -ForegroundColor White
Write-Host "8. Then run: flutter run" -ForegroundColor White

Write-Host "`nAlternatively, you can use ADB command:" -ForegroundColor Green
Write-Host "  adb -e emu kill" -ForegroundColor Cyan
Write-Host "  Then restart emulator from Android Studio with 'Cold Boot Now'" -ForegroundColor White

