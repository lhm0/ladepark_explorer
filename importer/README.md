# Ladepark Explorer Importer

Lokales Python-Werkzeug zur Prüfung und Aufbereitung der
Bundesnetzagentur-Ladesäulenliste.

## Modulstruktur

```text
src/ladepark_importer/
├── charging_sqlite/   Schema, Modelle, Writer, Validator und Referenzabfragen
├── commands/          Ausführung der CLI-Unterbefehle
├── pipeline/          vollständige Build-Orchestrierung
├── park_info/         redaktionelles Schema, Build und Validierung
└── *.py               Quellenadapter und fachliche Verarbeitung
```

## Redaktionellen Informationsbestand bauen

Die verständliche Pflegeanleitung und ein vollständiger Beispieleintrag stehen
unter `../editorial/park_info/`. Der normale Aufruf erfolgt aus dem
Repository-Stamm mit `./tooling/prepare_park_info_dataset.sh`. Direkt lässt sich
der Contract so prüfen:

```text
uv run ladepark-importer build-park-info \
  tests/fixtures/park_info_minimal.json \
  --media tests/fixtures \
  --charging-database ../app/assets/datasets/charging-2026.07.0-contract.sqlite3 \
  --output ../data/output/test-park-info.sqlite3 \
  --media-output ../data/output/test-park-info-media --replace
uv run ladepark-importer validate-park-info ../data/output/test-park-info.sqlite3
```

Die bisherigen Module `sqlite_export` und `sqlite_query` bleiben vorerst als
Kompatibilitätsfassaden erhalten. Der sprachübergreifende Schema-v2-Vertrag
liegt unter `../contracts/charging_dataset/v2/`.

## Einrichtung

```bash
cd importer
uv sync
```

## Prüfen

```bash
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run mypy src
```

## Quelle untersuchen

```bash
uv run ladepark-importer inspect tests/fixtures/bnetza_minimal.csv
```

Der Befehl prüft Dateiformat, Spaltenvertrag und Kernwerte und gibt einen
JSON-Bericht aus. Er verändert die Quelldatei nicht.

Die offiziellen BNetzA-Dateien enthalten Informationszeilen vor der
eigentlichen Kopfzeile. Der Adapter sucht die Kopfzeile deshalb in den ersten
50 CSV- beziehungsweise XLSX-Zeilen. Gequotete Felder dürfen Zeilenumbrüche
enthalten.

## Quelle normalisieren

```bash
uv run ladepark-importer normalize tests/fixtures/bnetza_minimal.csv
```

Der Befehl erzeugt eine deterministisch sortierte JSON-Darstellung typisierter
Stationen, EVSEs und Connectoren. Die dabei verwendeten UUID-Namespaces und
Connector-Zuordnungen liegen versioniert unter `config/`.

Unbekannte Steckertypen bleiben mit ihrem Quellwert erhalten und erzeugen eine
Warnung. Betreiber werden ohne Eintrag in einem zukünftigen Betreiberregister
nicht automatisch zusammengeführt; bis dahin bleiben sie als Quellname
erhalten und werden im Qualitätsbericht gezählt.

## Qualitätsbericht erzeugen

Für große Quelldateien ist der kompakte Bericht zweckmäßiger als die komplette
JSON-Ausgabe:

```bash
uv run ladepark-importer report ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv
```

Optional kann er lokal gespeichert werden:

```bash
mkdir -p ../data/output
uv run ladepark-importer report ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv \
  > ../data/output/normalization-report.json
```

Der Bericht zählt Stationen, EVSEs, AC/DC-Verteilung, Connector-Typen,
EVSE-ID-Probleme, fehlende Hausnummern und uneindeutige Leistungszuordnungen.
`data/output/` wird nicht in Git aufgenommen.

## Abstandsgruppen auswerten

Für einen der fünf unterstützten maximalen Gruppendurchmesser:

```bash
uv run ladepark-importer cluster-report \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv \
  --dataset-version 2026-07-07 \
  --diameter 50
```

Der Bericht enthält Gruppenzahl, Größenverteilung, tatsächlichen größten
Durchmesser, größte Gruppen nach Stations- und EVSE-Zahl sowie einen SHA-256
über alle Mitgliedschaften. Die `dataset-version` ist verpflichtend, weil sie
in die reproduzierbaren, aber datensatzabhängigen Gruppen-IDs eingeht.

## Gruppen manuell prüfen

Der Review-Export vereinigt die Top-N-Gruppen nach HPC-, EVSE- und
Stationszahl:

```bash
uv run ladepark-importer cluster-review \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv \
  --dataset-version 2026-07-07 \
  --diameter 50 \
  --limit-per-category 100 \
  --output ../data/output/cluster-review-50m.csv
```

HPC bedeutet in diesem Bericht DC mit mindestens 100 kW. Die CSV enthält unter
anderem Auswahlgrund und Ränge, Ankeradresse, Anker- und Medoidkoordinate,
Stations-, EVSE-, AC-, DC- und HPC-Zahlen, maximale Leistung, Betreiber,
Connector-Typen, identische Koordinaten und BNetzA-Quell-IDs.

## Betreiberbezeichnungen prüfen

