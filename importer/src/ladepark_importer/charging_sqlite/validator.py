"""Read-only integrity validation for charging SQLite artifacts."""

import sqlite3
from pathlib import Path

from ladepark_importer.charging_sqlite.models import SqliteValidationResult
from ladepark_importer.charging_sqlite.schema import SCHEMA_VERSION
from ladepark_importer.clustering import SUPPORTED_DIAMETERS_M
from ladepark_importer.errors import ImporterError


def validate_charging_sqlite(path: Path) -> SqliteValidationResult:
    try:
        connection = sqlite3.connect(f"file:{path}?mode=ro", uri=True)
    except sqlite3.Error as error:
        raise ImporterError(f"SQLite-Datei kann nicht geöffnet werden: {error}") from error
    try:
        integrity = connection.execute("PRAGMA integrity_check").fetchone()
        if integrity != ("ok",):
            raise ImporterError(f"SQLite integrity_check fehlgeschlagen: {integrity}")
        foreign_keys = connection.execute("PRAGMA foreign_key_check").fetchall()
        if foreign_keys:
            raise ImporterError(f"SQLite-Fremdschlüsselfehler: {foreign_keys[:10]}")
        schema_version = connection.execute("PRAGMA user_version").fetchone()[0]
        if schema_version != SCHEMA_VERSION:
            raise ImporterError(
                f"Falsche SQLite-Schemaversion: {schema_version}, erwartet {SCHEMA_VERSION}"
            )
        counts = {
            table: connection.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            for table in (
                "station",
                "evse",
                "connector",
                "proximity_group",
                "proximity_group_member",
            )
        }
        diameters = tuple(
            row[0]
            for row in connection.execute(
                "SELECT DISTINCT diameter_m FROM proximity_group ORDER BY diameter_m"
            )
        )
        diameter_count = len(diameters)
        if diameters != SUPPORTED_DIAMETERS_M:
            raise ImporterError(f"Unvollständige Gruppendurchmesser: {diameters}")
        expected_members = counts["station"] * diameter_count
        if counts["proximity_group_member"] != expected_members:
            raise ImporterError(
                "Nicht jede Station besitzt genau eine Gruppenmitgliedschaft je Durchmesser"
            )
        duplicate_memberships = connection.execute(
            """
            SELECT COUNT(*) FROM (
                SELECT m.station_id, g.diameter_m
                FROM proximity_group_member m
                JOIN proximity_group g ON g.group_id = m.group_id
                GROUP BY m.station_id, g.diameter_m
                HAVING COUNT(*) != 1
            )
            """
        ).fetchone()[0]
        if duplicate_memberships:
            raise ImporterError("Mehrdeutige Gruppenmitgliedschaften gefunden")
        invalid_group_members = connection.execute(
            """
            SELECT COUNT(*)
            FROM proximity_group g
            WHERE NOT EXISTS (
                SELECT 1 FROM proximity_group_member m
                WHERE m.group_id = g.group_id
                  AND m.station_id = g.anchor_station_id
            )
            OR NOT EXISTS (
                SELECT 1 FROM proximity_group_member m
                WHERE m.group_id = g.group_id
                  AND m.station_id = g.medoid_station_id
            )
            OR g.actual_diameter_m > g.diameter_m + 0.0000001
            """
        ).fetchone()[0]
        if invalid_group_members:
            raise ImporterError("Ungültige Gruppenanker, Medoide oder Durchmesser")
        aggregate_errors = connection.execute(
            """
            SELECT COUNT(*)
            FROM proximity_group g
            JOIN (
                SELECT m.group_id,
                       COUNT(DISTINCT m.station_id) AS station_count,
                       COUNT(e.evse_id) AS evse_count,
                       SUM(CASE WHEN e.current_type = 'ac' THEN 1 ELSE 0 END) AS ac_count,
                       SUM(CASE WHEN e.current_type = 'dc' THEN 1 ELSE 0 END) AS dc_count,
                       SUM(CASE WHEN e.current_type = 'dc' AND e.max_power_kw >= 100
                                THEN 1 ELSE 0 END) AS hpc_count,
                       MAX(e.max_power_kw) AS max_power
                FROM proximity_group_member m
                JOIN evse e ON e.station_id = m.station_id
                GROUP BY m.group_id
            ) x ON x.group_id = g.group_id
            WHERE g.station_count != x.station_count
               OR g.evse_count != x.evse_count
               OR g.ac_evse_count != x.ac_count
               OR g.dc_evse_count != x.dc_count
               OR g.hpc_evse_count != x.hpc_count
               OR ABS(g.max_power_kw - x.max_power) > 0.000001
            """
        ).fetchone()[0]
        if aggregate_errors:
            raise ImporterError("Fehlerhafte Gruppenaggregate gefunden")
        index_errors = connection.execute(
            """
            SELECT
                (SELECT COUNT(*) FROM station)
                    != (SELECT COUNT(*) FROM station_geo)
                OR
                (SELECT COUNT(*) FROM station)
                    != (SELECT COUNT(*) FROM station_search)
                OR
                (SELECT COUNT(*) FROM proximity_group)
                    != (SELECT COUNT(*) FROM proximity_group_geo)
                OR
                (SELECT COUNT(*) FROM station) + (SELECT COUNT(*) FROM evse)
                    != (SELECT COUNT(*) FROM source_reference)
            """
        ).fetchone()[0]
        if index_errors:
            raise ImporterError("Unvollständige Such-, Geo- oder Leistungsindizes")
        group_geo_errors = connection.execute(
            """
            SELECT COUNT(*)
            FROM proximity_group g
            JOIN proximity_group_geo gg ON gg.group_rowid = g.group_rowid
            WHERE NOT (
                gg.min_latitude <= g.latitude
                AND gg.max_latitude >= g.latitude
                AND gg.min_longitude <= g.longitude
                AND gg.max_longitude >= g.longitude
            )
            """
        ).fetchone()[0]
        if group_geo_errors:
            raise ImporterError("Fehlerhafter Gruppen-Geoindex")
        source_reference_errors = connection.execute(
            """
            SELECT COUNT(*)
            FROM source_reference r
            LEFT JOIN station s
                ON r.object_type = 'station' AND s.station_id = r.object_id
            LEFT JOIN evse e
                ON r.object_type = 'evse' AND e.evse_id = r.object_id
            WHERE (r.object_type = 'station' AND s.station_id IS NULL)
               OR (r.object_type = 'evse' AND e.evse_id IS NULL)
            """
        ).fetchone()[0]
        if source_reference_errors:
            raise ImporterError("Verwaiste Quellenreferenzen gefunden")
        power_band_errors = connection.execute(
            """
            SELECT COUNT(*)
            FROM group_power_band b
            WHERE b.evse_count != (
                SELECT COUNT(*)
                FROM proximity_group_member m
                JOIN evse e ON e.station_id = m.station_id
                WHERE m.group_id = b.group_id
                  AND e.max_power_kw >= b.minimum_power_kw
            )
            """
        ).fetchone()[0]
        zero_band_count = connection.execute(
            "SELECT COUNT(*) FROM group_power_band WHERE minimum_power_kw = 0"
        ).fetchone()[0]
        if power_band_errors or zero_band_count != counts["proximity_group"]:
            raise ImporterError("Fehlerhafte sparse Leistungsbänder")
        always_open_band_errors = connection.execute(
            """
            SELECT COUNT(*)
            FROM group_always_open_power_band b
            WHERE b.evse_count != (
                SELECT COUNT(*)
                FROM proximity_group_member m
                JOIN station s ON s.station_id = m.station_id
                JOIN evse e ON e.station_id = s.station_id
                WHERE m.group_id = b.group_id
                  AND s.opening_hours_status = 'always_open'
                  AND e.max_power_kw >= b.minimum_power_kw
            )
            """
        ).fetchone()[0]
        missing_always_open_bands = connection.execute(
            """
            SELECT COUNT(*) FROM (
                SELECT m.group_id, p.minimum_power_kw
                FROM proximity_group_member m
                JOIN station s ON s.station_id = m.station_id
                JOIN evse e ON e.station_id = s.station_id
                CROSS JOIN (
                    SELECT DISTINCT minimum_power_kw FROM group_power_band
                ) p
                WHERE s.opening_hours_status = 'always_open'
                  AND e.max_power_kw >= p.minimum_power_kw
                GROUP BY m.group_id, p.minimum_power_kw
                EXCEPT
                SELECT group_id, minimum_power_kw
                FROM group_always_open_power_band
            )
            """
        ).fetchone()[0]
        if always_open_band_errors or missing_always_open_bands:
            raise ImporterError("Fehlerhafte 24/7-Leistungsbänder")
        connector_aggregate_errors = connection.execute(
            """
            SELECT COUNT(*)
            FROM group_connector gc
            WHERE gc.evse_count != (
                SELECT COUNT(DISTINCT e.evse_id)
                FROM proximity_group_member m
                JOIN evse e ON e.station_id = m.station_id
                JOIN connector c ON c.evse_id = e.evse_id
                WHERE m.group_id = gc.group_id
                  AND c.connector_type = gc.connector_type
            )
            """
        ).fetchone()[0]
        missing_connector_aggregates = connection.execute(
            """
            SELECT COUNT(*)
            FROM (
                SELECT m.group_id, c.connector_type
                FROM proximity_group_member m
                JOIN evse e ON e.station_id = m.station_id
                JOIN connector c ON c.evse_id = e.evse_id
                GROUP BY m.group_id, c.connector_type
                EXCEPT
                SELECT group_id, connector_type
                FROM group_connector
            )
            """
        ).fetchone()[0]
        if connector_aggregate_errors or missing_connector_aggregates:
            raise ImporterError("Fehlerhafte Connector-Gruppenaggregate")
        return SqliteValidationResult(
            station_count=counts["station"],
            evse_count=counts["evse"],
            connector_count=counts["connector"],
            group_count=counts["proximity_group"],
            group_member_count=counts["proximity_group_member"],
            diameter_count=diameter_count,
        )
    except sqlite3.Error as error:
        raise ImporterError(f"SQLite-Validierung fehlgeschlagen: {error}") from error
    finally:
        connection.close()
