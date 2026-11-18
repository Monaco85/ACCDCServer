# Optional: Weboberflaeche accweb (https://github.com/assetto-corsa-web/accweb) mit dem Race-Control-Design
# aus accweb-theme\. Damit startest, stoppst und konfigurierst du den Server im Browser.
#
# Voraussetzung: install.ps1 wurde ausgefuehrt (server\accServer.exe ist da).
# Aufruf: PowerShell -ExecutionPolicy Bypass -File .\install-accweb.ps1 -AdminPassword deinPasswort
#
# Beim ersten Lauf wird aus cfg\ ein Server in accweb angelegt. Danach pflegst du die Einstellungen
# im Browser; ein erneuter Lauf aktualisiert nur accweb und das Design, nicht deine Einstellungen.
param(
    [string]$AdminPassword,
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"
$root    = $PSScriptRoot
$dest    = Join-Path $root "accweb"
$version = "v1.27.0"   # das Design in accweb-theme\ ist fuer genau diese Version gebaut

if (-not (Test-Path "$root\server\accServer.exe")) {
    throw "server\accServer.exe fehlt. Zuerst install.ps1 ausfuehren."
}

# accweb herunterladen und entpacken
New-Item -ItemType Directory -Force $dest | Out-Null
$zip = Join-Path $env:TEMP "accweb_$version.zip"
$tmp = Join-Path $env:TEMP "accweb_$version"
Invoke-WebRequest "https://github.com/assetto-corsa-web/accweb/releases/download/$version/accweb_$version.zip" -OutFile $zip
if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
Expand-Archive $zip $tmp -Force
$extracted = Get-ChildItem $tmp -Filter "accweb.exe" -Recurse | Select-Object -First 1
if (-not $extracted) { throw "accweb.exe nicht im Download gefunden." }
Copy-Item "$($extracted.DirectoryName)\accweb.exe", "$($extracted.DirectoryName)\LICENSE" $dest -Force
Remove-Item $zip, $tmp -Recurse -Force

# Design einspielen. accweb liefert die Oberflaeche aus dem Ordner public\, wenn "dev: true" gesetzt ist.
$public = Join-Path $dest "public"
if (Test-Path $public) { Remove-Item $public -Recurse -Force }
New-Item -ItemType Directory -Force $public | Out-Null
Copy-Item "$root\accweb-theme\xindex.html", "$root\accweb-theme\dist", "$root\accweb-theme\static" $public -Recurse -Force

# config.yml nur beim ersten Mal schreiben, damit Passwoerter erhalten bleiben
$configYml = Join-Path $dest "config.yml"
if (-not (Test-Path $configYml)) {
    function New-Password { -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 14 | ForEach-Object { [char]$_ }) }
    if (-not $AdminPassword) { $AdminPassword = New-Password; $generated = $true }
    if ($AdminPassword -match "['`r`n]") { throw "Das Admin-Passwort darf kein ' und keinen Zeilenumbruch enthalten." }
    $serverPath = ($root -replace "\\", "/") + "/server"
    $yml = @"
webserver:
  host: 0.0.0.0:$Port
  tls: false
  cert: ""
  private_key: ""
  write_timeout: 5
  read_timeout: 5
auth:
  timeout: 12h
  admin_password: '$AdminPassword'
  moderator_password: '$(New-Password)'
  read_only_password: '$(New-Password)'
acc:
  server_path: "$serverPath"
  server_exe: accServer.exe
config_path: config/
# dev: true laedt die Oberflaeche aus public\ (Race-Control-Design) statt der eingebauten
dev: true
loglevel: info
cors:
  origins: "http://localhost:$Port"
  loglevel: info
log:
  with_timestamp: true
callback:
  enabled: false
"@
    [IO.File]::WriteAllText($configYml, $yml, (New-Object Text.UTF8Encoding $false))
    if ($generated) { Write-Host "Admin-Passwort (steht auch in accweb\config.yml): $AdminPassword" -ForegroundColor Yellow }
} elseif ($AdminPassword) {
    Write-Host "accweb\config.yml gibt es schon, das Passwort wurde nicht geaendert. Dort unter admin_password anpassen." -ForegroundColor Yellow
}

# Beim ersten Mal den Server aus cfg\ in accweb anlegen (Ordner accweb\config\acc1)
$instance = Join-Path $dest "config\acc1"
if (-not (Test-Path $instance)) {
    New-Item -ItemType Directory -Force $instance | Out-Null
    foreach ($file in Get-ChildItem "$root\cfg" -Filter "*.json") {
        $json = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8) | ConvertFrom-Json
        if ($file.Name -eq "settings.json" -and -not ($json.PSObject.Properties.Name -contains "ignorePrematureDisconnects")) {
            # accweb schreibt jedes Feld; ohne diesen Eintrag wuerde es 0 statt des ACC-Standards 1 speichern
            $json | Add-Member ignorePrematureDisconnects 1
        }
        $text = $json | ConvertTo-Json -Depth 10
        [IO.File]::WriteAllText((Join-Path $instance $file.Name), $text, [Text.Encoding]::Unicode)
    }
    $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $extra = @{
        "bop.json"          = '{ "entries": [], "configVersion": 1 }'
        "accwebConfig.json" = "{ `"id`": `"acc1`", `"md5Sum`": `"`", `"autoStart`": false, `"settings`": { `"autoStart`": true, `"enableAdvWindowsCfg`": false, `"advWindowsCfg`": null, `"enableGlobalEntrylist`": false, `"enableGlobalBanlist`": false }, `"createdAt`": `"$now`", `"updatedAt`": `"$now`" }"
    }
    foreach ($name in $extra.Keys) {
        if (-not (Test-Path (Join-Path $instance $name))) {
            [IO.File]::WriteAllText((Join-Path $instance $name), $extra[$name], [Text.Encoding]::Unicode)
        }
    }
    Write-Host "Server aus cfg\ in accweb angelegt (startet automatisch mit accweb)."
}

Write-Host "Fertig. start-accweb.bat starten und im Browser http://localhost:$Port oeffnen."
