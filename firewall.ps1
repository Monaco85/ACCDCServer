# Als Administrator ausfuehren. Oeffnet die ACC-Ports in der Windows-Firewall.
# Die Ports kommen aus cfg\configuration.json. Erneut ausfuehren ersetzt die alten Regeln.
$ErrorActionPreference = "Stop"
$cfg = Get-Content "$PSScriptRoot\cfg\configuration.json" -Raw -Encoding UTF8 | ConvertFrom-Json

Get-NetFirewallRule -DisplayName "ACC Server *" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName "ACC Server TCP $($cfg.tcpPort)" -Direction Inbound -Protocol TCP -LocalPort $cfg.tcpPort -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "ACC Server UDP $($cfg.udpPort)" -Direction Inbound -Protocol UDP -LocalPort $cfg.udpPort -Action Allow | Out-Null
# Erlaubt accServer.exe zusaetzlich alles Eingehende, damit auch die LAN-Suche durchkommt.
New-NetFirewallRule -DisplayName "ACC Server Programm" -Direction Inbound -Program "$PSScriptRoot\server\accServer.exe" -Action Allow | Out-Null
Write-Host "Firewall-Regeln angelegt: TCP $($cfg.tcpPort), UDP $($cfg.udpPort) und server\accServer.exe"
