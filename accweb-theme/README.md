# Race-Control-Design für accweb

Fertig gebaute Oberfläche für [accweb](https://github.com/assetto-corsa-web/accweb) 1.27.0. `install-accweb.ps1` kopiert sie nach `accweb\public\`, accweb liefert sie mit `dev: true` aus diesem Ordner aus.

| Datei | Inhalt |
|---|---|
| `xindex.html`, `dist\build.js`, `static\` | Die gebaute Oberfläche |
| `theme.patch` | Alle Änderungen am accweb-Quellcode (Tag `v1.27.0`): Design in `main.scss`, Kopfzeile, Serverkarte mit Restart, "Save & restart", `util/restart.js` |
| `LICENSE-accweb` | Lizenz von accweb (MIT) |

Neu bauen: accweb auf Tag `v1.27.0` auschecken, `git apply theme.patch`, dann in `public\` `npm ci` und `npx webpack --mode=production`. Danach `public\xindex.html` und `public\dist\build.js` hierher kopieren.
