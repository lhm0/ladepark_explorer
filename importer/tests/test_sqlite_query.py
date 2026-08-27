from pathlib import Path

import pytest

from ladepark_importer.clustering import (
    SUPPORTED_DIAMETERS_M,
    StationPoint,
    build_proximity_groups,
)
from ladepark_importer.configuration import load_connector_types, load_namespaces
from ladepark_importer.errors import ImporterError
from ladepark_importer.sqlite_export import SqliteBuildMetadata, export_charging_sqlite
from ladepark_importer.sqlite_query import GroupQuery, get_group_detail, query_groups
from ladepark_importer.transformation import normalize_file

PROJECT_DIRECTORY = Path(__file__).parents[1]
FIXTURE = Path(__file__).parent / "fixtures" / "bnetza_minimal.csv"


@pytest.fixture
def database(tmp_path: Path) -> Path:
    target = tmp_path / "charging.sqlite3"
    namespaces = load_namespaces(PROJECT_DIRECTORY / "config" / "namespaces.json")
    snapshot = normalize_file(
        FIXTURE,
        namespaces,
        load_connector_types(PROJECT_DIRECTORY / "config" / "connector_types.json"),
    )
    points = tuple(
        StationPoint(station.station_id, float(station.latitude), float(station.longitude))
        for station in snapshot.stations
    )
    export_charging_sqlite(
        target,
        snapshot,
        {
            diameter: build_proximity_groups(
                points, "2026.07.0-test", diameter, namespaces.proximity_group
            )
            for diameter in SUPPORTED_DIAMETERS_M
        },
        SqliteBuildMetadata(
            dataset_id="ladepark-explorer-de",
            dataset_version="2026.07.0-test",
            source_version="test",
            created_at="2026-07-26T12:00:00Z",
            pipeline_version="test",
        ),
        namespaces.operator,
        FIXTURE,
    )
    return target


def test_default_query_applies_100_kw_filter(database: Path) -> None:
    result = query_groups(database, GroupQuery())

    assert result.returned_count == 1
    assert result.groups[0]["anchor_name"] == "Testpark Nord"
    assert result.groups[0]["hpc_evse_count"] == 2
    assert result.elapsed_ms >= 0


def test_query_combines_filters_and_ors_values(database: Path) -> None:
    result = query_groups(
        database,
        GroupQuery(
            minimum_power_evse_count=0,
            operator_names=("Unbekannt", "Andere Laden GmbH"),
            connector_types=("ccs", "type_2"),
        ),
    )

    assert result.returned_count == 1
    assert result.groups[0]["city"] == "München"


def test_query_supports_search_bounds_and_radius(database: Path) -> None:
    searched = query_groups(
        database,
        GroupQuery(minimum_power_evse_count=0, search_text="Münch", limit=1),
    )
    bounded = query_groups(
        database,
        GroupQuery(
            minimum_power_evse_count=0,
            bounds=(52.0, 13.0, 53.0, 14.0),
        ),
    )
    nearby = query_groups(
        database,
        GroupQuery(
            minimum_power_evse_count=0,
            near=(52.52, 13.405),
            radius_km=5,
        ),
    )

    assert searched.groups[0]["city"] == "München"
    assert bounded.groups[0]["city"] == "Berlin"
    assert nearby.groups[0]["city"] == "Berlin"
    assert nearby.groups[0]["distance_km"] == pytest.approx(0)


def test_query_reports_truncation(database: Path) -> None:
    result = query_groups(
        database,
        GroupQuery(minimum_power_evse_count=0, limit=1),
    )

    assert result.returned_count == 1
    assert result.truncated is True


def test_group_detail_contains_operators_bands_connectors_and_stations(database: Path) -> None:
    group_id = query_groups(database, GroupQuery()).groups[0]["group_id"]

    detail = get_group_detail(database, group_id)

    assert detail["operators"] == [{"source_name": "Beispiel Energie GmbH", "evse_count": 2}]
    assert detail["power_bands"][-1] == {"minimum_power_kw": 300, "evse_count": 2}
    assert detail["connectors"] == [{"connector_type": "ccs", "evse_count": 2}]
    assert detail["stations"][0]["name"] == "Testpark Nord"


def test_query_rejects_incomplete_radius(database: Path) -> None:
    with pytest.raises(ImporterError, match="gemeinsam"):
        query_groups(database, GroupQuery(near=(52.52, 13.405)))
