# Roadmap

Status: Produktroadmap – Termine noch offen

## 1.0
- Importer
- SQLite
- iPhone-App auf gemeinsamer Flutter-Codebasis
- Karte
- Suche, Filter und Details
- eigener redaktioneller Informationsbestand mit selbst erhobenen
  Standortmerkmalen und Fotos ausgewählter Ladeparks
- dynamische Abstandsgruppen mit konfigurierbarem maximalem Gruppendurchmesser
- lokale Favoriten
- Übergabe an Apple Maps und Google Maps
- statische Datensatzupdates
- Deutsch und Englisch
- keine Community-Funktionen und kein fachliches Backend

### Offene Implementierungsmeilensteine für 1.0

- **M6 – Suche und Standort (implementiert):** lokale Textsuche, eigener
  Standort, Umkreissuche und eingehende Direktkoordinaten.
- **M7 – Favoriten (implementiert):** rein lokale Speicherung, Detail-Herz,
  eigene Liste, Kartenfilter und Auflösung über stabile Stationsanker.
- **M8 – Redaktionelle Ladeparkinformationen (implementiert und manuell
  abgenommen):** JSON-Pflegequelle, getrennter `park_info.sqlite`-Bestand, eigene
  Vor-Ort-Merkmale, geprüfte eigene App-Bilder, Build-Validierung und
  Darstellung in der Detailansicht. Der erste Produktbestand enthält Emstek,
  Hilden und Kamen mit sechs Bildern. Ein automatisierter Bilddarstellungstest
  bleibt als Härtungsaufgabe offen.
- **M9 – Weitere Filter (implementiert):** Infrastrukturfilter,
  Umkreisbegrenzung und konservativ strukturierter 24/7-Filter sind im
  gemeinsamen Filterzustand umgesetzt. Eine optionale OSM-Ergänzung bleibt
  davon getrennt.
- **M10 – Navigation, Sprache und Einstellungen (implementiert):** Google Maps
  mit Apple-Maps-Fallback, unabhängige Sprachauswahl und persistente lokale
  Einstellungen.
- **M11 – Statische Datensatzupdates:** Manifest, Download, Verifikation,
  atomarer Wechsel und Rollback.
- **M12 – Datenschutz und Diagnostik:** Entscheidung über einen vollständigen
  Verzicht oder eine ausdrücklich einwilligungsbasierte Telemetrie.
- **M13 – Release-Härtung:** Performance, Offlineverhalten,
  Zugänglichkeit, Lizenznachweise, TestFlight und App-Store-Vorbereitung.

## 1.5
- breiterer Foto- und Informationsbestand
- Bewertungen und Kommentare
- Feedback zu zusammengehörigen beziehungsweise getrennten Ladeeinrichtungen
- versionierte `verified_park`-Regeln nach Aggregation und Review
- Benutzerkonten und Moderation
- Statistiken
- Top-100 Ladeparks
- Android-Veröffentlichung bei erfolgreichem iPhone-Start

## 2.0
- Live-Daten
- Preise
- Backend-Technologien nach gesonderter Architekturentscheidung
