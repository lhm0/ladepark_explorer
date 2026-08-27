import hashlib
import os
import sqlite3
from collections import Counter
from pathlib import Path
from uuid import UUID

from ladepark_importer.charging_sqlite.models import SqliteBuildMetadata, SqliteValidationResult
from ladepark_importer.charging_sqlite.schema import (
    POWER_BANDS_KW,
    SCHEMA_SQL,
    SCHEMA_VERSION,
    SOURCE_ID,
)
from ladepark_importer.charging_sqlite.validator import validate_charging_sqlite
from ladepark_importer.clustering import ProximityGroup
from ladepark_importer.errors import ImporterError
from ladepark_importer.models import NormalizedSnapshot
from ladepark_importer.normalization import stable_uuid
from ladepark_importer.opening_hours import normalize_opening_hours
from ladepark_importer.operator_registry import OperatorRegistry


def export_charging_sqlite(
    output_path: Path,
    snapshot: NormalizedSnapshot,
    groups_by_diameter: dict[int, tuple[ProximityGroup, ...]],
    metadata: SqliteBuildMetadata,
    operator_namespace: UUID,
    source_path: Path,
    operator_registry: OperatorRegistry | None = None,
    replace: bool = False,
) -> SqliteValidationResult:
    if output_path.exists() and not replace:
        raise ImporterError(f"Ausgabedatei existiert bereits: {output_path}; --replace verwenden")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    temporary_path = output_path.with_name(f".{output_path.name}.tmp")
    if temporary_path.exists():
        temporary_path.unlink()
    try:
        connection = sqlite3.connect(temporary_path)
        try:
            _configure_build(connection)
            connection.executescript(SCHEMA_SQL)
            _insert_metadata(connection, metadata, source_path)
            registry = operator_registry or OperatorRegistry(version=1, operators=())
            operator_ids, canonical_ids = _insert_operators(
                connection, snapshot, operator_namespace, registry
            )
            _insert_stations(
                connection, snapshot, operator_ids, canonical_ids, metadata.source_version
            )
            _insert_evses_and_connectors(connection, snapshot)
            _insert_operator_statistics(connection, snapshot, registry)
            _insert_groups(connection, snapshot, groups_by_diameter, operator_ids, canonical_ids)
            connection.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
            connection.commit()
            connection.execute("ANALYZE")
            connection.commit()
            connection.execute("VACUUM")
        finally:
            connection.close()
        result = validate_charging_sqlite(temporary_path)
        os.replace(temporary_path, output_path)
        return result
    except ImporterError:
        if temporary_path.exists():
            temporary_path.unlink()
        raise
    except (OSError, sqlite3.Error) as error:
        if temporary_path.exists():
            temporary_path.unlink()
        raise ImporterError(f"SQLite-Export fehlgeschlagen: {error}") from error


def _configure_build(connection: sqlite3.Connection) -> None:
    connection.execute("PRAGMA foreign_keys = ON")
    connection.execute("PRAGMA journal_mode = OFF")
    connection.execute("PRAGMA synchronous = OFF")
    connection.execute("PRAGMA temp_store = MEMORY")


