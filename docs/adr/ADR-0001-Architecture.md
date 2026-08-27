# ADR-0001 – Version 1.0 ohne dauerhaftes fachliches Backend

Status: Angenommen

Datum: 26. Juli 2026

## Kontext

Version 1.0 soll die Produktidee eines ladeparkzentrierten, offline nutzbaren
Explorers validieren. Live-Belegung, Preise, Benutzerkonten und
Community-Inhalte sind nicht Teil dieses Releases. Ein dauerhaftes Backend
würde Betrieb, Datenschutz, Sicherheit und Entwicklung erheblich erweitern,
ohne für die Kernabläufe zwingend erforderlich zu sein.

## Entscheidung

Version 1.0 verwendet:

- eine offline nutzbare mobile App,
- einen mitgelieferten und lokal gespeicherten SQLite-Datensatz,
- statisch bereitgestellte, versionierte Datensatzupdates,
- lokale Favoriten,
- optional einen getrennten Telemetrie-/Fehlerberichtsdienst nach Einwilligung.

Version 1.0 verwendet kein dauerhaftes fachliches Anwendungsbackend. Statischer
Objektspeicher und optionale Telemetrie gelten nicht als fachliches Backend.

## Folgen

Positiv:

- geringe laufende Kosten und geringe betriebliche Komplexität,
- Kernfunktionen sind offline und mit niedriger Latenz verfügbar,
- keine Konten- oder Community-Daten zu schützen,
- Datenstände sind versionierbar und reproduzierbar.

Negativ:

- keine Live-Daten,
- keine Community-Funktionen,
- keine Synchronisation von Favoriten,
- Datenkorrekturen erreichen Geräte erst mit einem Datensatzupdate,
- Online-Geocoding muss getrennt betrachtet oder lokal ersetzt werden.

## Spätere Erweiterung

Community- und Live-Funktionen können in späteren Versionen ein Backend
ergänzen. Stammdaten, Live-Status und nutzergenerierte Inhalte bleiben dabei
fachlich getrennte Bereiche. Diese Erweiterung hebt die Entscheidung für
Version 1.0 nicht rückwirkend auf.

## Verworfene Alternative

Ein Backend bereits für Version 1.0 wurde verworfen, weil es für Karte, lokale
Suche, Filter, Details, Favoriten und statische Updates nicht erforderlich ist.
