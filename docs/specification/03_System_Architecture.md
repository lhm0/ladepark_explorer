# Systemarchitektur – Version 1.0

Status: Verbindlicher Spezifikationskern

Stand: 26. Juli 2026

## 1. Architekturziele

Die Architektur von Version 1.0 priorisiert:

1. offline nutzbare Kernfunktionen,
2. geringe laufende Betriebskosten,
3. reproduzierbare und überprüfbare Datenaufbereitung,
4. schnelle lokale Suche und Filterung,
5. ausfallsichere Datensatzaktualisierungen,
6. spätere Android-Portierbarkeit,
7. Erweiterbarkeit um Community- und Live-Funktionen ohne deren vorzeitige
   Implementierung.

## 2. Systemkontext

```text
Bundesnetzagentur ─┐
OpenStreetMap ─────┼──> Importer und Datenpflege
Eigene Vor-Ort-Daten ┘             │
                                     ▼
                  charging.sqlite + park_info.sqlite
                    + optionale osm_amenities.sqlite
                    + Bilddateien + manifest.json
                                 │
                                 ▼
                       Statische Distribution
                                 │
                                 ▼
                 iPhone-App (Flutter + Apple MapKit)
                    │       │          │
                    │       │          └──> Apple Maps / Google Maps
                    │       └─────────────> optionale Telemetrie
                    └─────────────────────> lokale Favoriten
```

Die Bundesnetzagentur ist die primäre Quelle für Ladeinfrastruktur.
Eigene Vor-Ort-Erhebungen und optional OpenStreetMap ergänzen insbesondere
Infrastrukturmerkmale. Die konkrete Auswahl weiterer Quellen setzt eine
Lizenzprüfung voraus. Quellen, Beschaffungsgrenzen und Attributionen sind in
`15_License_Compliance.md` festgelegt.

## 3. Komponenten und Verantwortlichkeiten

### 3.1 Importer und Datenpflege

Verantwortlich für:

- Abruf beziehungsweise Einlesen versionierter Quelldaten,
- Validierung und Normalisierung,
- Bildung stabiler fachlicher Objekte,
- Vorbereitung dynamischer Abstandsgruppen für definierte Durchmesser,
- Anwendung versionierter manueller Zusammenführungs- und Trennregeln,
- Zusammenführung von Infrastrukturmerkmalen mit Herkunftsnachweis,
- Erstellung der SQLite-Datenbank und des Manifests,
- Qualitätsbericht und Regressionstests.

Der Importer ist ein Build-Werkzeug und kein dauerhaft laufender Dienst.

### 3.2 Datensatzartefakte

Die App erhält:

- eine versionierte SQLite-Datenbank mit BNetzA-basierten Ladestandorten,
- eine getrennte redaktionelle SQLite-Datenbank mit selbst erhobenen
  Standortinformationen und Referenzen auf optimierte eigene Bilddateien,
- eine getrennte, ODbL-lizenzierte SQLite-Datenbank mit OSM-Infrastruktur,
- ein Manifest mit Datensatzversion, Erstellungszeitpunkt, Quellenständen,
  Schema- und Pipeline-Version, Dateigröße und kryptografischer Prüfsumme.

Das genaue Schema wird in `07_SQLite.md` spezifiziert. Änderungen am
Datenaustauschformat werden explizit versioniert.

Die Trennung folgt ADR-0003 und ADR-0012. Redaktionelle und OSM-Daten steuern
in Version 1.0 nicht automatisch die persistente Bildung oder Identität eines
Ladeparks.

### 3.3 Statische Distribution

Ein statischer Objektspeicher stellt Manifest und versionierte
Datensatzdateien bereit. Cloudflare R2 ist derzeit die bevorzugte, aber noch
nicht endgültig bestätigte Lösung.

Die Distribution enthält keine fachliche API, Benutzerverwaltung oder
serverseitige Suche.

### 3.4 Mobile App

Die App ist verantwortlich für:

