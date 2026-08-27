# SQLite- und Manifestvertrag

Status: Schema Version 2 und charging-Export implementiert

Stand: 26. Juli 2026

## 0. Implementierungsstand

Implementiert:

- `charging`-Schema Version 2 einschließlich Metadaten, Provenienz und
  konservativ normalisierter Öffnungszeiten,
- Stationen, EVSEs, Connectoren und Connector-Katalog,
- nicht-kanonische Betreiber-Quellbezeichnungen,
- Gruppen, Mitgliedschaften, Betreiber- und Leistungsaggregate für alle fünf
  Durchmesser,
- FTS5-Stationssuche und R*Tree-Koordinatenindex,
- atomarer, reproduzierbarer Export mit explizitem Buildzeitpunkt,
- Integritäts-, Fremdschlüssel-, Aggregat-, Index- und Provenienzprüfung,
- byteidentischer Doppelbuild mit der synthetischen Fixture.

Noch nicht implementiert sind das Manifest, die getrennten `park_info`- und
`osm_amenities`-Artefakte, Betreiberlinks sowie Stationsaliase. Die dafür im
Ladebestand vorgesehenen leeren Tabellen sind bereits vorhanden.

Ein read-only Abfrage-Prototyp ist ebenfalls implementiert. Er deckt
Gruppendurchmesser, Ladepunktzahl, Leistungsstufe und Anzahl geeigneter
Ladepunkte, Betreiber-Quellnamen, Connectoren, Volltextsuche,
Kartenausschnitt, Umkreis und Gruppendetails ab. Infrastruktur und Favoriten
bleiben wegen der vorgesehenen Datentrennung außerhalb dieses Prototyps.

## 1. Zweck und Trennung

SQLite ist das versionierte Austauschformat und der lokale Nur-Lese-Bestand der
App. Ein Release kann enthalten:

```text
charging-de-<dataset_version>.sqlite3
park-info-<dataset_version>.sqlite3
park-info-media/
osm-amenities-de-<dataset_version>.sqlite3
manifest.json
quality-report.json
```

Gemäß ADR-0003 bleiben die Artefakte getrennt:

- `charging` enthält BNetzA-basierte Stationen, EVSEs, Connectoren, Betreiber
  und vorberechnete Abstandsgruppen.
- `osm_amenities` enthält OSM-Infrastruktur unter ODbL.
- `park_info` enthält eigene redaktionelle Vor-Ort-Erhebungen und Metadaten zu
  separat gespeicherten, optimierten eigenen Bildern gemäß ADR-0012.
- Die App verbindet die Bestände nur zur Laufzeit.
- OSM-Daten beeinflussen keine Gruppenmitgliedschaft der Version 1.0.
- Redaktionelle Angaben werden über stabile Stationsreferenzen auf die aktuell
  gewählte Abstandsgruppe aufgelöst und beeinflussen deren Identität nicht.

Favoriten und Einstellungen liegen getrennt vom ausgelieferten Ladebestand in
lokalen, unabhängig versionierten SQLite-Dateien im Application-Support-
Verzeichnis. M10 verwendet für Einstellungen Schema v1 mit einer kleinen
Schlüssel-Wert-Tabelle; unbekannte Werte fallen auf sichere Standards zurück.

## 2. Versionen

- `manifest_format_version`: Struktur des Manifests,
- `schema_version`: logisches SQLite-Schema,
- `dataset_version`: `YYYY.MM.REVISION`,
- `pipeline_version`: Importer- und Regelversion,
- `source_version`: Stand der Quelle.

`PRAGMA user_version` entspricht `schema_version`. Versionen werden numerisch,
nicht lexikografisch verglichen.

## 3. Allgemeine Datenbankregeln

- SQLite 3 und UTF-8,
- WGS84-Koordinaten,
- Zeitpunkte als RFC 3339 UTC, Datumswerte als ISO `YYYY-MM-DD`,
- Boolesche Werte als `0` oder `1`,
- Fremdschlüssel beim Build aktiviert,
- `VACUUM` und `ANALYZE` vor Hashbildung,
- App öffnet alle Austauschdatenbanken read-only,
- keine Benutzer-, Geräte-, Favoriten- oder Telemetriedaten,
- keine geheimen Schlüssel oder Build-internen Bearbeiternotizen.

