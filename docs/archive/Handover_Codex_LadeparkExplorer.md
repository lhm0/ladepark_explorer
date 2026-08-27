# Handover für Codex -- Projekt Ladepark Explorer

> **Historisches Übergabedokument:** Dieses Dokument hält den Diskussionsstand
> vor Erstellung des Spezifikationskerns fest. Bei Widersprüchen sind
> `PROJECT_STATUS.md`, `docs/README.md`, die Kapitel unter
> `docs/specification/` und die angenommenen ADRs unter `docs/adr/` maßgeblich.

Version: 1.0\
Stand: Juli 2026

# Zweck

Dieses Dokument fasst die Ergebnisse der bisherigen Architektur- und
Produktdiskussion vollständig zusammen. Es dient als Übergabedokument
für die weitere Entwicklung mit Codex und soll verhindern, dass
wesentliche Entscheidungen verloren gehen.

------------------------------------------------------------------------

# Projektidee

Entwicklung einer App für iOS und Android, die sich auf **Ladeparks**
für Elektrofahrzeuge spezialisiert.

Der entscheidende Unterschied zu bestehenden Apps:

> Das zentrale Objekt ist nicht die Ladesäule, sondern der Ladepark.

Die App ist eine Planungs- und Analyseanwendung, keine Roaming- oder
Bezahl-App.

------------------------------------------------------------------------

# Motivation

Bestehende Anwendungen beantworten überwiegend:

-   Wo ist die nächste Ladesäule?
-   Wo ist aktuell ein Ladepunkt frei?

Das Projekt beantwortet stattdessen:

-   Wo befinden sich große Ladeparks?
-   Welche Ladeparks besitzen besonders viele HPC-Ladepunkte?
-   Welche Betreiber bauen große Standorte?
-   Welche Ladeparks eignen sich besonders für Langstrecken?

------------------------------------------------------------------------

# Strategische Entscheidung

Version 1 verzichtet bewusst auf Live-Daten.

Begründung:

-   deutlich geringere Komplexität
-   keine Betreiber-APIs notwendig
-   praktisch keine Backendkosten
-   schneller Markteintritt
-   Validierung der Produktidee vor größerer Investition

Die Architektur wird jedoch von Anfang an so ausgelegt, dass Live-Daten
später ergänzt werden können.

------------------------------------------------------------------------

# Roadmap

## Version 1.0

-   Bundesnetzagentur als Datenquelle
-   Bildung logischer Ladeparks
-   Deutschlandkarte
-   lokale SQLite-Datenbank
-   Offlinefähigkeit
-   leistungsfähige Filter
-   Favoriten

Keine:

-   Live-Belegung
-   Preise
-   Navigation
-   Bezahlfunktionen

## Version 1.5

-   Fotos
-   Statistiken
-   Top-100 Ladeparks
-   zusätzliche POIs

## Version 2.0

-   Backend
-   PostgreSQL/PostGIS
-   Redis
-   FastAPI
-   AFIR/DATEX II
-   Live-Status
-   Preise

------------------------------------------------------------------------

# Zielarchitektur Version 1

Bundesnetzagentur ↓ Python Importer ↓ SQLite + manifest.json ↓
Cloudflare R2 ↓ Flutter + MapLibre ↓ lokale SQLite

Es existiert kein dauerhaft laufendes Backend.

------------------------------------------------------------------------

# Hosting

Empfohlen:

-   Cloudflare R2
-   eigene Domain
-   manifest.json
-   versionierte SQLite-Dateien

App lädt zunächst nur manifest.json und anschließend bei Bedarf einen
neuen Datensatz.

------------------------------------------------------------------------

# Datenquelle

Primäre Quelle:

Bundesnetzagentur Ladesäulenregister.

Importer übernimmt:

-   Download
-   Validierung
-   Normalisierung
-   Clusterbildung
-   SQLite-Export
-   manifest.json

------------------------------------------------------------------------

# Domänenmodell

Das Projekt arbeitet bereits in Version 1 mit einem zukünftigen
Datenmodell.

Entitäten:

-   charging_park
-   station
-   evse
-   connector
-   operator
-   source_reference

Version 1 nutzt überwiegend charging_park.

------------------------------------------------------------------------

# Zentrale Architekturentscheidung

Alle Objekte erhalten stabile interne IDs.