- Karte, lokale Suche, Filter und Detailansicht,
- Zugriff auf den lokalen Datensatz,
- lokale Favoriten,
- Standortberechtigung und Umkreissuche,
- Prüfung, Download, Verifikation und atomaren Wechsel des Datensatzes,
- Übergabe eines Navigationsziels an externe Karten-Apps,
- Sprach- und Datenschutzeinstellungen.

Fachlogik und Datenzugriff werden von plattformspezifischen Funktionen
getrennt. Flutter, Apple MapKit für iOS und ein Repository Pattern sind
entschieden. Die Kartenschnittstelle erhält später einen eigenen
Android-Adapter. Riverpod übernimmt State Management und Dependency
Composition gemäß ADR-0008.

### 3.5 Externe Navigations-Apps

Apple Maps und optional Google Maps übernehmen die eigentliche Navigation. Der
Ladepark Explorer übergibt in Version 1.0 die Koordinate der Anker-Station oder
einer vom Nutzer gewählten Station. Ein bestätigter Zufahrtspunkt kann ab einer
späteren Regelversion verwendet werden. Die App prüft Google Maps über dessen
iOS-URL-Schema, speichert die bevorzugte Ziel-App lokal und bietet bei
Nichtverfügbarkeit Apple Maps als Fallback an.

### 3.6 Optionale Telemetrie

Ein noch auszuwählender Dienst darf nach Einwilligung ausschließlich
dokumentierte, datensparsame Diagnose- und Nutzungsereignisse empfangen.
Telemetrie ist von allen fachlichen Kernfunktionen getrennt. Der Ausfall oder
die Ablehnung der Telemetrie darf die App nicht einschränken.

## 4. Hauptdatenflüsse

### 4.1 Erzeugung eines Datensatzes

1. Quelldaten werden mit Datum und Herkunft erfasst.
2. Der Importer validiert und normalisiert die Daten.
3. Ladepunkte werden zu Ladestandorten gruppiert.
4. Infrastrukturangaben und manuelle Regeln werden angewendet.
5. Automatisierte Qualitäts- und Regressionstests laufen.
6. SQLite-Datei, Manifest und Qualitätsbericht werden erzeugt.
7. Nach erfolgreicher Prüfung werden unveränderliche Artefakte veröffentlicht.

### 4.2 Installation und erster Start

1. Die App enthält einen Basisdatensatz.
2. Sie öffnet diesen lokal und bietet Karte, Suche und Filter an.
3. Nur bei aktivierter automatischer Prüfung fragt sie nach einem neuen
   Manifest.
4. Standort- oder Telemetrieberechtigungen werden zweckbezogen und getrennt
   eingeholt.

### 4.3 Datensatzupdate

1. Die App lädt das Manifest.
2. Sie vergleicht Datensatz- und Schemaversion mit dem lokalen Stand.
3. Nach Nutzerfreigabe beziehungsweise gemäß Einstellung lädt sie das Artefakt
   über WLAN oder Mobilfunk.
4. Sie prüft Dateigröße, Prüfsumme, Schema und Lesbarkeit.
5. Erst danach ersetzt sie den aktiven Datensatz atomar.
6. Bei jedem Fehler bleibt der bisherige Datensatz aktiv.

### 4.4 Lokale Recherche

Kartenbereich, Suchtext und Filter werden gegen lokale Indizes ausgewertet.
Favoriten werden über stabile `station_id`-Anker mit der aktuell gewählten
Abstandsgruppe verbunden. Online-Geocoding darf die lokale Suche ergänzen, aber
nicht ersetzen.

## 5. Systemgrenzen

Version 1.0 besitzt kein dauerhaftes fachliches Backend. Daraus folgen:

- keine Benutzerkonten,
- keine Community-Inhalte,
- keine geräteübergreifende Synchronisation,
- keine Live-Belegungs- oder Preisdaten,
- keine serverseitigen Filter oder Suchabfragen.

Die statische Bereitstellung von Datensätzen und optionale Telemetrie gelten
nicht als fachliches Anwendungsbackend.