## 4. Schema `charging`

### 4.1 `metadata`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `key` | TEXT | Primärschlüssel |
| `value` | TEXT | nicht NULL |

Pflichtschlüssel:

- `dataset_id`,
- `dataset_version`,
- `schema_version`,
- `created_at`,
- `pipeline_version`,
- `region`,
- `license_summary`.

### 4.2 `station`

Repräsentiert eine BNetzA-Ladeeinrichtung.

| Spalte | Typ | Regel |
| --- | --- | --- |
| `station_id` | TEXT | UUID, Primärschlüssel |
| `operator_id` | TEXT | FK auf `operator`, NULL bei ungeklärtem Betreiber |
| `source_status` | TEXT | normalisierter Quellstatus |
| `station_type` | TEXT | NULL zulässig |
| `name` | TEXT | NULL zulässig |
| `latitude` | REAL | nicht NULL |
| `longitude` | REAL | nicht NULL |
| `street` | TEXT | NULL zulässig |
| `house_number` | TEXT | NULL zulässig |
| `postal_code` | TEXT | NULL zulässig |
| `city` | TEXT | NULL zulässig |
| `state` | TEXT | NULL zulässig |
| `opening_hours_raw` | TEXT | NULL zulässig |
| `opening_hours_weekdays_raw` | TEXT | NULL zulässig |
| `opening_hours_times_raw` | TEXT | NULL zulässig |
| `opening_hours_status` | TEXT | `always_open`, `restricted`, `unknown` |
| `commissioned_on` | TEXT | ISO-Datum oder NULL |
| `data_updated_at` | TEXT | NULL zulässig |

### 4.3 `evse`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `evse_id` | TEXT | UUID, Primärschlüssel |
| `station_id` | TEXT | FK auf `station`, nicht NULL |
| `external_evse_id` | TEXT | NULL zulässig |
| `current_type` | TEXT | `ac`, `dc`, `mixed`, `unknown` |
| `max_power_kw` | REAL | NULL oder mindestens 0 |
| `access_status` | TEXT | `public`, `restricted`, `unknown` |

### 4.4 `connector`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `connector_id` | TEXT | UUID, Primärschlüssel |
| `evse_id` | TEXT | FK auf `evse`, nicht NULL |
| `connector_type` | TEXT | kanonischer Code |
| `max_power_kw` | REAL | NULL oder mindestens 0 |

### 4.5 `connector_type`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `connector_type` | TEXT | Primärschlüssel |
| `display_key` | TEXT | Lokalisierungsschlüssel |
| `current_type` | TEXT | `ac`, `dc`, `mixed`, `unknown` |

### 4.6 `operator`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `operator_id` | TEXT | UUID, Primärschlüssel |
| `canonical_name` | TEXT | nicht NULL |
| `display_name` | TEXT | geprüfter kurzer Anzeigename, nicht NULL |
| `website` | TEXT | NULL; nur kuratierter zulässiger Betreiberlink |
| `website_verified_at` | TEXT | NULL zulässig |
| `website_evidence` | TEXT | `operator_confirmation`, `manual_link_check` |

Ein Webseitenlink enthält keine von der Webseite kopierten Koordinaten,
Beschreibungen oder Bilder. Eine Betreiberbestätigung wird separat
nachgewiesen.

### 4.6.1 `operator_source`

BNetzA-Bezeichnungen bleiben unabhängig vom geprüften Betreiberregister in
einer getrennten Source-Label-Tabelle erhalten:

- deterministische technische `operator_source_id`,
- exakter normalisierter BNetzA-Quellname,
- optionale Referenz auf einen kanonischen Betreiber.

Geprüfte exakte Aliase befüllen zusätzlich `station.operator_id` und
`group_operator`. Ungeprüfte Namen bleiben über `group_operator_source`
filterbar; abweichende Schreibweisen werden nicht automatisch vereinigt.

### 4.6.2 `operator_filter_option`