Der Betreiber-Review zählt Stationen und Ladepunkte direkt aus der
normalisierten BNetzA-Quelle und sortiert alle Quellbezeichnungen nach
Ladepunktzahl:

```bash
uv run ladepark-importer operator-review \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv \
  --candidate-limit 5 \
  --output ../data/output/operator-review-2026-07-07.csv
```

Der Export enthält AC-, DC- und HPC-Zahlen, maximale Leistung, Bundesländer,
Beispielorte sowie technische Normalisierungs- und Vergleichsschlüssel.
Ähnliche Namen sind ausschließlich Review-Hinweise. Der Befehl führt keine
Betreiber automatisch zusammen; `canonical_operator` bleibt bis zur manuellen
Übernahme in das versionierte Betreiberregister leer.

Für die eigentliche Prüfung erzeugt eine kleinere Arbeitsliste die größten
Quellnamen und nimmt deren Ähnlichkeitskandidaten zusätzlich auf:

```bash
uv run ladepark-importer operator-worklist \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv \
  --top 20 --candidate-limit 5 \
  --output ../data/output/operator-worklist-top20-2026-07-07.csv
```

Entscheidungen werden nicht in den generierten Export zurückgeschrieben,
sondern ausschließlich im versionierten Register `config/operators.json`
festgehalten. Jeder Eintrag benötigt einen dauerhaft stabilen `registry_key`,
kanonischen Namen, Anzeigenamen, exakte BNetzA-Aliase, Reviewdatum und
Begründung. Prüfung und Abdeckungsbericht:

```bash
uv run ladepark-importer operator-registry-validate \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv
uv run ladepark-importer operator-coverage \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv
```

Die Validierung weist unbekannte oder mehrfach zugeordnete Aliase, doppelte
Registerschlüssel, unvollständige Einträge und ungültige Reviewdaten zurück.
Die stabile Betreiber-ID ist UUIDv5 aus dem Operator-Namespace und dem
`registry_key`; Umfirmierungen verändern sie deshalb nicht.

`build-sqlite` übernimmt geprüfte Aliase in die kanonischen Betreiber- und
Gruppenbeziehungen. Zusätzlich wird eine direkt aus Stationen und EVSEs
gezählte Rangstatistik für die Top-20-Auswahl der App materialisiert. Nicht
zugeordnete BNetzA-Namen bleiben als exakte, durchsuchbare Quellnamen erhalten.

## SQLite-App-Datensatz erzeugen

Der vollständige Build normalisiert die Quelle, berechnet alle fünf
Gruppierungsvarianten, schreibt die Datenbank atomar und validiert sie:

```bash
uv run ladepark-importer build-sqlite \
  ../data/raw/Ladesaeulenregister_BNetzA_2026-07-07.csv \
  --output ../data/output/charging-de-2026.07.0.sqlite3 \
  --dataset-version 2026.07.0 \
  --source-version 2026-07-07 \
  --created-at 2026-07-26T00:00:00Z \
  --pipeline-version 0.1.0
```

Eine vorhandene Datei wird nur mit `--replace` ersetzt. Separate
Read-only-Prüfung:

```bash
uv run ladepark-importer validate-sqlite \
  ../data/output/charging-de-2026.07.0.sqlite3
```

`created-at` ist explizit, damit gleiche Eingaben und Metadaten byteidentische
Testbuilds ermöglichen.

## SQLite-Abfragen erproben

Der Abfrage-Prototyp öffnet die App-Datenbank ausschließlich read-only. Der
Standardfilter zeigt bei 50 Metern Gruppendurchmesser Gruppen mit mindestens
einem Ladepunkt ab 100 kW:

```bash
uv run ladepark-importer query-sqlite \
  ../data/output/charging-de-2026.07.0.sqlite3 \
  --limit 10
```

Eine strengere Suche im sichtbaren Kartenausschnitt:

```bash
uv run ladepark-importer query-sqlite \
  ../data/output/charging-de-2026.07.0.sqlite3 \
  --diameter 50 \
  --min-evse 8 \
  --min-power 200 \
  --min-power-evse 8 \
  --connector ccs \
  --bounds 47.2 5.8 55.1 15.1 \
  --limit 20
```

Weitere Optionen sind `--search`, wiederholbares `--operator` und
`--connector` sowie `--near LAT LON --radius-km KM`. Mehrere Betreiber oder
Connectoren werden jeweils mit ODER, verschiedene Filtergruppen mit UND
verknüpft. `--min-power-evse 0` deaktiviert den Leistungsfilter.

Die JSON-Ausgabe enthält die effektiven Filter, Treffer, ein
Abschneidekennzeichen und die SQL-Laufzeit. Details eines Treffers:

```bash
uv run ladepark-importer group-detail \
  ../data/output/charging-de-2026.07.0.sqlite3 GRUPPEN_ID
```

Die Detailausgabe umfasst Stationsliste, Betreiber-Quellnamen,
Leistungsstufen und Connectoren. Infrastruktur und Favoriten sind noch nicht
Teil des Prototyps, weil sie später in getrennten lokalen Beständen liegen.

Connectorfilter verwenden das beim Export vorberechnete sparse
`group_connector`-Aggregat. Es zählt je Gruppe die unterschiedlichen EVSEs, die
einen Connector-Typ anbieten.
