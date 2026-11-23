@echo off
rem Startet den ACC-Server direkt (ohne accweb).
tasklist /fi "imagename eq accServer.exe" 2>nul | find /i "accServer.exe" >nul
if not errorlevel 1 (
    echo Es laeuft bereits ein ACC-Server ^(accServer.exe^), z. B. ueber accweb.
    echo Erst diesen beenden, sonst wollen zwei Server dieselben Ports.
    pause
    exit /b 1
)
tasklist /fi "imagename eq accweb.exe" 2>nul | find /i "accweb.exe" >nul
if not errorlevel 1 (
    echo accweb laeuft noch. Entweder accweb oder start.bat verwenden, nicht beides.
    pause
    exit /b 1
)
cd /d "%~dp0server"
accServer.exe
pause
