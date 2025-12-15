@echo off
echo ============================================
echo   Reset MySQL Root Password
echo ============================================
echo.
echo กรุณารันไฟล์นี้แบบ "Run as Administrator"
echo.
pause

echo [1/5] หยุด MySQL Service...
net stop MySQL80
if %errorlevel% neq 0 (
    echo ERROR: ไม่สามารถหยุด MySQL Service ได้
    echo กรุณาตรวจสอบว่ารันแบบ Administrator หรือไม่
    pause
    exit /b 1
)
echo ✓ หยุด MySQL เรียบร้อย
echo.

echo [2/5] สร้างไฟล์ reset password...
echo FLUSH PRIVILEGES; > C:\mysql-init.txt
echo ALTER USER 'root'@'localhost' IDENTIFIED BY '12345678'; >> C:\mysql-init.txt
echo CREATE DATABASE IF NOT EXISTS humans; >> C:\mysql-init.txt
echo CREATE USER IF NOT EXISTS 'humans_app'@'localhost' IDENTIFIED BY '12345678'; >> C:\mysql-init.txt
echo GRANT ALL PRIVILEGES ON humans.* TO 'humans_app'@'localhost'; >> C:\mysql-init.txt
echo FLUSH PRIVILEGES; >> C:\mysql-init.txt
echo ✓ สร้างไฟล์ reset เรียบร้อย
echo.

echo [3/5] รีเซ็ตรหัสผ่าน MySQL...
echo (กรุณารอสักครู่...)
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysqld.exe" --init-file=C:\mysql-init.txt --console
if %errorlevel% neq 0 (
    echo WARNING: อาจมีปัญหา แต่ลองทำขั้นตอนถัดไป
)
echo.

echo [4/5] เริ่ม MySQL Service ใหม่...
net start MySQL80
if %errorlevel% neq 0 (
    echo ERROR: ไม่สามารถเริ่ม MySQL Service ได้
    pause
    exit /b 1
)
echo ✓ เริ่ม MySQL เรียบร้อย
echo.

echo [5/5] ลบไฟล์ชั่วคราว...
del C:\mysql-init.txt
echo ✓ ลบไฟล์เรียบร้อย
echo.

echo ============================================
echo   เสร็จสิ้น!
echo ============================================
echo.
echo ตอนนี้คุณสามารถเข้า MySQL Workbench ได้แล้ว:
echo   User: root (หรือ humans_app)
echo   Password: 12345678
echo.
echo จากนั้น Restart Backend:
echo   cd backend
echo   npm start
echo.
pause