Materialisierte, direkt aus Stationen und EVSEs gezählte Rangstatistik für
kanonische Betreiber. Sie enthält `operator_id`, Stations-, EVSE-, DC- und
HPC-Zahl. Die App sortiert nach `evse_count` und liest standardmäßig höchstens
20 Einträge; dadurch werden die fünf Gruppendurchmesser nicht mehrfach gezählt.

### 4.7 `proximity_group`

Vorberechnete Gruppe für eine bestimmte Durchmessereinstellung.

| Spalte | Typ | Regel |
| --- | --- | --- |
| `group_id` | TEXT | kontextbezogene UUID, Primärschlüssel |
| `group_rowid` | INTEGER | deterministischer technischer Schlüssel für R*Tree |
| `diameter_m` | INTEGER | `25`, `50`, `100`, `200` oder `300` |
| `anchor_station_id` | TEXT | FK auf `station` |
| `medoid_station_id` | TEXT | FK auf `station` |
| `station_count` | INTEGER | mindestens 1 |
| `evse_count` | INTEGER | mindestens 1 |
| `ac_evse_count` | INTEGER | mindestens 0 |
| `dc_evse_count` | INTEGER | mindestens 0 |
| `max_power_kw` | REAL | NULL oder mindestens 0 |

Die Gruppen-ID ist nur innerhalb von Datensatzversion und Durchmesser
reproduzierbar. Sie ist keine langfristige Park-ID.

### 4.8 `proximity_group_member`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `group_id` | TEXT | FK auf `proximity_group` |
| `station_id` | TEXT | FK auf `station` |

Primärschlüssel: `(group_id, station_id)`.

Für jeden der fünf Durchmesser gehört jede aktive Station genau einer Gruppe
an. Der maximale paarweise Abstand aller Gruppenmitglieder darf den
Gruppendurchmesser nicht überschreiten.

### 4.9 `group_operator`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `group_id` | TEXT | FK |
| `operator_id` | TEXT | FK |
| `evse_count` | INTEGER | mindestens 0 |

Primärschlüssel: `(group_id, operator_id)`.

### 4.10 `group_power_band`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `group_id` | TEXT | FK |
| `minimum_power_kw` | INTEGER | Teil des Primärschlüssels |
| `evse_count` | INTEGER | mindestens 0 |

Vorgesehene Leistungsstufen: `0`, `50`, `100`, `150`, `200`, `250`, `300`,
`350`.

Die Implementierung speichert die Tabelle sparse: Nur positive Zählwerte
werden geschrieben; eine fehlende Zeile bedeutet `0`. Der Primärschlüssel
beginnt mit `minimum_power_kw`, sodass kein inhaltsgleicher zusätzlicher
Filterindex notwendig ist.

### 4.10a `group_always_open_power_band`

Besitzt denselben Schlüssel- und Leistungsgrenzenvertrag wie
`group_power_band`, zählt jedoch ausschließlich EVSEs aus Stationen mit
`opening_hours_status = 'always_open'`. Der 24/7-Filter verwendet diese Tabelle
anstelle des allgemeinen Leistungsbands, sodass Mindestzahl, Mindestleistung
und durchgehende Zugänglichkeit gekoppelt bleiben.

### 4.11 `group_connector`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `group_id` | TEXT | FK auf `proximity_group` |
| `connector_type` | TEXT | FK auf `connector_type` |
| `evse_count` | INTEGER | mindestens 1 |

Primärschlüssel: `(connector_type, group_id)`.

Die sparse Tabelle enthält nur Kombinationen, die in der Gruppe tatsächlich
vorkommen. `evse_count` zählt unterschiedliche EVSEs, die mindestens einen
Connector des Typs anbieten. Ein EVSE mit mehreren gleichartigen Anschlüssen
wird daher nur einmal gezählt.

### 4.12 `station_id_alias`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `old_station_id` | TEXT | Primärschlüssel |
| `current_station_id` | TEXT | FK auf `station` |
| `reason` | TEXT | definierter Code |

Aliase sind azyklisch und auf die aktuelle ID abgeflacht.

### 4.13 `operator_link`