## 6. Sicherheits- und Datenschutzgrenzen

- Datensatzdownloads erfolgen verschlüsselt.
- Artefakte werden vor Aktivierung kryptografisch geprüft.
- Es werden keine geheimen Zugangsdaten in App oder Datensatz abgelegt.
- Standortdaten verlassen für Kernfunktionen nicht das Gerät.
- Externes Geocoding und Navigation werden als Datenweitergabe an den jeweiligen
  Anbieter erkennbar gemacht, soweit rechtlich beziehungsweise technisch
  erforderlich.
- Telemetrie arbeitet nur nach Einwilligung und ohne Werbe-ID oder
  personenbezogenes Profil.

## 7. Technologieentscheidungen

### Entschieden

- Flutter als plattformübergreifende App-Basis,
- Apple MapKit für die iPhone-Version 1.0 ohne nutzungsabhängige
  Kartenabrechnung,
- eine eigene plattformneutrale Kartenschnittstelle; Android erhält später
  einen getrennten Adapter, voraussichtlich auf Basis von MapLibre,
- SQLite als lokaler Daten- und Austauschbestand,
- statische, versionierte Datensatzdistribution,
- getrennter redaktioneller Informationsbestand gemäß ADR-0012,
- Python als vorgesehene Importer-Technologie,
- stabile interne IDs gemäß ADR-0002,
- getrennte BNetzA- und OSM-Artefakte gemäß ADR-0003,
- modularer Monorepo-Aufbau und ausführbarer Datensatzvertrag gemäß ADR-0007,
- direkter read-only SQLite-Zugriff und Riverpod-Komposition gemäß ADR-0008,
- native MapKit-Integration als UIKit Platform View gemäß ADR-0009,
- kein dauerhaftes fachliches Backend in Version 1.0.

### App-seitiger Datenzugriff

- Die UI greift ausschließlich über ein `ChargingRepository` auf den
  Ladebestand zu und enthält kein SQL.
- Der versionierte Ladebestand wird read-only geöffnet. Favoriten und
  Einstellungen liegen in einem getrennten lokalen Benutzerspeicher.
- Datenbankabfragen laufen asynchron außerhalb des UI-Threads.
- Python-Importer und Flutter-App verwenden dieselben kleinen
  Referenzdatenbanken als Contract Tests und müssen identische Gruppen-IDs,
  Filtergrenzen und Sortierungen liefern.
- Kartenabfragen liefern höchstens 500 kompakte Gruppenzusammenfassungen.
  Stations-, Betreiber-, Connector- und Leistungsdetails werden erst nach
  Auswahl einer Gruppe geladen.
- Datensatzupdates ersetzen nur den Ladebestand und werden nach vollständiger
  Prüfung atomar aktiviert; der Benutzerspeicher bleibt unberührt.

### Noch offen

- Android-Kartenadapter und dessen Kartenversorgung,
- Geocodinganbieter,
- Telemetrie- und Crash-Reporting-Anbieter,
- endgültiger Objektspeicher und Domainstruktur,
- endgültiger Signierungs- und App-Store-Prozess.

Offene Entscheidungen werden vor Implementierung der betroffenen Komponente
durch ADRs festgehalten.

## 8. Bezug zu Anforderungen

| Architekturteil | Hauptanforderungen |
| --- | --- |
| Importer und Datensatz | FR-DATA-001 bis 003, NFR-DATA-001 |
| Lokale App-Datenhaltung | FR-FILTER-001 bis 003, FR-FAV-001, NFR-OFFLINE-001 |
| Updateverfahren | FR-DATA-002, NFR-RELIABILITY-001 |
| Karte und Standort | FR-MAP-001/002, FR-SEARCH-001/002 |
| Navigation | FR-NAV-001 |
| Lokalisierung | FR-I18N-001 |
| Telemetrie | FR-PRIV-001 |
| Plattformtrennung | NFR-PORT-001 |
