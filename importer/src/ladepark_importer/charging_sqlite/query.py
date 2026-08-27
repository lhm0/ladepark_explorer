import math
import re
import sqlite3
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from ladepark_importer.charging_sqlite.schema import POWER_BANDS_KW, SCHEMA_VERSION
from ladepark_importer.clustering import SUPPORTED_DIAMETERS_M
from ladepark_importer.errors import ImporterError

EARTH_RADIUS_KM = 6371.0088
_SEARCH_WORD = re.compile(r"\w+", re.UNICODE)


@dataclass(frozen=True, slots=True)
class GroupQuery:
    diameter_m: int = 50
    minimum_evse_count: int = 1
    minimum_power_kw: int = 100
    minimum_power_evse_count: int = 1
    operator_names: tuple[str, ...] = ()
    connector_types: tuple[str, ...] = ()
    always_open_only: bool = False
    search_text: str | None = None
    bounds: tuple[float, float, float, float] | None = None
    near: tuple[float, float] | None = None
    radius_km: float | None = None
    limit: int = 100


@dataclass(frozen=True, slots=True)
class GroupQueryResult:
    database: str
    elapsed_ms: float
    returned_count: int
    truncated: bool
    filters: dict[str, Any]
    groups: tuple[dict[str, Any], ...]

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


def query_groups(database: Path, query: GroupQuery) -> GroupQueryResult:
    _validate_query(query)
    started = time.perf_counter()
    connection = _open_database(database)
    try:
        clauses = [
            "g.diameter_m = :diameter_m",
            "g.evse_count >= :minimum_evse_count",
        ]
        parameters: dict[str, Any] = {
            "diameter_m": query.diameter_m,
            "minimum_evse_count": query.minimum_evse_count,
            "limit": query.limit + 1,
        }

        if query.minimum_power_evse_count > 0:
            power_band_table = (
                "group_always_open_power_band" if query.always_open_only else "group_power_band"
            )
            clauses.append(
                f"""
                EXISTS (
                    SELECT 1 FROM {power_band_table} pb
                    WHERE pb.group_id = g.group_id
                      AND pb.minimum_power_kw = :minimum_power_kw
                      AND pb.evse_count >= :minimum_power_evse_count
                )
                """
            )
            parameters["minimum_power_kw"] = query.minimum_power_kw
            parameters["minimum_power_evse_count"] = query.minimum_power_evse_count

        _append_multi_value_filter(
            clauses,
            parameters,
            query.operator_names,
            "operator",
            """
            EXISTS (
                SELECT 1
                FROM group_operator_source gos
                JOIN operator_source os
                  ON os.operator_source_id = gos.operator_source_id
                WHERE gos.group_id = g.group_id
                  AND os.source_name IN ({placeholders})
            )
            """,
        )
        _append_multi_value_filter(
            clauses,
            parameters,
            query.connector_types,
            "connector",
            """
            EXISTS (
                SELECT 1
                FROM group_connector gc
                WHERE gc.group_id = g.group_id
                  AND gc.connector_type IN ({placeholders})
            )
            """,
        )

        if query.search_text:
            clauses.append(
                """
                g.group_id IN (
                    SELECT gm.group_id
                    FROM station_search
                    JOIN proximity_group_member gm
                      ON gm.station_id = station_search.station_id
                    WHERE station_search MATCH :search_expression
                )
                """
            )
            parameters["search_expression"] = _fts_expression(query.search_text)

        effective_bounds = query.bounds
        group_geo_join = ""
        if query.near is not None and query.radius_km is not None:
            effective_bounds = _radius_bounds(*query.near, query.radius_km)
        if effective_bounds is not None:
            south, west, north, east = effective_bounds
            parameters.update(south=south, north=north)
            if _use_group_geo(effective_bounds):
                group_geo_join = "JOIN proximity_group_geo gg ON gg.group_rowid = g.group_rowid"
                clauses.extend(("gg.max_latitude >= :south", "gg.min_latitude <= :north"))
                if west <= east:
                    clauses.extend(("gg.max_longitude >= :west", "gg.min_longitude <= :east"))
                else:
                    clauses.append("(gg.max_longitude >= :west OR gg.min_longitude <= :east)")
            else:
                clauses.append("g.latitude BETWEEN :south AND :north")
                if west <= east:
                    clauses.append("g.longitude BETWEEN :west AND :east")
                else:
                    clauses.append("(g.longitude >= :west OR g.longitude <= :east)")
            parameters.update(west=west, east=east)

        distance_select = "NULL AS distance_km"
        order_by = "g.hpc_evse_count DESC, g.evse_count DESC, g.group_id"
        if query.near is not None:
            parameters.update(near_latitude=query.near[0], near_longitude=query.near[1])
            distance_select = (
                "haversine_km(:near_latitude, :near_longitude, "
                "g.latitude, g.longitude) AS distance_km"
            )
            order_by = "distance_km, g.group_id"
            if query.radius_km is not None:
                clauses.append(
                    "haversine_km(:near_latitude, :near_longitude, "
                    "g.latitude, g.longitude) <= :radius_km"
                )
                parameters["radius_km"] = query.radius_km

        sql = f"""
            SELECT
                g.group_id,
                g.diameter_m,
                g.anchor_station_id,
                s.name AS anchor_name,
                s.street,
                s.house_number,
                s.postal_code,
                s.city,
                g.latitude,
                g.longitude,
                g.station_count,
                g.evse_count,
                g.ac_evse_count,
                g.dc_evse_count,
                g.hpc_evse_count,
                g.max_power_kw,
                {distance_select}
            FROM proximity_group g
            {group_geo_join}
            JOIN station s ON s.station_id = g.anchor_station_id
            WHERE {" AND ".join(f"({clause})" for clause in clauses)}
            ORDER BY {order_by}
            LIMIT :limit
        """
        rows = connection.execute(sql, parameters).fetchall()
    except sqlite3.Error as error:
        raise ImporterError(f"SQLite-Abfrage fehlgeschlagen: {error}") from error
    finally:
        connection.close()

    truncated = len(rows) > query.limit
    groups = tuple(_row_to_dict(row) for row in rows[: query.limit])
    return GroupQueryResult(
        database=str(database),
        elapsed_ms=round((time.perf_counter() - started) * 1000, 3),
        returned_count=len(groups),
        truncated=truncated,
        filters=_query_filters(query),
        groups=groups,
    )