Kuratierte Links zu offiziellen Betreiber- oder Standortseiten.

| Spalte | Typ | Regel |
| --- | --- | --- |
| `operator_link_id` | TEXT | Primärschlüssel |
| `operator_id` | TEXT | FK, nicht NULL |
| `station_id` | TEXT | FK oder NULL |
| `url` | TEXT | HTTPS, nicht NULL |
| `link_type` | TEXT | `operator_home`, `official_location_page` |
| `checked_at` | TEXT | nicht NULL |
| `title` | TEXT | eigener neutraler Titel, kein kopierter Seitentext |
| `matching_method` | TEXT | definierter manueller Abgleich oder Bestätigung |
| `matching_status` | TEXT | `verified`, `needs_confirmation`, `rejected` |
| `permission_reference` | TEXT | NULL oder Betreiberbestätigung |

Eine standortspezifische Verknüpfung wird nur über BNetzA-Identität,
Betreiberbestätigung oder eigene zulässige Feststellung hergestellt. Aus der
Webseite abgelesene Koordinaten werden nicht gespeichert.

`manual_exact_address_match` und `manual_name_and_address_match` dürfen
`verified` ergeben, wenn die frei zugängliche offizielle Seite eindeutig zur
BNetzA-Station gehört. Die Adresse der Webseite wird nicht gespeichert.
Abweichende und mehrdeutige Fälle bleiben `needs_confirmation` und werden nicht
an die App ausgeliefert.

### 4.13 `source` und `source_reference`

Speichern BNetzA-Herkunft, externe IDs, URL, Snapshot, Lizenz und Attribution.
Polymorphe Querverweise werden beim Build validiert.

## 5. Schema `park_info`

Status: Schema v1 implementiert für `FR-DATA-004`.

Der getrennte redaktionelle Bestand besitzt `PRAGMA user_version = 1` und die
Pflichtmetadaten `dataset_version`, `created_at`, `schema_version` und
`source_type=own_on_site_research`.

- `park_info(park_info_id, title, observed_on, reviewed_at, notes_de,
  notes_en)` enthält nur freigegebene Vor-Ort-Erhebungen.
- `park_info_station(park_info_id, station_id)` bindet jeden Eintrag an eine
  oder mehrere stabile Stations-IDs des Ladebestands. Der Build weist
  unbekannte Referenzen zurück.
- `amenity(park_info_id, amenity_type, state)` enthält für jeden Eintrag genau
  Restaurant, Shop, Kaffeeautomat, Snackautomat und Toilette mit dem Zustand
  `present`, `absent` oder `unknown`.
- `photo(photo_id, park_info_id, asset_path, author, captured_on, file_sha256,
  alt_de, alt_en, rights_reviewed_at, privacy_reviewed_at)` speichert nur
  Metadaten und den relativen Flutter-Assetpfad. Bildbytes bleiben außerhalb
  von SQLite.

Die Pflegequelle ist JSON unter `editorial/park_info/`; der reproduzierbare
Build und die App verwenden keine Redaktionsnotizen oder Originalfotos. Bei
mehreren passenden Stationsreferenzen wird derselbe redaktionelle Eintrag nur
einmal angezeigt. Ohne passenden Eintrag zeigt die App keinen
Infrastrukturblock und deutet fehlende Abdeckung nicht als „nicht vorhanden“.

Für `FR-FILTER-002` ermittelt die App im redaktionellen Bestand ausschließlich
Stationsanker, bei denen alle ausgewählten Merkmale explizit den Zustand
`present` besitzen. `absent`, `unknown` und fehlende Einträge erfüllen den
Filter nicht. Die Anker werden anschließend im Ladebestand zur dynamischen
Abstandsgruppe des gewählten Durchmessers aufgelöst; die beiden
SQLite-Artefakte bleiben physisch getrennt. Ohne aktiven Infrastrukturfilter
findet keine solche Vorabfrage statt.

## 6. Schema `osm_amenities`

### 6.1 `metadata`

Enthält zwingend OSM-Snapshot, ODbL-1.0, Attribution und URL des öffentlichen
ODbL-Angebots.

### 6.2 `osm_amenity`

