# ACCDCServer

Fertiges Setup für einen **Assetto Corsa Competizione (ACC) Dedicated Server unter Windows**: Installation per Skript, Firewall-Regeln, Start-Datei und Beispielkonfiguration. Aufgebaut wie [AssettoCorsaDCServer](https://github.com/Monaco85/AssettoCorsaDCServer), nur für ACC.

> Hinweis: Das Setup ist noch nicht auf einem echten Windows-PC getestet. Die Skriptlogik (Server finden, Konfiguration prüfen und umwandeln) wurde unter PowerShell 7 durchgespielt, SteamCMD und die Firewall-Befehle nicht.

## Inhalt

| Datei | Zweck |
|---|---|
| `install.ps1` | Holt den Server aus deiner ACC-Installation oder per SteamCMD (Steam-Tool 1430110) und spielt `cfg\` ein |
| `start.bat` | Startet `server\accServer.exe` |
| `firewall.ps1` | Öffnet die Ports in der Windows-Firewall (als Administrator) |
| `cfg\configuration.json` | Ports, Verbindungen, Lobby und LAN |
| `cfg\settings.json` | Servername, Passwörter, Fahrzeugklasse, Slots |
| `cfg\event.json` | Strecke, Wetter, Sessions |
| `cfg\eventRules.json` | Boxenstopp-Regeln |
| `cfg\assistRules.json` | Erlaubte Fahrhilfen |
| `cfg\entrylist.json` | Feste Einträge, z. B. du als Admin (anfangs leer) |

## Was anders ist als beim Assetto-Corsa-Server

- **Kein anonymer Download.** Den ACC-Server gibt es nur für Besitzer von ACC. Entweder liegt er schon in deiner Spielinstallation (`...\steamapps\common\Assetto Corsa Competizione\server`) oder du lädst ihn mit deinem Steam-Konto per SteamCMD.
- **JSON statt INI.** Der Server liest die Dateien nur in der Kodierung UTF-16 LE. Im Repo liegen sie als normales UTF-8, `install.ps1` wandelt sie beim Kopieren um. Bearbeite deshalb immer `cfg\` und führe danach `install.ps1` aus.
- **Andere Ports:** UDP 9231 und TCP 9232. Der Server läuft damit auch parallel zu deinem AC-Server (9600/8081).
- **Keine Inhalte kopieren.** Alle Strecken und Autos bringt das Spiel mit, der Server braucht keinen `content`-Ordner.
- **Kein Verbinden per IP im Spielmenü.** Spieler finden den Server in der Serverliste (Internet) oder in der LAN-Liste.
- **Rennen laufen nach Zeit**, nicht nach Runden.
- Keine eingebaute Weboberfläche (siehe "Optional: accweb").

## Voraussetzungen

- Windows 10/11 oder Windows Server, PowerShell 5.1 oder neuer
- Ein Steam-Konto, das ACC besitzt
- Spieler brauchen ACC. Für Strecken aus DLCs braucht jeder Spieler das passende DLC

## Installation

1. Repo klonen oder als ZIP herunterladen und entpacken, z. B. nach `C:\ACCDCServer`.
2. **Konfiguration anpassen** (vor der Installation, sonst danach `install.ps1` erneut ausführen):
   - `cfg\settings.json`: `serverName`, `password` (leer = öffentlich), `adminPassword`
   - `cfg\event.json`: `track` und `sessions`
   - `cfg\configuration.json`: nur wenn du andere Ports oder mehr Verbindungen willst
3. PowerShell im Ordner öffnen und ausführen.

   **Variante A**, ACC ist auf diesem PC installiert:
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\install.ps1
   ```
   Das Skript sucht ACC in allen Steam-Bibliotheken und kopiert den Ordner `server` nach `server\`.

   **Variante B**, PC ohne ACC (z. B. ein eigener Server-PC):
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\install.ps1 -SteamUser deinSteamName
   ```
   Das legt `steamcmd\` und `steamapp\` an. SteamCMD fragt im Fenster nach Passwort und Steam-Guard-Code. Danach kopiert das Skript den Server nach `server\`.

   In beiden Fällen prüft das Skript zuerst alle Dateien in `cfg\` auf Syntaxfehler und schreibt sie dann als UTF-16 LE nach `server\cfg\`. Außerdem legt es `server\results\` für die Ergebnisse an.
4. Firewall-Ports öffnen (PowerShell **als Administrator**):
   ```powershell
   PowerShell -ExecutionPolicy Bypass -File .\firewall.ps1
   ```
   Die Ports liest das Skript aus `cfg\configuration.json`. Zusätzlich gibt es `server\accServer.exe` frei, damit auch die LAN-Suche durchkommt.

## Starten

Doppelklick auf `start.bat`. Im Fenster erscheint das Serverlog, eine Kopie liegt in `server\log\`. Zum Beenden das Fenster schließen oder `Strg+C`.

Wenn der Server sofort stoppt, steht der Grund im Log. Meist ist es ein falscher Streckenname oder ein unpassender Wert. Bei einem falschen Streckennamen listet das Log alle gültigen Namen auf.

## Nutzen

### Verbinden
- **Im selben Netzwerk:** In ACC unter *Multiplayer* in der LAN-Liste. Dafür muss `lanDiscovery` auf `1` stehen.
- **Über das Internet:** Im Router **UDP 9231** und **TCP 9232** auf den Server-PC weiterleiten. Mit `registerToLobby` auf `1` erscheint der Server in der Serverliste im Spiel. Ist ein `password` gesetzt, gilt er als privater Server und fragt beim Beitreten nach dem Passwort.
- Siehst du deinen Server in der Liste ohne Ping-Wert, ist der UDP-Port nicht erreichbar.
- `registerToLobby` auf `0` macht den Server zum reinen LAN-Server.

Kunos rät davon ab, einen öffentlichen Server auf dem eigenen PC zu betreiben: offene Ports und ein schwacher Upload deines Anschlusses gehen auf Kosten aller Spieler. Für Runden mit Freunden ist ein Passwort deshalb sinnvoll.

### Admin im Spiel
Im Chat `/admin <adminPassword>`, danach z. B.:
- `/next`: nächste Session
- `/restart`: Session neu starten (nicht in der Vorbereitungsphase)
- `/kick <Startnummer>` oder `/ban <Startnummer>`: anders als bei AC mit der **Startnummer**, nicht dem Namen
- `/dq <Startnummer>`: sofort disqualifizieren
- `/tp5`, `/tp15` `<Startnummer>`: 5 oder 15 Sekunden Zeitstrafe
- `/dt <Startnummer>`: Durchfahrtsstrafe, `/clear <Startnummer>` hebt offene Strafen auf
- `/manual entrylist`: schreibt eine Entry-Liste mit allen gerade verbundenen Fahrern

### Dich dauerhaft als Admin eintragen
In `cfg\entrylist.json` einen Eintrag mit deiner Steam64-ID (17 Ziffern, mit `S` davor) anlegen:
```json
{
    "entries": [
        {
            "drivers": [ { "playerID": "S76561198000000000" } ],
            "raceNumber": -1,
            "forcedCarModel": -1,
            "overrideDriverInfo": 0,
            "isServerAdmin": 1
        }
    ],
    "forceEntryList": 0,
    "configVersion": 1
}
```
Einträge aus der Entry-Liste kommen auch auf einen vollen Server und umgehen die Rating-Anforderungen. Mit `forceEntryList` auf `1` dürfen nur noch eingetragene Fahrer beitreten (nur auf privaten Servern).

### Strecke und Autos
- `track` in `cfg\event.json`. Gültige Namen: `barcelona`, `brands_hatch`, `cota`, `donington`, `hungaroring`, `imola`, `indianapolis`, `kyalami`, `laguna_seca`, `misano`, `monza`, `mount_panorama`, `nurburgring`, `nurburgring_24h`, `oulton_park`, `paul_ricard`, `red_bull_ring`, `silverstone`, `snetterton`, `spa`, `suzuka`, `valencia`, `watkins_glen`, `zandvoort`, `zolder`.
- Sicher im Grundspiel enthalten sind `monza`, `zolder`, `brands_hatch`, `silverstone`, `paul_ricard`, `misano`, `spa`, `nurburgring`, `barcelona`, `hungaroring` und `zandvoort`. Für die anderen brauchen Spieler eventuell ein DLC.
- `carGroup` in `cfg\settings.json` legt die Fahrzeugklasse fest: `FreeForAll` (alles), `GT3`, `GT4`, `GT2`, `GTC` (Cup- und Supertrofeo-Autos) oder `TCX`.
- `maxCarSlots` begrenzt die Autos. Hat die Strecke weniger Boxen, gilt die Boxenzahl. `maxConnections` in `configuration.json` muss mindestens so groß sein, der Rest sind Plätze für Zuschauer.
- `spectatorPassword` erlaubt das Beitreten als Zuschauer. Es muss sich von `password` unterscheiden.

### Sessions und Wetter
In `cfg\event.json` steht unter `sessions` eine Liste. Jede Session hat:
- `sessionType`: `P` (Training), `Q` (Qualifying) oder `R` (Rennen). Mindestens eine Session darf kein Rennen sein
- `sessionDurationMinutes`: Dauer in Minuten
- `dayOfWeekend` (1 = Freitag, 2 = Samstag, 3 = Sonntag) und `hourOfDay` (0 bis 23): Wochentag und Uhrzeit, beeinflussen Grip und Wetter
- `timeMultiplier`: wie schnell die Uhrzeit im Spiel läuft (1 = Echtzeit)

Wetter: `ambientTemp` in °C, `cloudLevel` und `rain` von 0.0 bis 1.0, `weatherRandomness` 0 = festes Wetter, 1 bis 4 realistisch, 5 bis 7 wechselhaft.

`preRaceWaitingTimeSeconds` (mindestens 30) ist die Vorbereitungszeit vor dem Rennen. `sessionOverTimeSeconds` ist die Zeit nach Ablauf der Uhr, die Fahrer haben, um ihre Runde zu beenden. Für lange Strecken wie Spa oder Silverstone mehr als die voreingestellten 120 Sekunden nehmen.

### Boxenregeln und Fahrhilfen
- `cfg\eventRules.json`: Pflichtboxenstopps, Boxenfenster, Tanken, Reifensätze. Gilt nur auf privaten Servern, öffentliche Server ignorieren die Datei.
- `cfg\assistRules.json`: Fahrhilfen sperren, z. B. `disableIdealLine` auf `1` blendet die Ideallinie aus. `stabilityControlLevelMax` begrenzt die Stabilitätskontrolle (0 bis 100).

### Ergebnisse
Mit `dumpLeaderboards` auf `1` schreibt der Server nach jeder Session eine JSON-Datei nach `server\results\`, z. B. `251103_193009_R.json` mit Rundenzeiten und Strafen.

### Optional: accweb
Eine Weboberfläche zum Verwalten, Starten und Stoppen gibt es mit [accweb](https://github.com/assetto-corsa-web/accweb). Die ist hier nicht eingebaut. Wenn du sie nutzt, pflegt accweb die Konfiguration selbst, die Dateien aus `cfg\` brauchst du dann nicht.

## Updates
- **Variante A:** Steam aktualisiert ACC wie gewohnt. Danach `install.ps1` erneut ausführen.
- **Variante B:** `install.ps1 -SteamUser deinSteamName` erneut ausführen. SteamCMD aktualisiert den Server (`validate`).

Den Server vorher beenden, sonst lässt sich `accServer.exe` nicht überschreiben.
**Achtung:** Das Skript überschreibt die Dateien in `server\cfg\`. Pflege die Konfiguration deshalb in `cfg\`.

## Fehlersuche

| Problem | Ursache / Lösung |
|---|---|
| "Keine ACC-Installation mit accServer.exe gefunden" | ACC ist auf diesem PC nicht installiert. Über Steam installieren oder Variante B nutzen |
| SteamCMD lädt nichts, "No subscription" | Das Steam-Konto besitzt ACC nicht |
| "Syntaxfehler in cfg\\..." | Komma oder Anführungszeichen in der genannten Datei prüfen. Die Meldung nennt Zeile und Position |
| Server startet nicht, Fenster schließt sich | `start.bat` zeigt am Ende `pause`. Meldung lesen oder in `server\log\` nachsehen |
| Server nutzt andere Werte als in `cfg\` | Nach der Änderung `install.ps1` nicht erneut ausgeführt, oder eine Datei in `server\cfg\` wurde im Editor als UTF-8 gespeichert. Dann ignoriert der Server sie. `install.ps1` erneut ausführen |
| Nicht in der LAN-Liste | `lanDiscovery` auf `1`, `firewall.ps1` ausführen, Netzwerkprofil "Privat" verwenden |
| In der Serverliste ohne Ping | UDP-Port (9231) nicht erreichbar: Router-Weiterleitung und Firewall prüfen |
| Aus dem Internet nicht erreichbar | Portfreigabe im Router. Bei CGNAT oder DS-Lite ist keine direkte Erreichbarkeit möglich (VPN oder Tunnel nötig) |
| Skript meldet "Ausführung deaktiviert" | Mit `-ExecutionPolicy Bypass` starten wie oben gezeigt |