Nicht:

Bundesnetzagentur-ID

Sondern:

park_id

Diese ID bleibt dauerhaft bestehen.

Dadurch können später

-   Live-Daten
-   Bewertungen
-   Fotos
-   Historie

ohne Architekturänderung ergänzt werden.

------------------------------------------------------------------------

# Ladeparkbildung

Importer gruppiert Ladepunkte anhand von:

-   Betreiber
-   räumlicher Nähe
-   Adresse
-   gemeinsamer Zufahrt

Das Ergebnis ist ein logischer Ladepark.

Clusteralgorithmus wird später separat spezifiziert.

------------------------------------------------------------------------

# Flutter

Empfehlung:

-   Flutter
-   MapLibre
-   Clean Architecture
-   Repository Pattern
-   Riverpod (noch endgültig zu bewerten)

Offline First.

Alle Filter laufen lokal.

------------------------------------------------------------------------

# SQLite

SQLite wird als Austauschformat verwendet.

Nicht GeoJSON.

Vorteile:

-   schnelle Filter
-   SQL
-   lokale Indizes
-   Offlinebetrieb

------------------------------------------------------------------------

# Live-Daten (später)

Für Version 2 wurde folgende Zielarchitektur diskutiert:

PostgreSQL/PostGIS + Redis + FastAPI

Live-Daten werden getrennt von Stammdaten gespeichert.

Redis:

-   aktueller Status

PostgreSQL:

-   Stammdaten
-   Historie

------------------------------------------------------------------------

# Wettbewerbspositionierung

Der Ladepark Explorer konkurriert nicht primär mit:

-   EnBW mobility+
-   PlugShare
-   ChargeFinder
-   Chargemap
-   ABRP

Sondern ergänzt diese.

USP:

Fokus auf Ladeparks als Planungseinheit.

------------------------------------------------------------------------

# Designprinzipien

1.  Ladepark statt Ladesäule
2.  Offline First
3.  Performance vor Funktionsumfang
4.  geringe Betriebskosten
5.  Erweiterbarkeit
6.  Clean Architecture
7.  reproduzierbare Datenpipeline

------------------------------------------------------------------------

# Dokumentationsstrategie

Es wird kein einzelnes großes Dokument gepflegt.

Stattdessen entsteht ein Dokumentations-Repository.

Geplante Struktur:

docs/ 01_ProjectVision.md 02_Requirements.md 03_SystemArchitecture.md
04_DataModel.md 05_Importer.md 06_Clustering.md 07_SQLite.md
08_FlutterArchitecture.md 09_UIGuidelines.md 10_APIFuture.md ...

Zusätzlich:

ADR/ Research/ Specification/

Diese Dokumente bilden gemeinsam das Software Design Handbook.

------------------------------------------------------------------------

# Nächster Schritt

Das erste Dokument (01_ProjectVision.md) wurde als Entwurf erstellt.

Es soll nun erheblich erweitert werden.

Ziel:

ca. 15--20 Seiten mit:

-   Executive Summary
-   Produktvision
-   Motivation
-   Marktanalyse
-   Wettbewerbsanalyse
-   Personas
-   Stakeholder
-   Out-of-Scope
-   Produktprinzipien
-   KPIs
-   Risiken
-   Annahmen
-   Glossar

Erst danach folgen Requirements und Domain Model.

------------------------------------------------------------------------

# Arbeitsweise mit Codex

Das Git-Repository wird direkt mit Codex bearbeitet.

Empfohlener Prozess:

1.  Ein Dokument vollständig ausarbeiten.
2.  Review.
3.  Commit.
4.  Erst danach nächstes Dokument.

Die Dokumentation ist die "Single Source of Truth".

Code wird grundsätzlich aus der Dokumentation abgeleitet.

------------------------------------------------------------------------

# Wichtigste Erkenntnis

Die größte Innovation dieses Projekts ist **nicht** eine neue
Karten-App.

Sie besteht darin, den **Ladepark** als zentrales Domänenobjekt zu
etablieren und daraus eine spezialisierte Planungsplattform für
Langstreckenfahrer und HPC-Infrastruktur zu entwickeln.

Alle späteren Architektur- und Implementierungsentscheidungen müssen mit
diesem Grundgedanken vereinbar bleiben.
