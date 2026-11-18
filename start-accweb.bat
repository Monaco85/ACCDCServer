@echo off
rem Startet die Weboberflaeche. Der ACC-Server laeuft dann unter accweb, nicht ueber start.bat.
cd /d "%~dp0accweb"
accweb.exe
pause
