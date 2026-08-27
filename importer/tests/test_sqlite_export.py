import hashlib
import sqlite3
from pathlib import Path

import pytest

from ladepark_importer.clustering import (
    SUPPORTED_DIAMETERS_M,
    StationPoint,
    build_proximity_groups,
)
from ladepark_importer.configuration import load_connector_types, load_namespaces
from ladepark_importer.errors import ImporterError
from ladepark_importer.operator_registry import load_operator_registry
from ladepark_importer.sqlite_export import (
    SCHEMA_VERSION,
    SqliteBuildMetadata,
    export_charging_sqlite,
    validate_charging_sqlite,
)
from ladepark_importer.transformation import normalize_file

PROJECT_DIRECTORY = Path(__file__).parents[1]
FIXTURE = Path(__file__).parent / "fixtures" / "bnetza_minimal.csv"
NAMESPACES = load_namespaces(PROJECT_DIRECTORY / "config" / "namespaces.json")
CONNECTOR_TYPES = load_connector_types(PROJECT_DIRECTORY / "config" / "connector_types.json")
METADATA = SqliteBuildMetadata(
    dataset_id="ladepark-explorer-de",
    dataset_version="2026.07.0-test",
    source_version="2026-07-07-test",
    created_at="2026-07-26T12:00:00Z",
    pipeline_version="test",
)


def test_sqlite_end_to_end_contract(tmp_path: Path) -> None:
    target = tmp_path / "charging.sqlite3"
    result = _build(target)

    assert result.station_count == 2
    assert result.evse_count == 3
    assert result.connector_count == 3
    assert result.group_count == 10
    assert result.group_member_count == 10
    assert result.diameter_count == 5

    connection = sqlite3.connect(target)
    try:
        assert connection.execute("PRAGMA user_version").fetchone() == (SCHEMA_VERSION,)
        assert connection.execute(
            "SELECT value FROM metadata WHERE key = 'dataset_version'"
        ).fetchone() == ("2026.07.0-test",)
        assert connection.execute("SELECT COUNT(*) FROM operator_source").fetchone() == (2,)
        assert connection.execute("SELECT COUNT(*) FROM source_reference").fetchone() == (5,)
        assert connection.execute("SELECT COUNT(*) FROM station_geo").fetchone() == (2,)
        assert connection.execute("SELECT COUNT(*) FROM proximity_group_geo").fetchone() == (10,)
        assert connection.execute(
            "SELECT COUNT(*) FROM station_search WHERE station_search MATCH 'Berlin'"
        ).fetchone() == (1,)
        assert connection.execute(
            """
            SELECT evse_count FROM group_power_band
            WHERE minimum_power_kw = 100
            ORDER BY evse_count DESC LIMIT 1
            """
        ).fetchone() == (2,)
        assert connection.execute(
            "SELECT opening_hours_status FROM station WHERE city = 'Berlin'"
        ).fetchone() == ("always_open",)
        assert connection.execute(
            """
            SELECT evse_count FROM group_always_open_power_band
            WHERE minimum_power_kw = 100
            ORDER BY evse_count DESC LIMIT 1
            """
        ).fetchone() == (2,)
        assert connection.execute(
            """
            SELECT evse_count FROM group_connector
            WHERE connector_type = 'ccs'
            ORDER BY evse_count DESC LIMIT 1
            """
        ).fetchone() == (2,)
    finally:
        connection.close()


def test_sqlite_build_is_byte_reproducible(tmp_path: Path) -> None:
    first = tmp_path / "first.sqlite3"
    second = tmp_path / "second.sqlite3"

    _build(first)
    _build(second)

    assert _sha256(first) == _sha256(second)


def test_sqlite_materializes_reviewed_operator_filters(tmp_path: Path) -> None:
    target = tmp_path / "charging.sqlite3"
    _build(target, with_operator_registry=True)

    with sqlite3.connect(target) as connection:
        assert connection.execute("SELECT display_name FROM operator").fetchone() == (
            "Beispiel Energie",
        )
        assert connection.execute(
            "SELECT station_count, evse_count FROM operator_filter_option"
        ).fetchone() == (1, 2)
        assert connection.execute(
            "SELECT COUNT(*) FROM station WHERE operator_id IS NOT NULL"
        ).fetchone() == (1,)
        assert connection.execute("SELECT COUNT(*) FROM group_operator").fetchone() == (5,)


def test_sqlite_refuses_unapproved_replacement(tmp_path: Path) -> None:
    target = tmp_path / "charging.sqlite3"
    _build(target)

    with pytest.raises(ImporterError, match="existiert bereits"):
        _build(target)


def test_validate_rejects_non_database(tmp_path: Path) -> None:
    target = tmp_path / "broken.sqlite3"
    target.write_text("not sqlite", encoding="utf-8")

    with pytest.raises(ImporterError, match="Validierung"):
        validate_charging_sqlite(target)


def test_validate_rejects_missing_connector_aggregate(tmp_path: Path) -> None:
    target = tmp_path / "charging.sqlite3"
    _build(target)
    with sqlite3.connect(target) as connection:
        connection.execute(
            """
            DELETE FROM group_connector
            WHERE connector_type = 'ccs'
              AND group_id = (
                  SELECT group_id FROM group_connector
                  WHERE connector_type = 'ccs'
                  LIMIT 1
              )
            """
        )

    with pytest.raises(ImporterError, match="Connector-Gruppenaggregate"):
        validate_charging_sqlite(target)


def _build(path: Path, *, with_operator_registry: bool = False):
    snapshot = normalize_file(FIXTURE, NAMESPACES, CONNECTOR_TYPES)
    points = tuple(
        StationPoint(
            station.station_id,
            float(station.latitude),
            float(station.longitude),
        )
        for station in snapshot.stations
    )
    groups = {
        diameter: build_proximity_groups(
            points,
            METADATA.dataset_version,
            diameter,
            NAMESPACES.proximity_group,
        )
        for diameter in SUPPORTED_DIAMETERS_M
    }
    registry = None
    if with_operator_registry:
        registry = load_operator_registry(
            Path(__file__).parent / "fixtures" / "operators_contract.json",
            NAMESPACES.operator,
            {station.operator_source_name for station in snapshot.stations},
        )
    return export_charging_sqlite(
        path,
        snapshot,
        groups,
        METADATA,
        NAMESPACES.operator,
        FIXTURE,
        registry,
    )


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()