| Spalte | Typ | Regel |
| --- | --- | --- |
| `osm_amenity_id` | TEXT | stabile OSM-basierte ID |
| `osm_type` | TEXT | `node`, `way`, `relation` |
| `osm_id` | INTEGER | nicht NULL |
| `osm_version` | INTEGER | NULL oder positiv |
| `amenity_type` | TEXT | App-Code |
| `name` | TEXT | NULL zulässig |
| `latitude` | REAL | nicht NULL |
| `longitude` | REAL | nicht NULL |
| `source_snapshot_at` | TEXT | nicht NULL |

Pflichttypen:

- `toilet`,
- `vending_machine`,
- `shopping`,
- `cafe`,
- `restaurant`.

Es wird keine persistente Zuordnung zu `proximity_group` gespeichert. Die App
führt eine räumliche Suche zur aktuell gewählten Gruppe aus.

## 7. Suche und Geoindizes

### 7.1 Stationssuche

FTS5-Tabelle `station_search` indexiert:

- Stationsname,
- Stadt,
- Postleitzahl,
- Straße,
- Betreibername.

Treffer werden anschließend zur Gruppe des aktuell gewählten Durchmessers
aufgelöst.

### 7.2 Räumliche Indizes

- `station_geo` als R*Tree über Stationskoordinaten,
- `proximity_group_geo` als R*Tree über die Kartenkoordinaten aller
  Abstandsgruppen und Verknüpfung über `group_rowid`,
- `osm_amenity_geo` als R*Tree über Infrastrukturkoordinaten.

Exakte Radiusfilter berechnen nach der Bounding-Box-Vorauswahl die tatsächliche
geodätische Distanz. Regionale Kartenausschnitte und Umkreise verwenden den
Gruppen-R*Tree. Bei sehr großen Ausschnitten mit einem Trefferanteil nahe
100 % ist ein sequenzieller Filter über den Durchmesserindex schneller; der
Prototyp schaltet deshalb ab einer orientierenden Ausschnittsfläche von
25 Quadratgrad auf diesen Pfad um. Der Schwellenwert wird später auf dem
iPhone-Referenzgerät kalibriert.

Falls FTS5 oder R*Tree auf unterstützten iOS-Versionen nicht zuverlässig
verfügbar sind, wird vor Implementierung eine Alternative als ADR festgelegt.

## 8. Pflichtindizes

Mindestens:

- `evse(station_id, max_power_kw)`,
- `connector(evse_id, connector_type)`,
- `proximity_group(diameter_m, group_id)`,
- `proximity_group_member(station_id, group_id)`,
- `group_operator(operator_id, group_id)`,
- `group_power_band(minimum_power_kw, evse_count, group_id)`,
- `group_connector(connector_type, group_id)`,
- `operator_link(operator_id, station_id)`,
- FTS5- und R*Tree-Indizes.

## 9. Filtersemantik

Die App wählt zunächst alle `proximity_group`-Zeilen für den eingestellten
Durchmesser. Darauf werden Filter angewendet:

- Mindestzahl Ladepunkte: `evse_count >= Wert`,
- Mindestleistung und Mindestzahl: `group_power_band`,
- bei geforderter durchgehender Zugänglichkeit stattdessen:
  `group_always_open_power_band`,
- Betreiber: `group_operator`,
- Connector: `group_connector`,
- nur Favoriten: Gruppe enthält die gespeicherte Anker-Station,
- Infrastruktur: räumlicher OSM- oder eigener zulässiger Nachweis.

Mehrfachwerte innerhalb einer Filtergruppe werden mit ODER, verschiedene
Filtergruppen mit UND verbunden. Unbekannte Infrastruktur erfüllt einen
„vorhanden“-Filter nicht.

### 9.1 Abfrage-Prototyp und erster Performancetest

Der CLI-Befehl `query-sqlite` bildet diese Semantik mit parametrisierten
SQL-Abfragen ab und öffnet die Datenbank im SQLite-Modus `mode=ro`.
`group-detail` liefert Betreiber, Leistungsstufen, Connectoren und
Mitgliedsstationen einer ausgewählten Gruppe.

