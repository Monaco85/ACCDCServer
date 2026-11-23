Fertiges Setup für einen Assetto Corsa Competizione Dedicated Server unter Windows.

## Download und Installation
1. Unten unter **Assets** die Datei `ACCDCServer-….zip` herunterladen (nicht "Source code").
2. Entpacken, z. B. nach `C:\ACCDCServer`. `install.ps1` liegt direkt im Ordner.
3. Konfiguration in `cfg\` anpassen, dann in PowerShell im Ordner:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\install.ps1
   ```
   Auf einem PC ohne ACC: `.\install.ps1 -SteamUser deinSteamName`
4. `firewall.ps1` als Administrator ausführen, dann **`ACCDCServer.exe`** doppelklicken.

Optional Weboberfläche mit Race-Control-Design, Restart und "Save & restart":
```powershell
PowerShell -ExecutionPolicy Bypass -File .\install-accweb.ps1 -AdminPassword deinPasswort
```
Danach `firewall.ps1` erneut als Administrator. `ACCDCServer.exe` startet dann accweb samt Server und öffnet den Browser.

**ACCDCServer.exe** startet alles mit einem Doppelklick und beendet alles, wenn du das Fenster schließt. Beim ersten Start warnt Windows eventuell ("Der Computer wurde durch Windows geschützt"), weil das Programm nicht signiert ist: "Weitere Informationen" → "Trotzdem ausführen".

Alle Details stehen in der `README.md` im ZIP.

## Inhalt
- Installation aus der eigenen ACC-Installation oder per SteamCMD
- Beispielkonfiguration (Monza, Training, Qualifying, Rennen), wird automatisch nach UTF-16 LE umgewandelt
- Firewall-Skript für die ACC-Ports (UDP 9231, TCP 9232) und die Weboberfläche
- Weboberfläche accweb 1.27.0 mit eigenem Design

Hinweis: Noch nicht auf einem echten Windows-PC vollständig getestet.