def get_group_detail(database: Path, group_id: str) -> dict[str, Any]:
    connection = _open_database(database)
    try:
        group = connection.execute(
            """
            SELECT g.*, s.name AS anchor_name, s.street, s.house_number,
                   s.postal_code, s.city
            FROM proximity_group g
            JOIN station s ON s.station_id = g.anchor_station_id
            WHERE g.group_id = ?
            """,
            (group_id,),
        ).fetchone()
        if group is None:
            raise ImporterError(f"Abstandsgruppe nicht gefunden: {group_id}")
        operators = connection.execute(
            """
            SELECT os.source_name, gos.evse_count
            FROM group_operator_source gos
            JOIN operator_source os
              ON os.operator_source_id = gos.operator_source_id
            WHERE gos.group_id = ?
            ORDER BY gos.evse_count DESC, os.source_name
            """,
            (group_id,),
        ).fetchall()
        power_bands = connection.execute(
            """
            SELECT minimum_power_kw, evse_count
            FROM group_power_band
            WHERE group_id = ?
            ORDER BY minimum_power_kw
            """,
            (group_id,),
        ).fetchall()
        connectors = connection.execute(
            """
            SELECT c.connector_type, COUNT(DISTINCT c.evse_id) AS evse_count
            FROM proximity_group_member gm
            JOIN evse e ON e.station_id = gm.station_id
            JOIN connector c ON c.evse_id = e.evse_id
            WHERE gm.group_id = ?
            GROUP BY c.connector_type
            ORDER BY evse_count DESC, c.connector_type
            """,
            (group_id,),
        ).fetchall()
        stations = connection.execute(
            """
            SELECT s.station_id, s.name, s.street, s.house_number,
                   s.postal_code, s.city, s.latitude, s.longitude,
                   os.source_name AS operator_name,
                   COUNT(e.evse_id) AS evse_count,
                   MAX(e.max_power_kw) AS max_power_kw
            FROM proximity_group_member gm
            JOIN station s ON s.station_id = gm.station_id
            JOIN operator_source os
              ON os.operator_source_id = s.operator_source_id
            LEFT JOIN evse e ON e.station_id = s.station_id
            WHERE gm.group_id = ?
            GROUP BY s.station_id
            ORDER BY evse_count DESC, s.station_id
            """,
            (group_id,),
        ).fetchall()
    except sqlite3.Error as error:
        raise ImporterError(f"SQLite-Detailabfrage fehlgeschlagen: {error}") from error
    finally:
        connection.close()
    return {
        "group": _row_to_dict(group),
        "operators": [_row_to_dict(row) for row in operators],
        "power_bands": [_row_to_dict(row) for row in power_bands],
        "connectors": [_row_to_dict(row) for row in connectors],
        "stations": [_row_to_dict(row) for row in stations],
    }


