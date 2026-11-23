# Installiert den Assetto Corsa Competizione Dedicated Server und spielt die Konfiguration aus cfg\ ein.
#
# Variante A, ACC ist auf diesem PC installiert:
#   PowerShell -ExecutionPolicy Bypass -File .\install.ps1
#   Kopiert den Server aus der ACC-Installation (Ordner "server" im Spielverzeichnis).
#
# Variante B, PC ohne ACC:
#   PowerShell -ExecutionPolicy Bypass -File .\install.ps1 -SteamUser deinSteamName
#   Laedt das Steam-Tool 1430110 per SteamCMD. Anonym geht das nicht, das Konto muss ACC besitzen.
#   SteamCMD fragt Passwort und Steam-Guard-Code im Fenster ab.
param([string]$SteamUser)

$ErrorActionPreference = "Stop"
$root   = $PSScriptRoot
$server = Join-Path $root "server"

# Konfiguration zuerst pruefen, damit ein Tippfehler nicht erst nach dem Download auffaellt.
$configs = foreach ($file in Get-ChildItem "$root\cfg" -Filter "*.json") {
    $text = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    try { $null = $text | ConvertFrom-Json }
    catch { throw "Syntaxfehler in cfg\$($file.Name): $($_.Exception.Message)" }
    [pscustomobject]@{ Name = $file.Name; Text = $text }
}

# Sucht accServer.exe in den angegebenen Ordnern und gibt den Ordner zurueck, in dem sie liegt.
function Find-AccServer([string[]]$dirs) {
    foreach ($d in $dirs) {
        if (-not (Test-Path $d)) { continue }
        $exe = Get-ChildItem $d -Filter "accServer.exe" -Recurse -Depth 2 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($exe) { return $exe.DirectoryName }
    }
}

# Alle ACC-Ordner in allen Steam-Bibliotheken (Spiel und Dedicated-Server-Tool).
function Get-AccFolders {
    $steam = (Get-ItemProperty "HKCU:\Software\Valve\Steam" -ErrorAction SilentlyContinue).SteamPath
    $libs  = @("${env:ProgramFiles(x86)}\Steam", "$env:ProgramFiles\Steam")
    if ($steam) { $libs += $steam -replace "/", "\" }
    $vdf   = if ($steam) { Join-Path $steam "steamapps\libraryfolders.vdf" } else { "" }
    if ($vdf -and (Test-Path $vdf)) {
        $libs += Select-String -Path $vdf -Pattern '"path"\s+"([^"]+)"' |
            ForEach-Object { $_.Matches[0].Groups[1].Value -replace "\\\\", "\" }
    }
    foreach ($lib in $libs | Select-Object -Unique) {
        Get-ChildItem (Join-Path $lib "steamapps\common") -Directory -Filter "Assetto Corsa Competizione*" -ErrorAction SilentlyContinue |
            ForEach-Object { $_.FullName }
    }
}

if ($SteamUser) {
    $steamcmd = Join-Path $root "steamcmd"
    $download = Join-Path $root "steamapp"
    if (-not (Test-Path "$steamcmd\steamcmd.exe")) {
        New-Item -ItemType Directory -Force $steamcmd | Out-Null
        Invoke-WebRequest "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -OutFile "$steamcmd\steamcmd.zip"
        Expand-Archive "$steamcmd\steamcmd.zip" $steamcmd -Force
    }
    & "$steamcmd\steamcmd.exe" +force_install_dir $download +login $SteamUser +app_update 1430110 validate +quit
    $source = Find-AccServer @($download)
    if (-not $source) { throw "SteamCMD hat keinen Server geladen. Besitzt das Konto '$SteamUser' ACC? Meldung im SteamCMD-Fenster pruefen." }
} else {
    # Ein frueherer SteamCMD-Download in diesem Ordner zaehlt auch
    $source = Find-AccServer (@(Get-AccFolders) + @(Join-Path $root "steamapp"))
    if (-not $source) {
        throw ("Auf diesem PC ist kein ACC installiert (keine accServer.exe gefunden).`n" +
               "Server per Steam-Konto laden:  .\install.ps1 -SteamUser deinSteamName`n" +
               "Hast du schon einen Server-Ordner? Dann dort weiterarbeiten statt neu zu installieren.")
    }
}

Write-Host "Server-Dateien aus: $source"
New-Item -ItemType Directory -Force $server | Out-Null
Copy-Item "$source\*" $server -Recurse -Force

# Eigene Konfiguration einspielen. Der Server liest die JSON-Dateien nur als UTF-16 LE,
# in cfg\ liegen sie als UTF-8. Deshalb umwandeln statt einfach kopieren.
New-Item -ItemType Directory -Force "$server\cfg", "$server\results" | Out-Null
foreach ($c in $configs) {
    [IO.File]::WriteAllText((Join-Path "$server\cfg" $c.Name), $c.Text, [Text.Encoding]::Unicode)
}
Write-Host "Fertig. Server mit ACCDCServer.exe (oder start.bat) starten."
