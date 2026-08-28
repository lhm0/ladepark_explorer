# Ladepark Explorer – Projektdokumentation

Diese Dokumentation ist die verbindliche Wissensbasis für Produktentwicklung,
Architektur und Implementierung. Neue Codex-Chats sollen hier beginnen.

## Einstieg

1. [Projektstatus](../PROJECT_STATUS.md)
2. [Technische Übergabe für die Weiterentwicklung](AI_HANDOVER.md)
3. [Projektvision](specification/01_ProjectVision.md)
4. [Anforderungen](specification/02_Requirements.md)
5. [Systemarchitektur](specification/03_System_Architecture.md)
6. [Domänenmodell und Glossar](specification/04_Data_Model.md)
7. [Lizenz- und Datenquellen-Dossier](specification/15_License_Compliance.md)
8. [Datenschutz und Diagnostik](specification/16_Privacy_and_Diagnostics.md)
9. [Roadmap](specification/14_Roadmap.md)
10. [Routenplanung – Version 1.1](specification/17_Route_Planning.md)

Die übrigen Kapitel vertiefen Importer, Clustering, SQLite, Flutter, UI,
zukünftige APIs, Tests, Deployment und Coding Guidelines.

## Struktur

- `specification/` – verbindliche fachliche und technische Kapitel,
- `adr/` – angenommene und vorgeschlagene Architecture Decision Records,
- `diagrams/` – Architektur- und Datenflussdiagramme,
- `archive/` – historische Übergaben und Arbeitsvorschläge; nicht verbindlich.

Historische Dokumente bleiben zur Nachvollziehbarkeit erhalten, gehören aber
nicht zur aktuellen Spezifikation. Bei Widersprüchen gelten der Projektstatus,
die Kapitel unter `specification/` und die angenommenen ADRs.

Der aktuelle Entwicklungsstand steht in `../PROJECT_STATUS.md`. Verbindliche
Arbeitsanweisungen für neue Codex-Chats stehen in `../AGENTS.md`.

Aktuelle Architekturentscheidungen:

- [ADR-0001 – Version 1.0 ohne fachliches Backend](adr/ADR-0001-Architecture.md)
- [ADR-0002 – Stabile interne Identitäten](adr/ADR-0002-Stable-Identifiers.md)
- [ADR-0003 – Lizenzsichere Datentrennung](adr/ADR-0003-License-Safe-Data-Separation.md)
- [ADR-0004 – Dynamische Abstandsgruppen](adr/ADR-0004-Dynamic-Proximity-Groups.md)
- [ADR-0005 – Python-Toolchain für den Importer](adr/ADR-0005-Python-Importer-Toolchain.md)
- [ADR-0006 – Flutter mit Apple MapKit](adr/ADR-0006-Flutter-Apple-MapKit.md)
- [ADR-0007 – Modulares Monorepo und Datensatzvertrag](adr/ADR-0007-Modular-Monorepo-and-Dataset-Contract.md)
- [ADR-0008 – Direkter SQLite-Zugriff und Riverpod-Komposition](adr/ADR-0008-Flutter-SQLite-and-State-Management.md)
- [ADR-0009 – Native MapKit-Integration als iOS Platform View](adr/ADR-0009-Native-MapKit-Platform-View.md)
- [ADR-0010 – Packaging des mitgelieferten Basisdatensatzes](adr/ADR-0010-Bundled-Base-Dataset-Packaging.md)
- [ADR-0011 – Opake Detailroute über MapKit](adr/ADR-0011-Opaque-Detail-Route-over-MapKit.md)
- [ADR-0012 – Getrennter redaktioneller Ladepark-Informationsbestand](adr/ADR-0012-Curated-Park-Information-Dataset.md)
- [ADR-0013 – Lokale Standortsuche und eingehende Koordinaten](adr/ADR-0013-Location-Search-and-Inbound-Coordinates.md)
- [ADR-0014 – Getrennter lokaler Favoritenspeicher](adr/ADR-0014-Local-Favorite-Store.md)
- [ADR-0015 – Konservativer Filter für durchgehende Zugänglichkeit](adr/ADR-0015-Structured-Opening-Hours-Filter.md)
- [ADR-0016 – Lokale Einstellungen und Wahl der Navigations-App](adr/ADR-0016-Local-Settings-and-Navigation-Choice.md)
- [ADR-0017 – Statische, atomare Ladebestandsupdates](adr/ADR-0017-Static-Dataset-Updates.md)
- [ADR-0018 – Keine Telemetrie in Version 1.0](adr/ADR-0018-No-Telemetry-in-Version-1.md)
- [ADR-0019 – Plattformneutraler Route-Planning-Service](adr/ADR-0019-Route-Planning-Service.md)
- [ADR-0020 – Energie- und Segmentmodell hinter austauschbaren Schnittstellen](adr/ADR-0020-Energy-and-Segment-Model.md)
- [ADR-0021 – Lokaler Fahrzeugprofil-Speicher](adr/ADR-0021-Vehicle-Profile-Store.md)
- [ADR-0022 – Routenkorridor-Suche über Abtastung der Polyline](adr/ADR-0022-Route-Corridor-Search.md)
- [ADR-0023 – Ladezustandsfärbung der Route](adr/ADR-0023-Route-State-Of-Charge-Colouring.md)

## Verbindlichkeit

- Implementierter und überprüfter Ist-Zustand wird als solcher dokumentiert.
- Geplante Eigenschaften werden ausdrücklich als „geplant“ markiert.
- Wesentliche Architekturentscheidungen erhalten ein ADR.
- Änderungen an Verhalten, Datenmodell oder Architektur aktualisieren im selben
  Commit die betroffene Dokumentation.
