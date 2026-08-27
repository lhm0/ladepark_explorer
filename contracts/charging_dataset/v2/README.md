# Charging Dataset Contract – Schema Version 2

Dieser Vertrag verbindet den Python-Importer mit der Flutter-App. Die kleine
SQLite-Fixture wird deterministisch aus
`importer/tests/fixtures/bnetza_minimal.csv` erzeugt.

Version 2 ergänzt konservativ normalisierte Öffnungszeiten und
`group_always_open_power_band` für den gekoppelten 24/7-Filter.

## Reproduzieren

Aus `importer/`:

```text
uv run ladepark-importer build-sqlite tests/fixtures/bnetza_minimal.csv \
  --output ../contracts/charging_dataset/v2/fixture.sqlite3 \
  --dataset-version 2026.07.0-contract \
  --source-version 2026-07-07-contract \
  --created-at 2026-07-26T00:00:00Z \
  --operators tests/fixtures/operators_contract.json \
  --pipeline-version 0.1.0 --replace
```

Ein Wiederholungsbuild muss byteidentisch sein. Inkompatible Änderungen
erhalten ein neues Verzeichnis und eine neue `schema_version`.