Messung am 26. Juli 2026 auf dem Entwicklungs-Mac mit dem vollständigen
BNetzA-Datensatz und 50 Metern Gruppendurchmesser:

| Abfrage | gemessene Laufzeit |
| --- | ---: |
| mindestens vier EVSEs ab 100 kW | 440 ms |
| Text „Berlin“ plus Kartenausschnitt | 495 ms |
| 25-km-Umkreis um München | 158 ms |
| Betreiber Tesla, mindestens acht EVSEs ab 100 kW | 196 ms |
| CCS, mindestens acht EVSEs ab 200 kW, vor Aggregat | 567 ms |
| gleiche CCS-Abfrage mit `group_connector` | 34 ms |
| Berlin-Ausschnitt über `proximity_group_geo` | 154–207 ms |
| Text „Berlin“ plus Ausschnitt mit Gruppen-R*Tree | 178 ms |
| 25-km-Umkreis mit Gruppen-R*Tree | 53 ms |
| Deutschlandansicht mit hybridem Direktpfad | 443 ms |

Dies sind orientierende Einzelmessungen des Python-Prototyps, kein
repräsentativer iPhone-Benchmark. Alle geprüften Kernfälle erfüllen mit dem
vorberechneten `group_connector`-Aggregat das 500-ms-Ziel aus
`NFR-PERF-001`. Das Aggregat benötigt 324.079 sparse Zeilen und vergrößert das
vollständige SQLite-Artefakt um rund 16 MB.

`proximity_group_geo` enthält genau 266.971 Einträge. Gegenüber dem Stand mit
`group_connector`, aber ohne Gruppen-R*Tree erhöht es die Dateigröße um rund
26 MB. Die erste erzwungene R*Tree-Messung der fast vollständigen
Deutschlandansicht benötigte 979 ms; der hybride Direktpfad reduziert sie auf
443 ms.

Die zunächst korrelierte Volltextabfrage benötigte 13,2 Sekunden; die einmalige
Bildung der FTS-Treffermenge reduzierte sie auf 495 ms. Dieser Fall bleibt
fachlich durch automatisierte Tests abgedeckt; feste Zeitgrenzen gehören in
spätere Performance-Tests auf einem definierten Referenzgerät.

## 10. Favoritenspeicher der App

Ein Favorit liegt nicht in der Austauschdatenbank. Er enthält mindestens:

```text
anchor_station_id
saved_diameter_m
saved_at
optional display_snapshot
```

Beim Öffnen:

1. Stationsalias auflösen,
2. Gruppe für den aktuell gewählten Durchmesser finden,
3. Gruppe anzeigen,
4. fehlt die Station, Favorit als nicht verfügbar erhalten.

## 11. Integritätsprüfungen

Vor Veröffentlichung:

```sql
PRAGMA integrity_check;
PRAGMA foreign_key_check;
```

Zusätzlich:

- UUIDs syntaktisch gültig,
- jede Station je Durchmesser genau einer Gruppe zugeordnet,
- Gruppenanker und Medoid sind Gruppenmitglieder,
- maximaler paarweiser Abstand liegt innerhalb des Grenzwerts,
- EVSE-, AC/DC- und Leistungsaggregate stimmen,
- Stationsaliase sind azyklisch,
- FTS- und Geoindizes vollständig,
- Links verwenden HTTPS und enthalten keine übernommenen Webseitenkoordinaten,
- Metadaten stimmen mit Manifest überein.

## 12. Manifest

Pflichtfelder:

- `manifest_format_version`,
- `dataset_id`,
- `dataset_version`,
- `schema_version`,
- `created_at`,
- Region und App-Kompatibilität,
- Pipelineversion und Git-Commit,
- Quellen mit Snapshot, Lizenz und Attribution,
- Artefakte mit Typ, URL, Lizenz, Größe und SHA-256,
- für OSM `public_offer_url`,
- Objektstatistiken,
- Lizenz- und Qualitätsbericht-URLs.

Beispiel:

