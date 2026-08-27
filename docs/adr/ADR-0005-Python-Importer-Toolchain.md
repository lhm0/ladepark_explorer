# ADR-0005 – Python-Toolchain für den Importer

Status: Angenommen

Datum: 26. Juli 2026

## Kontext

Der Importer wird zunächst lokal auf macOS entwickelt und später unverändert in
CI ausführbar sein. Die Umgebung soll reproduzierbar, projektlokal und auch für
wenig erfahrene Mitwirkende mit wenigen Befehlen nutzbar sein.

## Entscheidung

- Python 3.12 ist die verbindliche Laufzeit für den ersten Importer.
- `uv` verwaltet Python-Umgebung, Abhängigkeiten und Lockdatei.
- `pytest` führt automatisierte Tests aus.
- `ruff` übernimmt Formatierung und Linting.
- `mypy` prüft statische Typen.
- `openpyxl` liest BNetzA-XLSX-Dateien.
- Python `sqlite3` erzeugt später die App-Datenbanken.
- `argparse` aus der Standardbibliothek bildet die CLI.
- Produktcode liegt als `src`-Layout unter `importer/`.
- Tests liegen unter `importer/tests/`.

Vorgesehene Standardbefehle:

```text
cd importer
uv sync
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run mypy src
uv run ladepark-importer --help
```

## Python-Version

Der Importer unterstützt zunächst `>=3.12,<3.13`. Eine Erweiterung auf neuere
Versionen erfolgt erst nach erfolgreichen Tests. Dadurch bleiben lokale und
CI-Ausführung eindeutig.

## Abhängigkeitspolitik

- Laufzeitabhängigkeiten werden sparsam gehalten.
- Standardbibliothek wird bevorzugt, wenn sie die Aufgabe robust erfüllt.
- Direkte Abhängigkeiten stehen in `pyproject.toml`.
- `uv.lock` wird committed.
- Virtuelle Umgebung, Caches und Buildartefakte werden nicht committed.
- Abhängigkeitsupdates erfolgen bewusst und werden durch Tests geprüft.

## Qualitätsgates

Vor jedem Commit mit Importer-Code müssen erfolgreich sein:

- Tests,
- Ruff-Lint,
- Ruff-Formatprüfung,
- Mypy für Produktcode.

Die Befehle werden zusätzlich in `AGENTS.md` gepflegt.

## Folgen

Positiv:

- reproduzierbare lokale Umgebung,
- keine Änderung der globalen Python-Installation,
- schnelle Installation und Prüfung,
- einheitliche Werkzeuge für lokale Entwicklung und CI.

Negativ:

- `uv` ist ein zusätzlich benötigtes Werkzeug,
- die zunächst enge Python-Versionsgrenze benötigt bewusste Upgrades,
- `openpyxl` ist eine zusätzliche Laufzeitabhängigkeit.

