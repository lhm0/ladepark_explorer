# Arbeitsanweisungen für Codex

## Projekt

Der Ladepark Explorer ist eine offline-first iPhone-App zur Recherche
zusammenhängender Ladestandorte in Deutschland. Version 1.0 besitzt kein
dauerhaftes fachliches Backend und keine Community-Funktionen.

## Einstieg in einen neuen Chat

Vor Änderungen in dieser Reihenfolge lesen:

1. `PROJECT_STATUS.md`
2. `docs/README.md`
3. `docs/specification/01_ProjectVision.md`
4. die für die Aufgabe relevanten Spezifikationskapitel
5. relevante ADRs unter `docs/adr/`

Anschließend den tatsächlichen Repository-Zustand prüfen. Dokumentierte Pläne
dürfen nicht mit bereits implementiertem Verhalten verwechselt werden.

## Verbindliche Arbeitsregeln

- Produktanforderungen besitzen IDs in `docs/specification/02_Requirements.md`.
- Code und Tests müssen auf die betroffenen Requirement-IDs zurückführbar sein.
- Änderungen an Verhalten, Datenmodell oder Architektur aktualisieren im selben
  Commit die betroffenen Dokumente.
- Langfristig relevante Architekturentscheidungen erhalten ein ADR.
- Neue Aussagen als **Ist-Zustand**, **entschieden**, **geplant** oder **offen**
  einordnen.
- Keine Produktanforderungen in `AGENTS.md` oder `PROJECT_STATUS.md`
  duplizieren; stattdessen auf das SSD verweisen.
- Bestehende offene Entscheidungen nicht stillschweigend treffen. Technische
  Entscheidungen vor ihrer Implementierung dokumentieren.
- Keine Community-, Konto-, Live-Daten- oder Bezahlfunktionen in Version 1.0
  vorziehen.

## Definition of Done

Eine Arbeitseinheit ist abgeschlossen, wenn:

- die betroffenen Anforderungen benannt und erfüllt sind,
- relevante automatisierte Tests vorhanden und erfolgreich sind,
- Dokumentation und ADRs konsistent aktualisiert sind,
- Formatierung, statische Analyse und Tests erfolgreich laufen,
- `PROJECT_STATUS.md` den neuen verifizierten Stand wiedergibt.

## Prüfkommandos

Für Änderungen am Importer:

```text
cd importer
uv sync
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run mypy src
```

Ein schneller funktionaler Probelauf mit dem synthetischen Datensatz:

```text
cd importer
uv run ladepark-importer inspect tests/fixtures/bnetza_minimal.csv
uv run ladepark-importer normalize tests/fixtures/bnetza_minimal.csv
uv run ladepark-importer report tests/fixtures/bnetza_minimal.csv
uv run ladepark-importer cluster-report tests/fixtures/bnetza_minimal.csv \
  --dataset-version test-2026-07-07 --diameter 50
uv run ladepark-importer cluster-review tests/fixtures/bnetza_minimal.csv \
  --dataset-version test-2026-07-07 --diameter 50 \
  --limit-per-category 1 --output ../data/output/test-cluster-review.csv
uv run ladepark-importer operator-review tests/fixtures/bnetza_minimal.csv \
  --candidate-limit 2 --output ../data/output/test-operator-review.csv
uv run ladepark-importer operator-worklist tests/fixtures/bnetza_minimal.csv \
  --top 1 --candidate-limit 2 --output ../data/output/test-operator-worklist.csv
uv run ladepark-importer operator-registry-validate \
  tests/fixtures/bnetza_minimal.csv \
  --registry tests/fixtures/operators_empty.json
uv run ladepark-importer operator-coverage tests/fixtures/bnetza_minimal.csv \
  --registry tests/fixtures/operators_empty.json
uv run ladepark-importer build-sqlite tests/fixtures/bnetza_minimal.csv \
  --output ../data/output/test-charging.sqlite3 \
  --dataset-version 2026.07.0-test --source-version 2026-07-07-test \
  --created-at 2026-07-26T00:00:00Z --replace
uv run ladepark-importer validate-sqlite ../data/output/test-charging.sqlite3
uv run ladepark-importer query-sqlite ../data/output/test-charging.sqlite3 --limit 10
uv run ladepark-importer build-release ../data/output/test-charging.sqlite3 \
  --output ../data/output/test-release \
  --repository lhm0/ladepark_explorer --git-commit test
```

`uv sync` verändert keine globale Python-Installation. Es verwendet die in
`importer/.python-version` festgelegte Python-Version und legt die Umgebung
projektlokal unter `importer/.venv` an.

Für Änderungen an der Flutter-App:

```text
cd app
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
dart run ../tooling/check_flutter_architecture.dart
flutter build ios --simulator
```

Das App-Gerüst verwendet Flutter 3.44.8 Stable und Dart 3.12.2. Lokal sind
Xcode 16.2, die iOS-18.3-Simulatorruntime und CocoaPods 1.17.0 verifiziert.
Der interaktive Simulatorstart ist in `app/README.md` dokumentiert.