def _insert_metadata(
    connection: sqlite3.Connection,
    metadata: SqliteBuildMetadata,
    source_path: Path,
) -> None:
    values = {
        "dataset_id": metadata.dataset_id,
        "dataset_version": metadata.dataset_version,
        "schema_version": str(SCHEMA_VERSION),
        "created_at": metadata.created_at,
        "pipeline_version": metadata.pipeline_version,
        "region": metadata.region,
        "license_summary": metadata.license_summary,
        "source_version": metadata.source_version,
    }
    connection.executemany("INSERT INTO metadata(key, value) VALUES (?, ?)", sorted(values.items()))
    connection.execute(
        """
        INSERT INTO source(
            source_id, source_type, name, snapshot_version, source_url,
            license, attribution, sha256
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            SOURCE_ID,
            "charging_register",
            "Liste der Ladesäulen",
            metadata.source_version,
            "https://www.bundesnetzagentur.de/DE/Fachthemen/"
            "ElektrizitaetundGas/E-Mobilitaet/DownloadundKontakt.html",
            "CC-BY-4.0",
            "Bundesnetzagentur.de",
            _sha256(source_path),
        ),
    )


def _insert_operators(
    connection: sqlite3.Connection,
    snapshot: NormalizedSnapshot,
    namespace: UUID,
    registry: OperatorRegistry,
) -> tuple[dict[str, str], dict[str, str]]:
    names = sorted({station.operator_source_name for station in snapshot.stations})
    identifiers = {name: stable_uuid(namespace, f"operator-source:{name}") for name in names}
    connection.executemany(
        "INSERT INTO operator(operator_id, canonical_name, display_name) VALUES (?, ?, ?)",
        (
            (entry.operator_id, entry.canonical_name, entry.display_name)
            for entry in registry.operators
        ),
    )
    canonical_ids = {
        alias: entry.operator_id for entry in registry.operators for alias in entry.aliases
    }
    connection.executemany(
        """
        INSERT INTO operator_source(operator_source_id, source_name, canonical_operator_id)
        VALUES (?, ?, ?)
        """,
        ((identifiers[name], name, canonical_ids.get(name)) for name in names),
    )
    return identifiers, canonical_ids


def _insert_stations(
    connection: sqlite3.Connection,
    snapshot: NormalizedSnapshot,
    operator_ids: dict[str, str],
    canonical_ids: dict[str, str],
    source_version: str,
) -> None:
    stations = tuple(sorted(snapshot.stations, key=lambda station: station.station_id))
    opening_hours = {
        station.station_id: normalize_opening_hours(
            station.opening_hours,
            station.opening_hours_weekdays,
            station.opening_hours_times,
        )
        for station in stations
    }
    connection.executemany(
        """
        INSERT INTO station(
            station_id, station_rowid, operator_id, operator_source_id,
            source_status, station_type,
            name, latitude, longitude, street, house_number, postal_code, city, state,
            opening_hours_raw, opening_hours_weekdays_raw, opening_hours_times_raw,
            opening_hours_status, commissioned_on, data_updated_at, parking_information,
            payment_systems
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            (
                station.station_id,
                rowid,
                canonical_ids.get(station.operator_source_name),
                operator_ids[station.operator_source_name],
                station.status,
                station.station_type,
                station.display_name,
                float(station.latitude),
                float(station.longitude),
                station.address.street,
                station.address.house_number,
                station.address.postal_code,
                station.address.city,
                station.address.federal_state,
                opening_hours[station.station_id].raw,
                opening_hours[station.station_id].weekdays_raw,
                opening_hours[station.station_id].times_raw,
                opening_hours[station.station_id].status,
                None,
                source_version,
                station.parking_information,
                station.payment_systems,
            )
            for rowid, station in enumerate(stations, 1)
        ),
    )
    connection.executemany(
        """
        INSERT INTO station_geo(
            station_rowid, min_latitude, max_latitude, min_longitude, max_longitude
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            (
                rowid,
                float(station.latitude),
                float(station.latitude),
                float(station.longitude),
                float(station.longitude),
            )
            for rowid, station in enumerate(stations, 1)
        ),
    )
    connection.executemany(
        """
        INSERT INTO station_search(
            station_id, name, city, postal_code, street, operator_name
        ) VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            (
                station.station_id,
                station.display_name or "",
                station.address.city,
                station.address.postal_code,
                station.address.street,
                station.operator_source_name,
            )
            for station in stations
        ),
    )
    connection.executemany(
        """
        INSERT INTO source_reference(object_type, object_id, source_id, external_id)
        VALUES ('station', ?, ?, ?)
        """,
        ((station.station_id, SOURCE_ID, station.source_station_id) for station in stations),
    )


