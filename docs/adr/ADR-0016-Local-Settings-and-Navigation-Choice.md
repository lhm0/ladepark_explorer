# ADR-0016 – Lokale Einstellungen und Wahl der Navigations-App

Status: Angenommen

Datum: 27. August 2026

## Kontext

FR-I18N-001 verlangt eine von der Systemsprache unabhängige Sprachwahl.
FR-NAV-001 verlangt Apple Maps, das installierte Google Maps und einen
verständlichen Fallback. Diese Präferenzen dürfen weder vom austauschbaren
Ladebestand abhängen noch ein Konto oder Backend voraussetzen.

## Entscheidung

- Sprache und bevorzugte Navigations-App werden in einer eigenen,
  schema-versionierten SQLite-Datei im Application-Support-Verzeichnis
  gespeichert.
- Unterstützte Sprachwerte sind Systemsprache, Deutsch und Englisch. Bei einer
  nicht unterstützten Systemsprache verwendet die App Deutsch.
- Unterstützte Navigationswerte sind „jedes Mal fragen“, Apple Maps und Google
  Maps. Der Standard ist „jedes Mal fragen“.
- Google Maps wird auf iOS über `canOpenURL` und das registrierte
  `comgooglemaps`-Schema erkannt. Die App übergibt nur die Zielkoordinaten und
  den Fahrmodus.
- Ist Google Maps nicht installiert, wird es nicht als neue Präferenz
  angeboten. Ist es nach einer früheren Auswahl nicht mehr verfügbar, fragt
  die App vor dem Öffnen von Apple Maps nach.
- Persistenz, Zustand und native Navigation bleiben hinter getrennten
  Repository- beziehungsweise Adapterverträgen.

## Folgen

Einstellungen überleben App-Neustarts und Datensatzwechsel, werden aber bei
einer Deinstallation entfernt. Eine spätere Erweiterung um Update- und
Datenschutzeinstellungen kann dasselbe Schlüssel-Wert-Schema migrationssicher
verwenden. Apple Maps bleibt der verfügbare iOS-Fallback; die eigentliche
Navigation ist weiterhin keine Funktion des Ladepark Explorers.
