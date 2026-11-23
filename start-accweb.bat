@echo off
rem Startet die Weboberflaeche. Der ACC-Server laeuft dann unter accweb, nicht ueber start.bat.
rem accweb schreibt sehr viele Meldungen, deshalb landen sie in accweb\accweb.log statt im Fenster.
tasklist /fi "imagename eq accweb.exe" 2>nul | find /i "accweb.exe" >nul
if not errorlevel 1 (
    echo accweb laeuft bereits. Weboberflaeche im Browser oeffnen.
    pause
    exit /b 1
)
tasklist /fi "imagename eq accServer.exe" 2>nul | find /i "accServer.exe" >nul
if not errorlevel 1 (
    echo Es laeuft bereits ein ACC-Server ^(accServer.exe^), vermutlich ueber start.bat.
    echo Erst dieses Fenster schliessen, sonst startet der Server aus accweb nicht.
    pause
    exit /b 1
)
cd /d "%~dp0accweb"
if exist accweb.log move /y accweb.log accweb.old.log >nul
title accweb - ACC Race Control
echo accweb laeuft. Weboberflaeche im Browser oeffnen, z. B. http://localhost:8080
echo Meldungen stehen in %~dp0accweb\accweb.log
echo Zum Beenden dieses Fenster schliessen.
accweb.exe >> accweb.log 2>&1
echo.
echo accweb wurde beendet. Grund steht am Ende von accweb\accweb.log
pause