def _insert_evses_and_connectors(
    connection: sqlite3.Connection, snapshot: NormalizedSnapshot
) -> None:
    evses = tuple(
        sorted(
            (evse for station in snapshot.stations for evse in station.evses),
            key=lambda evse: evse.evse_id,
        )
    )
    connectors = tuple(
        sorted(
            (connector for evse in evses for connector in evse.connectors),
            key=lambda connector: connector.connector_id,
        )
    )
    connector_types = sorted({connector.connector_type for connector in connectors})
    connection.executemany(
        """
        INSERT INTO connector_type(connector_type, display_key, current_type)
        VALUES (?, ?, ?)
        """,
        (
            (
                connector_type,
                f"connector.{connector_type}",
                _connector_current_type(connector_type),
            )
            for connector_type in connector_types
        ),
    )
    connection.executemany(
        """
        INSERT INTO evse(
            evse_id, station_id, external_evse_id, source_slot,
            current_type, max_power_kw, access_status
        ) VALUES (?, ?, ?, ?, ?, ?, 'public')
        """,
        (
            (
                evse.evse_id,
                evse.station_id,
                evse.source_evse_id,
                evse.source_slot,
                evse.current_type,
                float(evse.max_power_kw),
            )
            for evse in evses
        ),
    )
    connection.executemany(
        """
        INSERT INTO connector(
            connector_id, evse_id, connector_type, source_connector_type, max_power_kw
        ) VALUES (?, ?, ?, ?, ?)
        """,
        (
            (
                connector.connector_id,
                connector.evse_id,
                connector.connector_type,
                connector.source_type,
                None if connector.max_power_kw is None else float(connector.max_power_kw),
            )
            for connector in connectors
        ),
    )
    station_source_ids = {
        station.station_id: station.source_station_id for station in snapshot.stations
    }
    connection.executemany(
        """
        INSERT INTO source_reference(object_type, object_id, source_id, external_id)
        VALUES ('evse', ?, ?, ?)
        """,
        (
            (
                evse.evse_id,
                SOURCE_ID,
                evse.source_evse_id
                or f"{station_source_ids[evse.station_id]}:slot:{evse.source_slot}",
            )
            for evse in evses
        ),
    )


def _insert_operator_statistics(
    connection: sqlite3.Connection,
    snapshot: NormalizedSnapshot,
    registry: OperatorRegistry,
) -> None:
    stations_by_name = {
        name: tuple(
            station for station in snapshot.stations if station.operator_source_name == name
        )
        for name in registry.aliases
    }
    for operator in registry.operators:
        stations = tuple(
            station for alias in operator.aliases for station in stations_by_name.get(alias, ())
        )
        evses = tuple(evse for station in stations for evse in station.evses)
        connection.execute(
            """
            INSERT INTO operator_filter_option(
                operator_id, station_count, evse_count, dc_evse_count, hpc_evse_count
            ) VALUES (?, ?, ?, ?, ?)
            """,
            (
                operator.operator_id,
                len(stations),
                len(evses),
                sum(evse.current_type == "dc" for evse in evses),
                sum(evse.current_type == "dc" and evse.max_power_kw >= 100 for evse in evses),
            ),
        )