```json
{
  "manifest_format_version": 1,
  "dataset_id": "ladepark-explorer-de",
  "dataset_version": "2026.07.0",
  "schema_version": 1,
  "created_at": "2026-07-26T12:00:00Z",
  "compatibility": {
    "minimum_app_version": "1.0.0",
    "readable_schema_versions": [1]
  },
  "artifacts": [
    {
      "type": "charging_sqlite",
      "license": "CC-BY-4.0",
      "url": "datasets/charging-de-2026.07.0.sqlite3",
      "size_bytes": 12345678,
      "sha256": "64-lowercase-hex-characters"
    },
    {
      "type": "osm_amenities_sqlite",
      "license": "ODbL-1.0",
      "public_offer_url": "open-data/osm-amenities-de-2026.07.0/",
      "url": "datasets/osm-amenities-de-2026.07.0.sqlite3",
      "size_bytes": 2345678,
      "sha256": "64-lowercase-hex-characters"
    }
  ]
}
```

## 13. Updatealgorithmus

1. Manifest per HTTPS laden und validieren.
2. Kompatibilität und numerisch neuere Version prüfen.
3. Downloadgröße und Datenstand anzeigen.
4. Alle benötigten Artefakte temporär laden.
5. Größe und SHA-256 jedes Artefakts prüfen.
6. SQLite-Integrität, Schema, Metadaten und Querverweise prüfen.
7. Stationsaliase für Favoriten vorbereiten.
8. Artefaktsatz atomar aktivieren.
9. Alte Dateien erst nach erfolgreichem Öffnen wiederherstellbar entfernen.

Bei jedem Fehler bleibt der bisher aktive Artefaktsatz unverändert.

Ein Hash im selben unsignierten Manifest schützt vor Übertragungsfehlern, nicht
vollständig vor einer kompromittierten Distribution. Eine Manifest-Signatur
wird vor Produktionsbetrieb entschieden.

## 14. Akzeptanztests

- alle Gruppierungsfälle aus `06_Clustering.md`,
- exakte Filtergrenzen,
- Stationssuche und Gruppenauflösung,
- räumliche Infrastrukturzuordnung bei jedem Durchmesser,
- Favorit nach Durchmesserwechsel und Datensatzupdate,
- Stationsalias und entfernte Station,
- offizieller Betreiberlink ohne kopierte Koordinaten,
- beschädigte Datei, falscher Hash und abgebrochener Download,
- nicht unterstützte Schema- und Manifestversion,
- Quellen-, Lizenz- und Attributionsvollständigkeit,
- Performanceanforderungen aus `02_Requirements.md`.

## 15. Noch vor Produktionsfreigabe zu entscheiden

- konkrete SQLite-Mindestversion und Flutter-Bibliothek,
- FTS5-/R*Tree-Verfügbarkeit,
- räumlicher Radius für Infrastrukturmerkmale,
- finaler Connector-Codekatalog,
- Manifest-Signatur,
- Kompression und Downloadgröße,
- Rollback und Aufbewahrung alter Datensätze.

## 16. Erster vollständiger charging-Build

Der Build aus der BNetzA-CSV vom 7. Juli 2026 mit Datensatzversion `2026.07.0`
enthält:

- 113.385 Stationen,
- 204.078 EVSEs,
- 214.785 Connectoren,
- 266.971 vorberechnete Gruppen,
- 566.925 Gruppenmitgliedschaften für fünf Durchmesser,
- 324.079 Connector-Gruppenaggregate.

Das validierte Schema-v2-Artefakt
`charging-de-2026.07.0.sqlite3` ist rund 421 MB groß und besitzt SHA-256
`8d3c80b5ef4bc4e74d7033e387461b65d184252a271293a8724414769df5c7d4`.
Es enthält 36.908 eindeutig als durchgehend zugänglich normalisierte
Stationen und 195.259 sparse 24/7-Gruppenleistungszeilen.
Die Größe ist für den Prototyp akzeptiert, muss vor einem öffentlichen Release
jedoch weiter bewertet werden. Mögliche Optimierungen sind interne
Integer-Fremdschlüssel und die endgültige Wahl von Kompression und
Auslieferungsformat; stabile fachliche UUIDs bleiben dabei erhalten.
