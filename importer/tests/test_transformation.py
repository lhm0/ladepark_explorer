import csv
from decimal import Decimal
from pathlib import Path

import pytest

from ladepark_importer.configuration import load_connector_types, load_namespaces
from ladepark_importer.errors import DataValidationError
from ladepark_importer.transformation import normalize_file

# Referenztests für FR-DATA-001 und NFR-DATA-001.

PROJECT_DIRECTORY = Path(__file__).parents[1]
FIXTURE = Path(__file__).parent / "fixtures" / "bnetza_minimal.csv"
NAMESPACES = load_namespaces(PROJECT_DIRECTORY / "config" / "namespaces.json")
CONNECTOR_TYPES = load_connector_types(PROJECT_DIRECTORY / "config" / "connector_types.json")


def test_normalize_minimal_snapshot() -> None:
    snapshot = normalize_file(FIXTURE, NAMESPACES, CONNECTOR_TYPES)

    assert len(snapshot.stations) == 2
    assert snapshot.evse_count == 3
    assert snapshot.connector_count == 3
    assert snapshot.warnings == ()

    berlin = next(
        station for station in snapshot.stations if station.source_station_id == "DE-BNA-0001"
    )
    assert berlin.station_id == "fff955ec-a4d7-52ee-9250-46c4d6d53840"
    assert berlin.address.postal_code == "10115"
    assert berlin.latitude.as_tuple().exponent == -6
    assert {evse.current_type for evse in berlin.evses} == {"dc"}
    assert {connector.connector_type for evse in berlin.evses for connector in evse.connectors} == {
        "ccs"
    }
    assert berlin.evses[0].source_evse_id == "DE*BSP*E0001*1"

    munich = next(
        station for station in snapshot.stations if station.source_station_id == "DE-BNA-0002"
    )
    assert munich.evses[0].current_type == "ac"
    assert munich.evses[0].connectors[0].connector_type == "type_2"


def test_normalization_is_deterministic() -> None:
    first = normalize_file(FIXTURE, NAMESPACES, CONNECTOR_TYPES)
    second = normalize_file(FIXTURE, NAMESPACES, CONNECTOR_TYPES)

    assert first == second


def test_invalid_evse_id_uses_fallback_and_warns(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("EVSE-ID1")] = "invalid"
    target = tmp_path / "invalid_evse.csv"
    _write_csv(target, rows)

    snapshot = normalize_file(target, NAMESPACES, CONNECTOR_TYPES)

    first_evse = next(
        station.evses[0]
        for station in snapshot.stations
        if station.source_station_id == "DE-BNA-0001"
    )
    assert first_evse.source_evse_id is None
    assert any("ungültige EVSE-ID" in warning for warning in snapshot.warnings)


def test_unknown_connector_is_preserved_and_warns(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("Steckertypen1")] = "Megaplug"
    target = tmp_path / "unknown_connector.csv"
    _write_csv(target, rows)

    snapshot = normalize_file(target, NAMESPACES, CONNECTOR_TYPES)

    connector = next(
        station.evses[0].connectors[0]
        for station in snapshot.stations
        if station.source_station_id == "DE-BNA-0001"
    )
    assert connector.connector_type == "unknown:megaplug"
    assert connector.source_type == "Megaplug"
    assert any("unbekannter Steckertyp" in warning for warning in snapshot.warnings)


def test_multiple_connector_types_create_multiple_connectors(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("Steckertypen1")] = "DC Fahrzeugkupplung Typ Combo 2 (CCS); DC CHAdeMO"
    rows[1][rows[0].index("Nennleistung Stecker1")] = "150; 50"
    target = tmp_path / "multiple_connectors.csv"
    _write_csv(target, rows)

    snapshot = normalize_file(target, NAMESPACES, CONNECTOR_TYPES)

    connectors = next(
        station.evses[0].connectors
        for station in snapshot.stations
        if station.source_station_id == "DE-BNA-0001"
    )
    assert {connector.connector_type for connector in connectors} == {"ccs", "chademo"}
    assert len({connector.connector_id for connector in connectors}) == 2
    assert {connector.max_power_kw for connector in connectors} == {Decimal("50"), Decimal("150")}


def test_single_power_is_applied_to_all_connectors(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("Steckertypen1")] = "DC Fahrzeugkupplung Typ Combo 2 (CCS); DC CHAdeMO"
    target = tmp_path / "shared_power.csv"
    _write_csv(target, rows)

    snapshot = normalize_file(target, NAMESPACES, CONNECTOR_TYPES)

    berlin = next(
        station for station in snapshot.stations if station.source_station_id == "DE-BNA-0001"
    )
    assert {connector.max_power_kw for connector in berlin.evses[0].connectors} == {Decimal("300")}


def test_ambiguous_power_cardinality_remains_unknown(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("Nennleistung Stecker1")] = "150; 50"
    target = tmp_path / "ambiguous_power.csv"
    _write_csv(target, rows)

    snapshot = normalize_file(target, NAMESPACES, CONNECTOR_TYPES)

    berlin = next(
        station for station in snapshot.stations if station.source_station_id == "DE-BNA-0001"
    )
    assert berlin.evses[0].max_power_kw == Decimal("150")
    assert berlin.evses[0].connectors[0].max_power_kw is None
    assert any("Connectorleistung bleibt unbekannt" in warning for warning in snapshot.warnings)


def test_negative_connector_power_is_rejected(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("Nennleistung Stecker1")] = "-1"
    target = tmp_path / "negative_power.csv"
    _write_csv(target, rows)

    with pytest.raises(DataValidationError, match="nichtnegative"):
        normalize_file(target, NAMESPACES, CONNECTOR_TYPES)


def test_missing_house_number_is_preserved_as_unknown(tmp_path: Path) -> None:
    rows = _fixture_rows()
    rows[1][rows[0].index("Hausnummer")] = ""
    target = tmp_path / "missing_house_number.csv"
    _write_csv(target, rows)

    snapshot = normalize_file(target, NAMESPACES, CONNECTOR_TYPES)

    berlin = next(
        station for station in snapshot.stations if station.source_station_id == "DE-BNA-0001"
    )
    assert berlin.address.house_number is None
    assert any("Hausnummer fehlt" in warning for warning in snapshot.warnings)


def _fixture_rows() -> list[list[str]]:
    with FIXTURE.open(encoding="utf-8", newline="") as handle:
        return list(csv.reader(handle, delimiter=";"))


def _write_csv(path: Path, rows: list[list[str]]) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        csv.writer(handle, delimiter=";").writerows(rows)
