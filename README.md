# Ladepark Explorer

Der Ladepark Explorer ist eine offline-first iPhone-App zur Recherche räumlich
zusammenhängender Ladestandorte in Deutschland. Der aktuelle Entwicklungsstand
und die verbindliche Projektdokumentation werden getrennt gepflegt.

Version 1.1 („Routen-Update“, App-Version `1.1.0`) ist funktional eingefroren:
zusätzlich zur Recherche plant die App eine Autoroute, sucht Ladeparks im
Korridor, nimmt manuell gesetzte Ladestopps auf, färbt die Route nach
geschätztem Ladezustand und übergibt sie an Apple Maps oder Google Maps. Die
Release-Härtung (M13) und die Fortsetzung der Routenplanung (M17/M18, Version
1.2) stehen noch aus.

## Einstieg

1. [Projektstatus](PROJECT_STATUS.md)
2. [Änderungshistorie](CHANGELOG.md)
3. [Technische Übergabe für die Weiterentwicklung](docs/AI_HANDOVER.md)
4. [Dokumentationsübersicht](docs/README.md)
5. [Produktvision](docs/specification/01_ProjectVision.md)
6. [Anforderungen](docs/specification/02_Requirements.md)
7. [Arbeitsanweisungen für Codex](AGENTS.md)

## Repository-Struktur

- `importer/` – Python-Datenpipeline und SQLite-Erzeugung,
- `app/` – Flutter-App,
- `contracts/` – versionierte sprachübergreifende Datensatzverträge,
- `tooling/` – kleine projektweite Struktur- und Dokumentationsprüfungen,
- `docs/specification/` – verbindliche Produkt- und Systemspezifikation,
- `docs/adr/` – Architekturentscheidungen,
- `docs/archive/` – historische, nicht verbindliche Dokumente,
- `data/` – lokale Roh- und Buildartefakte; große Datensätze bleiben außerhalb
  der Versionskontrolle.

Version 1.0 und 1.1 besitzen kein dauerhaftes fachliches Backend. Maßgeblich
für Scope, Verhalten und technische Entscheidungen sind die verlinkte
Spezifikation und die angenommenen ADRs.

## License

Copyright © 2026 Ludwin Monz. All rights reserved. The repository is publicly
visible, but no permission to use, copy, modify, or redistribute the original
project code, documentation, or editorial content is granted. Third-party
software and externally sourced data remain subject to their respective
licenses; details are documented in the
[license and data-source dossier](docs/specification/15_License_Compliance.md).
