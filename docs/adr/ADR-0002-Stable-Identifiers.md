# ADR-0002 – Stabile interne Identitäten

Status: Angenommen

Datum: 26. Juli 2026

Ergänzt durch ADR-0004: Die hier beschriebene dauerhafte `park_id` gilt nicht
für dynamische Abstandsgruppen der Version 1.0, sondern erst für bestätigte
`verified_park`-Objekte ab Version 1.5. Favoriten der Version 1.0 verwenden
stabile Anker-Stationen.

## Kontext

Quelldaten können korrigiert, umsortiert, umbenannt, entfernt oder später
erneut veröffentlicht werden. Ladestandorte werden zudem aus mehreren
Ladeeinrichtungen und Betreibern gebildet. Favoriten und spätere
Community-Inhalte benötigen dennoch dauerhaft referenzierbare IDs.

Quell-IDs direkt als fachliche IDs zu verwenden wäre problematisch:

- mehrere Quellen besitzen unterschiedliche ID-Räume,
- EVSE-IDs sind nicht immer vorhanden,
- ein Ladestandort besitzt keine ID der Bundesnetzagentur,
- Cluster können sich teilen oder vereinigen.

## Entscheidung

### ID-Format

Alle internen IDs sind UUIDs in kanonischer Kleinschreibung.

- Deterministische Quellobjekt-IDs werden als UUIDv5 in projektspezifischen,
  dokumentierten Namespaces erzeugt.
- Neue Ladestandort-IDs werden ebenfalls deterministisch aus einer stabilen
  Ankeridentität erzeugt.
- Die verwendeten Namespace-UUIDs sind vor der ersten Implementierung einmalig
  zu erzeugen, im Repository zu versionieren und danach unveränderlich.

Die interne UUID ist nicht mit der sichtbaren Quell-ID identisch. Die Quell-ID
bleibt separat in `source_reference` erhalten.

### Ladeeinrichtung

Für eine Bundesnetzagentur-Ladeeinrichtung:

```text
station_id = UUIDv5(namespace_bnetza_station,
                    "bnetza:" + normalisierte_ladeeinrichtungs_id)
```

Ändern sich Adresse, Betreiber oder Koordinaten bei gleicher
Ladeeinrichtungs-ID, bleibt `station_id` erhalten.

### Ladepunkt / EVSE

Wenn eine syntaktisch gültige und innerhalb der Quelle eindeutige EVSE-ID
vorhanden ist:

```text
evse_id = UUIDv5(namespace_evse, "evse:" + kanonische_evse_id)
```

Ohne verwendbare EVSE-ID:

```text
evse_id = UUIDv5(namespace_bnetza_evse,
                 station_id + ":slot:" + quell_slot)
```

Der Fallback-Slot entspricht der Position des Ladepunkts in der beobachteten
Quellschnittstelle. Änderungen der Slotbelegung werden im Import als mögliche
Identitätsänderung gemeldet. Ein späterer Matching-Algorithmus darf eine
Identität nur anhand dokumentierter, konservativer Regeln fortführen.

### Connector

```text
connector_id = UUIDv5(namespace_connector,
                     evse_id + ":" + kanonischer_steckertyp)
```

Falls mehrere gleichartige Anschlüsse pro EVSE modelliert werden müssen, wird
ein quellstabiler ordinaler Zusatz verwendet.

### Betreiber

Betreiber erhalten interne IDs aus einem versionierten
Betreiber-Normalisierungsregister. Quellnamen werden als Aliase gepflegt.
Reine Textnormalisierung erzeugt keine automatische Zusammenführung rechtlich
oder organisatorisch verschiedener Unternehmen.

### Bestätigter Ladestandort ab Version 1.5

Der initiale `verified_park_id` ist UUIDv5 aus der kleinsten stabilen
`station_id` des bestätigten Parks, dem sogenannten Anker:

```text
verified_park_id =
  UUIDv5(namespace_verified_park, "anchor:" + anchor_station_id)
```

Zusätzlich führt ein versioniertes Identitätsregister:

- Zuordnung von Stationen zu `verified_park_id`,
- Ankerstation,
- frühere IDs und Aliasbeziehungen,
- Merge- und Splitereignisse,
- Begründung und Importlauf.

## Merge- und Splitregeln für `verified_park`

### Zusammenführung

Werden bestehende Parks zusammengeführt:

1. Eine manuelle Override-Regel hat Vorrang.
2. Andernfalls bleibt die ID des Parks mit der ältesten dokumentierten
   Entstehung erhalten.
3. Bei Gleichstand entscheidet die lexikografisch kleinste UUID.
4. Nicht fortgeführte IDs werden als Aliase auf die überlebende ID gespeichert.

Damit bleiben Favoriten auf frühere IDs auflösbar.

### Aufteilung

Wird ein Park geteilt:

1. Der Teil mit der bisherigen Ankerstation behält die bisherige
   `verified_park_id`.
2. Jeder weitere Teil erhält eine neue deterministische ID aus seiner kleinsten
   `station_id`.
3. Eine automatische Übertragung eines Favoriten auf mehrere Nachfolger findet
   nicht statt.
4. Der Split wird im Identitätsregister dokumentiert und als Qualitätsereignis
   gemeldet.

### Entfernung und Wiederkehr

Verschwindet ein Objekt aus einem Quellsnapshot, wird seine Identität nicht
sofort wiederverwendet oder gelöscht. Kehrt dieselbe belastbare Quellidentität
zurück, kann die bisherige ID reaktiviert werden. Aufbewahrungsdauer und
fachlicher Status werden in der Importer-Spezifikation festgelegt.

## Matchingregeln

- Exakte gültige Quell-ID hat Vorrang.
- Exakte EVSE-ID darf Betreiber- oder Adressänderungen überleben.
- Koordinaten, Adresse, Betreiber und Leistung allein reichen nicht für eine
  automatische Übernahme einer Identität, wenn eine Quell-ID gewechselt hat.
- Unsichere Fälle erzeugen einen Review-Fall, statt stillschweigend Historien
  zu verbinden.
- Eine manuelle Identitätsregel ist versioniert und reproduzierbar.

## Reproduzierbarkeit

Identitätsregister, Betreiberregister und manuelle Regeln sind versionierte
Eingaben der Pipeline. Gleiche Rohdaten, gleiche Registerstände und gleiche
Pipeline-Version ergeben dieselben IDs.

Der produktive Datensatz enthält nur die für die App erforderlichen IDs und
Aliasauflösungen. Vollständige Review- und Historieninformationen bleiben im
Build-Bereich.

## Folgen

Positiv:

- Favoriten überleben normale Datensatzupdates.
- Quell- und Fachidentität bleiben getrennt.
- betreiberübergreifende Parks sind möglich.
- Merge- und Splitfälle sind deterministisch und nachvollziehbar.

Negativ:

- Identitätsregister und Overrides müssen dauerhaft gepflegt werden.
- fehlende EVSE-IDs erzeugen schwächere Fallback-Identitäten.
- Clusterkorrekturen benötigen explizite Migrationsregeln.
- vollautomatische Importe müssen bei unsicheren Identitätsfällen gegebenenfalls
  gestoppt werden.

## Nicht entschieden

- konkrete Namespace-UUID-Werte,
- Dateiformat des Build-seitigen Identitätsregisters,
- Aufbewahrungsdauer verschwundener Objekte,
- Schwellenwerte für automatische Review-Warnungen.
