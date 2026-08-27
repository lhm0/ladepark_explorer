import re
from decimal import Decimal
from pathlib import Path

from ladepark_importer.configuration import Namespaces
from ladepark_importer.errors import DataValidationError
from ladepark_importer.models import Address, Connector, Evse, NormalizedSnapshot, Station
from ladepark_importer.normalization import (
    normalize_text,
    parse_coordinate,
    parse_nonnegative_decimal,
    parse_positive_int,
    require_text,
    stable_uuid,
)
from ladepark_importer.schema import STATION_ID_COLUMN, inspect_schema
from ladepark_importer.source import open_source

EVSE_ID_PATTERN = re.compile(
    r"^(?P<country>[A-Z]{2})[.*-]?"
    r"(?P<operator>[A-Z0-9]{3})[.*-]?"
    r"E(?P<outlet>[A-Z0-9][A-Z0-9*._-]{0,30})$"
)
CONNECTOR_SEPARATOR = re.compile(r"\s*;\s*")
POWER_SEPARATOR = re.compile(r"\s*;\s*")
DC_CONNECTOR_TYPES = frozenset({"ccs", "chademo", "mcs", "tesla_type_2_dc"})

# Implementiert den Normalisierungsanteil von FR-DATA-001 und NFR-DATA-001.


def normalize_file(
    path: Path,
    namespaces: Namespaces,
    connector_mappings: dict[str, tuple[str, ...]],
) -> NormalizedSnapshot:
    source = open_source(path)
    schema = inspect_schema(source.headers)
    stations: list[Station] = []
    warnings: list[str] = []
    seen_station_ids: set[str] = set()
    seen_source_evse_ids: set[str] = set()

    for row_number, row in enumerate(source.rows(), start=1):
        station = _normalize_station(
            row,
            row_number,
            schema.slot_numbers,
            namespaces,
            connector_mappings,
            warnings,
            seen_source_evse_ids,
        )
        if station.station_id in seen_station_ids:
            raise DataValidationError(
                f"Zeile {row_number}: doppelte Ladeeinrichtungs-ID {station.source_station_id!r}"
            )
        seen_station_ids.add(station.station_id)
        stations.append(station)

    return NormalizedSnapshot(
        stations=tuple(sorted(stations, key=lambda station: station.station_id)),
        warnings=tuple(warnings),
    )


def _normalize_station(
    row: dict[str, object],
    row_number: int,
    slot_numbers: tuple[int, ...],
    namespaces: Namespaces,
    connector_mappings: dict[str, tuple[str, ...]],
    warnings: list[str],
    seen_source_evse_ids: set[str],
) -> Station:
    source_station_id = require_text(
        row.get(STATION_ID_COLUMN), f"Zeile {row_number} Ladeeinrichtungs-ID"
    )
    station_id = stable_uuid(namespaces.bnetza_station, f"bnetza:{source_station_id}")
    evses = tuple(
        evse
        for slot in slot_numbers
        if (
            evse := _normalize_evse(
                row,
                row_number,
                slot,
                station_id,
                namespaces,
                connector_mappings,
                warnings,
                seen_source_evse_ids,
            )
        )
        is not None
    )
    declared_evse_count = parse_positive_int(
        row.get("Anzahl Ladepunkte"), f"Zeile {row_number} Anzahl Ladepunkte"
    )
    if declared_evse_count != len(evses):
        warnings.append(
            f"Zeile {row_number}: Anzahl Ladepunkte={declared_evse_count}, "
            f"erzeugte EVSEs={len(evses)}"
        )

    operator_name = require_text(row.get("Betreiber"), f"Zeile {row_number} Betreiber")
    house_number = normalize_text(row.get("Hausnummer"))
    if house_number is None:
        warnings.append(f"Zeile {row_number}: Hausnummer fehlt")

    return Station(
        station_id=station_id,
        source_station_id=source_station_id,
        operator_source_name=operator_name,
        display_name=normalize_text(row.get("Anzeigename (Karte)")),
        status=require_text(row.get("Status"), f"Zeile {row_number} Status"),
        station_type=normalize_text(row.get("Art der Ladeeinrichtung")),
        declared_evse_count=declared_evse_count,
        nominal_power_kw=_optional_power(
            row.get("Nennleistung Ladeeinrichtung [kW]"),
            f"Zeile {row_number} Nennleistung Ladeeinrichtung",
        ),
        latitude=parse_coordinate(
            row.get("Breitengrad"),
            f"Zeile {row_number} Breitengrad",
            Decimal("-90"),
            Decimal("90"),
        ),
        longitude=parse_coordinate(
            row.get("Längengrad"),
            f"Zeile {row_number} Längengrad",
            Decimal("-180"),
            Decimal("180"),
        ),
        address=Address(
            street=require_text(row.get("Straße"), f"Zeile {row_number} Straße"),
            house_number=house_number,
            postal_code=require_text(row.get("Postleitzahl"), f"Zeile {row_number} Postleitzahl"),
            city=require_text(row.get("Ort"), f"Zeile {row_number} Ort"),
            address_addition=normalize_text(row.get("Adresszusatz")),
            district=normalize_text(row.get("Kreis/kreisfreie Stadt")),
            federal_state=normalize_text(row.get("Bundesland")),
        ),
        location_name=normalize_text(row.get("Standortbezeichnung")),
        parking_information=normalize_text(row.get("Informationen zum Parkraum")),
        payment_systems=normalize_text(row.get("Bezahlsysteme")),
        opening_hours=normalize_text(row.get("Öffnungszeiten")),
        opening_hours_weekdays=normalize_text(row.get("Öffnungszeiten: Wochentage")),
        opening_hours_times=normalize_text(row.get("Öffnungszeiten: Tageszeiten")),
        evses=evses,
    )


