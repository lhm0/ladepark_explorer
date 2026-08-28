# ADR-0017 – Statische, atomare Ladebestandsupdates

Status: Angenommen

Datum: 27. August 2026

## Kontext

FR-DATA-002 und NFR-RELIABILITY-001 verlangen monatliche Updates ohne Backend,
eine sichtbare Downloadgröße sowie den Erhalt des letzten funktionsfähigen
Bestands. Der Deutschlandbestand ist unkomprimiert rund 421 MiB groß. Das
öffentliche GitHub-Repository stellt Release-Assets ohne App-Zugangsschlüssel
bereit.

## Entscheidung

- Der BNetzA-Ladebestand wird als deterministisches gzip-Artefakt in einem
  GitHub Release veröffentlicht; das Manifest liegt als separates Release-
  Asset unter einer stabilen `releases/latest/download`-URL.
- Das Manifest enthält Schema- und Datensatzversion, Quelle, Lizenz,
  komprimierte und unkomprimierte Größe sowie beide SHA-256-Prüfsummen.
- Die App prüft standardmäßig beim Start nur das kleine Manifest. Download und
  Nutzung von WLAN oder Mobilfunk beginnen erst nach einer Bestätigung.
- Download, Größen- und Hashprüfung, Dekompression, zweite Hashprüfung,
  `PRAGMA integrity_check`, Schema- und Metadatenprüfung erfolgen vollständig
  vor der Aktivierung.
- Jeder Bestand liegt in einem unveränderlichen Versionsverzeichnis. Erst eine
  atomar ersetzte kleine `active.json`-Datei macht ihn aktiv. Der vorherige
  Bestand bleibt als Rollbackversion erhalten; ältere Versionen werden danach
  entfernt.
- Favoriten und Einstellungen bleiben in ihren getrennten lokalen Datenbanken.
- Redaktionelle Vor-Ort-Daten und eigene Fotos bleiben unabhängig gebündelt;
  ein Registerupdate kann sie nicht ersetzen.

## Folgen

Ein abgebrochener, beschädigter oder inkompatibler Download verändert den
aktiven Bestand nicht. GitHub ist hinter Manifest- und HTTP-Adaptern gekapselt
und kann später durch einen Objektspeicher ersetzt werden. SHA-256 schützt die
Integrität, aber ein Hash im selben Manifest ersetzt keine kryptografische
Herkunftssignatur; diese bleibt ein Freigabepunkt für M13.