def _insert_groups(
    connection: sqlite3.Connection,
    snapshot: NormalizedSnapshot,
    groups_by_diameter: dict[int, tuple[ProximityGroup, ...]],
    operator_ids: dict[str, str],
    canonical_ids: dict[str, str],
) -> None:
    stations = {station.station_id: station for station in snapshot.stations}
    group_rowid = 0
    for diameter_m in sorted(groups_by_diameter):
        for group in sorted(groups_by_diameter[diameter_m], key=lambda item: item.group_id):
            group_rowid += 1
            group_stations = tuple(stations[item] for item in group.station_ids)
            evses = tuple(evse for station in group_stations for evse in station.evses)
            hpc_count = sum(
                evse.current_type == "dc" and evse.max_power_kw >= 100 for evse in evses
            )
            connection.execute(
                """
                INSERT INTO proximity_group(
                    group_id, group_rowid, diameter_m, anchor_station_id, medoid_station_id,
                    latitude, longitude, actual_diameter_m, station_count, evse_count,
                    ac_evse_count, dc_evse_count, hpc_evse_count, max_power_kw
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    group.group_id,
                    group_rowid,
                    diameter_m,
                    group.anchor_station_id,
                    group.medoid_station_id,
                    group.latitude,
                    group.longitude,
                    group.actual_diameter_m,
                    len(group_stations),
                    len(evses),
                    sum(evse.current_type == "ac" for evse in evses),
                    sum(evse.current_type == "dc" for evse in evses),
                    hpc_count,
                    max(float(evse.max_power_kw) for evse in evses),
                ),
            )
            connection.execute(
                """
                INSERT INTO proximity_group_geo(
                    group_rowid, min_latitude, max_latitude,
                    min_longitude, max_longitude
                ) VALUES (?, ?, ?, ?, ?)
                """,
                (
                    group_rowid,
                    group.latitude,
                    group.latitude,
                    group.longitude,
                    group.longitude,
                ),
            )
            connection.executemany(
                """
                INSERT INTO proximity_group_member(group_id, station_id)
                VALUES (?, ?)
                """,
                ((group.group_id, station_id) for station_id in group.station_ids),
            )
            operator_counts: Counter[str] = Counter()
            for station in group_stations:
                operator_counts[operator_ids[station.operator_source_name]] += len(station.evses)
            connection.executemany(
                """
                INSERT INTO group_operator_source(group_id, operator_source_id, evse_count)
                VALUES (?, ?, ?)
                """,
                (
                    (group.group_id, operator_id, count)
                    for operator_id, count in sorted(operator_counts.items())
                ),
            )
            canonical_counts: Counter[str] = Counter()
            for station in group_stations:
                canonical_id = canonical_ids.get(station.operator_source_name)
                if canonical_id is not None:
                    canonical_counts[canonical_id] += len(station.evses)
            connection.executemany(
                "INSERT INTO group_operator(group_id, operator_id, evse_count) VALUES (?, ?, ?)",
                (
                    (group.group_id, operator_id, count)
                    for operator_id, count in sorted(canonical_counts.items())
                ),
            )
            power_band_rows = tuple(
                (
                    group.group_id,
                    minimum,
                    sum(evse.max_power_kw >= minimum for evse in evses),
                )
                for minimum in POWER_BANDS_KW
            )
            connection.executemany(
                """
                INSERT INTO group_power_band(group_id, minimum_power_kw, evse_count)
                VALUES (?, ?, ?)
                """,
                (row for row in power_band_rows if row[2] > 0),
            )
            always_open_evses = tuple(
                evse
                for station in group_stations
                if normalize_opening_hours(
                    station.opening_hours,
                    station.opening_hours_weekdays,
                    station.opening_hours_times,
                ).status
                == "always_open"
                for evse in station.evses
            )
            always_open_rows = tuple(
                (
                    group.group_id,
                    minimum,
                    sum(evse.max_power_kw >= minimum for evse in always_open_evses),
                )
                for minimum in POWER_BANDS_KW
            )
            connection.executemany(
                """
                INSERT INTO group_always_open_power_band(
                    group_id, minimum_power_kw, evse_count
                ) VALUES (?, ?, ?)
                """,
                (row for row in always_open_rows if row[2] > 0),
            )
            connector_counts: Counter[str] = Counter()
            for evse in evses:
                connector_counts.update({connector.connector_type for connector in evse.connectors})
            connection.executemany(
                """
                INSERT INTO group_connector(group_id, connector_type, evse_count)
                VALUES (?, ?, ?)
                """,
                (
                    (group.group_id, connector_type, count)
                    for connector_type, count in sorted(connector_counts.items())
                ),
            )


def _connector_current_type(connector_type: str) -> str:
    if connector_type in {"ccs", "chademo", "mcs", "tesla_type_2_dc"}:
        return "dc"
    if connector_type.startswith("unknown:"):
        return "unknown"
    return "ac"


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