def _normalize_evse(
    row: dict[str, object],
    row_number: int,
    slot: int,
    station_id: str,
    namespaces: Namespaces,
    connector_mappings: dict[str, tuple[str, ...]],
    warnings: list[str],
    seen_source_evse_ids: set[str],
) -> Evse | None:
    source_types = normalize_text(row.get(f"Steckertypen{slot}"))
    if source_types is None:
        return None
    powers = _power_values(
        row.get(f"Nennleistung Stecker{slot}"),
        f"Zeile {row_number} Nennleistung Stecker{slot}",
    )
    raw_source_evse_id = normalize_text(row.get(f"EVSE-ID{slot}"))
    source_evse_id = _canonical_evse_id(raw_source_evse_id)
    duplicate_source_evse_id = False
    if source_evse_id is not None and source_evse_id in seen_source_evse_ids:
        warnings.append(
            f"Zeile {row_number} Slot {slot}: doppelte EVSE-ID {source_evse_id!r}; "
            "Fallback-ID wird verwendet"
        )
        source_evse_id = None
        duplicate_source_evse_id = True
    if source_evse_id is not None:
        seen_source_evse_ids.add(source_evse_id)
        evse_id = stable_uuid(namespaces.external_evse, f"evse:{source_evse_id}")
    else:
        if raw_source_evse_id is not None and not duplicate_source_evse_id:
            warnings.append(
                f"Zeile {row_number} Slot {slot}: ungültige EVSE-ID "
                f"{raw_source_evse_id!r}; Fallback-ID wird verwendet"
            )
        evse_id = stable_uuid(namespaces.bnetza_evse, f"{station_id}:slot:{slot}")

    connector_specs = _connector_specs(source_types, connector_mappings)
    connector_powers = _connector_powers(powers, len(connector_specs), row_number, slot, warnings)
    connectors: list[Connector] = []
    for ordinal, ((source_type, connector_type, known), connector_power) in enumerate(
        zip(connector_specs, connector_powers, strict=True), start=1
    ):
        if not known:
            warnings.append(
                f"Zeile {row_number} Slot {slot}: unbekannter Steckertyp {source_type!r}"
            )
        identity_type = (
            connector_type if len(connector_specs) == 1 else f"{connector_type}:{ordinal}"
        )
        connectors.append(
            Connector(
                connector_id=stable_uuid(namespaces.connector, f"{evse_id}:{identity_type}"),
                evse_id=evse_id,
                connector_type=connector_type,
                source_type=source_type,
                max_power_kw=connector_power,
            )
        )
    current_type = (
        "dc"
        if any(connector.connector_type in DC_CONNECTOR_TYPES for connector in connectors)
        else "ac"
    )
    return Evse(
        evse_id=evse_id,
        station_id=station_id,
        source_evse_id=source_evse_id,
        source_slot=slot,
        max_power_kw=max(powers),
        current_type=current_type,
        connectors=tuple(connectors),
    )


def _canonical_evse_id(value: object) -> str | None:
    normalized = normalize_text(value)
    if normalized is None:
        return None
    candidate = normalized.upper().replace(" ", "")
    match = EVSE_ID_PATTERN.fullmatch(candidate)
    if match is None:
        return None
    return f"{match.group('country')}*{match.group('operator')}*E{match.group('outlet')}"


def _connector_specs(
    source_types: str, connector_mappings: dict[str, tuple[str, ...]]
) -> tuple[tuple[str, str, bool], ...]:
    result: list[tuple[str, str, bool]] = []
    for source_type in CONNECTOR_SEPARATOR.split(source_types):
        normalized_source = normalize_text(source_type)
        if normalized_source is None:
            continue
        mapped_types = connector_mappings.get(normalized_source.casefold())
        if mapped_types is None:
            unknown_type = f"unknown:{normalized_source.casefold().replace(' ', '_')}"
            result.append((normalized_source, unknown_type, False))
        else:
            result.extend(
                (normalized_source, connector_type, True) for connector_type in mapped_types
            )
    if not result:
        raise DataValidationError(f"Keine auswertbaren Steckertypen in {source_types!r}")
    return tuple(result)


def _optional_power(value: object, field_name: str) -> Decimal | None:
    return None if normalize_text(value) is None else parse_nonnegative_decimal(value, field_name)


def _power_values(value: object, field_name: str) -> tuple[Decimal, ...]:
    normalized = require_text(value, field_name)
    powers = tuple(
        parse_nonnegative_decimal(part, field_name)
        for part in POWER_SEPARATOR.split(normalized)
        if part
    )
    if not powers:
        raise DataValidationError(f"{field_name}: keine Leistung gefunden")
    return powers


def _connector_powers(
    powers: tuple[Decimal, ...],
    connector_count: int,
    row_number: int,
    slot: int,
    warnings: list[str],
) -> tuple[Decimal | None, ...]:
    if len(powers) == connector_count:
        return powers
    if len(powers) == 1:
        return powers * connector_count
    warnings.append(
        f"Zeile {row_number} Slot {slot}: {len(powers)} Leistungswerte für "
        f"{connector_count} Connectoren; Connectorleistung bleibt unbekannt"
    )
    return (None,) * connector_count
