@echo off
rem Gecici baslatici: AltDetectorX.ps1'i profil yuklemeden ve ExecutionPolicy engeline takilmadan calistirir.
rem Ek parametreler aynen aktarilir, ornek: AltDetectorX.bat -Mode Quick
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0AltDetectorX.ps1" %*
if errorlevel 1 pause
