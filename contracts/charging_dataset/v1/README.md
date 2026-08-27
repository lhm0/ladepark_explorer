# Charging Dataset Contract – Schema Version 1

Dieser Vertrag verbindet den Python-Importer mit der Flutter-App. Die kleine
SQLite-Fixture wird deterministisch aus
`importer/tests/fixtures/bnetza_minimal.csv` erzeugt.

## Artefakte

- `fixture.sqlite3` – read-only Referenzdatenbank,
- `expectations.json` – stabile Abfrageparameter und erwartete Gruppen-IDs.

Laufzeitmessungen und absolute Dateipfade gehören nicht zum Vertrag.

## Reproduzieren

Aus `importer/`:

```text
uv run ladepark-importer build-sqlite tests/fixtures/bnetza_minimal.csv \
  --output ../contracts/charging_dataset/v1/fixture.sqlite3 \
  --dataset-version 2026.07.0-contract \
  --source-version 2026-07-07-contract \
  --created-at 2026-07-26T00:00:00Z \
  --operators tests/fixtures/operators_contract.json \
  --pipeline-version 0.1.0 --replace
```

Ein Wiederholungsbuild muss byteidentisch sein. Schemaänderungen innerhalb von
Version 1 dürfen nur kompatibel sein. Inkompatible Änderungen erhalten ein
neues Verzeichnis und eine neue `schema_version`.