def _open_database(database: Path) -> sqlite3.Connection:
    if not database.is_file():
        raise ImporterError(f"SQLite-Datei nicht gefunden: {database}")
    try:
        connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
        connection.row_factory = sqlite3.Row
        connection.create_function("haversine_km", 4, _haversine_km, deterministic=True)
        version_row = connection.execute("PRAGMA user_version").fetchone()
        if version_row is None or version_row[0] != SCHEMA_VERSION:
            connection.close()
            raise ImporterError(
                f"Nicht unterstützte SQLite-Schemaversion: "
                f"{version_row[0] if version_row else 'unbekannt'}"
            )
        return connection
    except sqlite3.Error as error:
        raise ImporterError(f"SQLite-Datei kann nicht geöffnet werden: {error}") from error


def _validate_query(query: GroupQuery) -> None:
    if query.diameter_m not in SUPPORTED_DIAMETERS_M:
        raise ImporterError(f"Nicht unterstützter Gruppendurchmesser: {query.diameter_m}")
    if query.minimum_evse_count < 1 or query.minimum_power_evse_count < 0:
        raise ImporterError("Ladepunktzahlen dürfen nicht negativ sein")
    if query.minimum_power_kw not in POWER_BANDS_KW:
        raise ImporterError(
            f"Mindestleistung muss einer vorberechneten Stufe entsprechen: {POWER_BANDS_KW}"
        )
    if query.limit < 1 or query.limit > 1000:
        raise ImporterError("Limit muss zwischen 1 und 1000 liegen")
    if (query.near is None) != (query.radius_km is None):
        raise ImporterError("--near und --radius-km müssen gemeinsam verwendet werden")
    if query.radius_km is not None and query.radius_km <= 0:
        raise ImporterError("Suchradius muss größer als 0 sein")
    if query.bounds is not None:
        south, west, north, east = query.bounds
        if not (-90 <= south <= north <= 90 and -180 <= west <= 180 and -180 <= east <= 180):
            raise ImporterError("Ungültiger Kartenausschnitt")
    if query.near is not None:
        latitude, longitude = query.near
        if not (-90 <= latitude <= 90 and -180 <= longitude <= 180):
            raise ImporterError("Ungültige Position")


def _append_multi_value_filter(
    clauses: list[str],
    parameters: dict[str, Any],
    values: tuple[str, ...],
    prefix: str,
    template: str,
) -> None:
    if not values:
        return
    placeholders = []
    for index, value in enumerate(values):
        key = f"{prefix}_{index}"
        placeholders.append(f":{key}")
        parameters[key] = value
    clauses.append(template.format(placeholders=", ".join(placeholders)))


def _fts_expression(search_text: str) -> str:
    words = _SEARCH_WORD.findall(search_text)
    if not words:
        raise ImporterError("Suchtext enthält keine suchbaren Zeichen")
    return " AND ".join(f'"{word}"*' for word in words)


def _radius_bounds(
    latitude: float, longitude: float, radius_km: float
) -> tuple[float, float, float, float]:
    latitude_delta = math.degrees(radius_km / EARTH_RADIUS_KM)
    cosine = max(abs(math.cos(math.radians(latitude))), 1e-12)
    longitude_delta = min(180.0, latitude_delta / cosine)
    south = max(-90.0, latitude - latitude_delta)
    north = min(90.0, latitude + latitude_delta)
    west = ((longitude - longitude_delta + 180) % 360) - 180
    east = ((longitude + longitude_delta + 180) % 360) - 180
    return south, west, north, east


def _use_group_geo(bounds: tuple[float, float, float, float]) -> bool:
    south, west, north, east = bounds
    longitude_span = east - west if west <= east else 360 - west + east
    return (north - south) * longitude_span <= 25


def _haversine_km(
    latitude_a: float, longitude_a: float, latitude_b: float, longitude_b: float
) -> float:
    lat_a = math.radians(latitude_a)
    lat_b = math.radians(latitude_b)
    delta_lat = lat_b - lat_a
    delta_lon = math.radians(longitude_b - longitude_a)
    haversine = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(lat_a) * math.cos(lat_b) * math.sin(delta_lon / 2) ** 2
    )
    return 2 * EARTH_RADIUS_KM * math.asin(min(1.0, math.sqrt(haversine)))


def _row_to_dict(row: sqlite3.Row) -> dict[str, Any]:
    return dict(row)


def _query_filters(query: GroupQuery) -> dict[str, Any]:
    return {
        "diameter_m": query.diameter_m,
        "minimum_evse_count": query.minimum_evse_count,
        "minimum_power_kw": query.minimum_power_kw,
        "minimum_power_evse_count": query.minimum_power_evse_count,
        "operator_names": list(query.operator_names),
        "connector_types": list(query.connector_types),
        "always_open_only": query.always_open_only,
        "search_text": query.search_text,
        "bounds": list(query.bounds) if query.bounds else None,
        "near": list(query.near) if query.near else None,
        "radius_km": query.radius_km,
        "limit": query.limit,
    }
