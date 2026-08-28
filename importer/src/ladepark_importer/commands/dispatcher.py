"""Command handlers kept separate from argument parsing."""

import argparse
import json
from dataclasses import asdict

from ladepark_importer.charging_sqlite import (
    GroupQuery,
    get_group_detail,
    query_groups,
    validate_charging_sqlite,
)
from ladepark_importer.clustering import StationPoint, build_proximity_groups
from ladepark_importer.configuration import load_connector_types, load_namespaces
from ladepark_importer.inspection import inspect_file
from ladepark_importer.models import NormalizedSnapshot
from ladepark_importer.operator_registry import (
    build_operator_coverage_report,
    export_operator_worklist_csv,
    load_operator_registry,
    validate_operator_registry,
)
from ladepark_importer.park_info import build_park_info_sqlite, validate_park_info_sqlite
from ladepark_importer.pipeline import ChargingDatasetBuildRequest, build_charging_dataset
from ladepark_importer.release_package import build_release_package
from ladepark_importer.reporting import build_clustering_report, build_normalization_report
from ladepark_importer.review import export_group_review_csv, export_operator_review_csv
from ladepark_importer.transformation import normalize_file


def dispatch(arguments: argparse.Namespace) -> int | None:
    if arguments.command == "inspect":
        print(inspect_file(arguments.source).to_json())
        return 0
    if arguments.command == "normalize":
        snapshot = normalize_file(
            arguments.source,
            load_namespaces(arguments.namespaces),
            load_connector_types(arguments.connector_types),
        )
        print(json.dumps(snapshot.to_dict(), ensure_ascii=False, indent=2, sort_keys=True))
        return 0
    if arguments.command == "report":
        snapshot = normalize_file(
            arguments.source,
            load_namespaces(arguments.namespaces),
            load_connector_types(arguments.connector_types),
        )
        print(build_normalization_report(arguments.source, snapshot).to_json())
        return 0
    if arguments.command == "cluster-report":
        namespaces = load_namespaces(arguments.namespaces)
        snapshot = normalize_file(
            arguments.source,
            namespaces,
            load_connector_types(arguments.connector_types),
        )
        points = tuple(
            StationPoint(
                station.station_id,
                float(station.latitude),
                float(station.longitude),
            )
            for station in snapshot.stations
        )
        groups = build_proximity_groups(
            points,
            arguments.dataset_version,
            arguments.diameter,
            namespaces.proximity_group,
        )
        print(
            build_clustering_report(
                arguments.dataset_version,
                arguments.diameter,
                groups,
                snapshot,
            ).to_json()
        )
        return 0
    if arguments.command == "cluster-review":
        namespaces = load_namespaces(arguments.namespaces)
        snapshot = normalize_file(
            arguments.source,
            namespaces,
            load_connector_types(arguments.connector_types),
        )
        points = tuple(
            StationPoint(
                station.station_id,
                float(station.latitude),
                float(station.longitude),
            )
            for station in snapshot.stations
        )
        groups = build_proximity_groups(
            points,
            arguments.dataset_version,
            arguments.diameter,
            namespaces.proximity_group,
        )
        print(
            export_group_review_csv(
                arguments.output,
                groups,
                snapshot,
                arguments.limit_per_category,
            ).to_json()
        )
        return 0
    if arguments.command == "operator-review":
        snapshot = normalize_file(
            arguments.source,
            load_namespaces(arguments.namespaces),
            load_connector_types(arguments.connector_types),
        )
        print(
            export_operator_review_csv(
                arguments.output,
                snapshot,
                arguments.candidate_limit,
            ).to_json()
        )
        return 0
    if arguments.command == "operator-worklist":
        snapshot = _normalized_snapshot(arguments)
        print(
            export_operator_worklist_csv(
                arguments.output,
                snapshot,
                arguments.top,
                arguments.candidate_limit,
            ).to_json()
        )
        return 0
    if arguments.command == "operator-registry-validate":
        namespaces = load_namespaces(arguments.namespaces)
        snapshot = _normalized_snapshot(arguments)
        print(
            validate_operator_registry(
                arguments.registry,
                snapshot,
                namespaces.operator,
            ).to_json()
        )
        return 0
    if arguments.command == "operator-coverage":
        namespaces = load_namespaces(arguments.namespaces)
        snapshot = _normalized_snapshot(arguments)
        registry = load_operator_registry(
            arguments.registry,
            namespaces.operator,
            {station.operator_source_name for station in snapshot.stations},
        )
        print(
            json.dumps(
                build_operator_coverage_report(snapshot, registry),
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
        )
        return 0
    if arguments.command == "build-sqlite":
        result = build_charging_dataset(
            ChargingDatasetBuildRequest(
                source=arguments.source,
                output=arguments.output,
                namespaces=arguments.namespaces,
                connector_types=arguments.connector_types,
                operators=arguments.operators,
                dataset_version=arguments.dataset_version,
                source_version=arguments.source_version,
                created_at=arguments.created_at,
                pipeline_version=arguments.pipeline_version,
                replace=arguments.replace,
            )
        )
        print(json.dumps(asdict(result), indent=2, sort_keys=True))
        return 0
    if arguments.command == "validate-sqlite":
        validation_result = validate_charging_sqlite(arguments.database)
        print(json.dumps(asdict(validation_result), indent=2, sort_keys=True))
        return 0
    if arguments.command == "build-release":
        release_result = build_release_package(
            arguments.database,
            arguments.output,
            arguments.repository,
            arguments.git_commit,
        )
        print(json.dumps(asdict(release_result), indent=2, sort_keys=True, default=str))
        return 0
    if arguments.command == "query-sqlite":
        query_result = query_groups(
            arguments.database,
            GroupQuery(
                diameter_m=arguments.diameter,
                minimum_evse_count=arguments.min_evse,
                minimum_power_kw=arguments.min_power,
                minimum_power_evse_count=arguments.min_power_evse,
                operator_names=tuple(arguments.operator),
                connector_types=tuple(arguments.connector),
                search_text=arguments.search,
                bounds=tuple(arguments.bounds) if arguments.bounds else None,
                near=tuple(arguments.near) if arguments.near else None,
                radius_km=arguments.radius_km,
                limit=arguments.limit,
            ),
        )
        print(json.dumps(query_result.to_dict(), ensure_ascii=False, indent=2, sort_keys=True))
        return 0
    if arguments.command == "group-detail":
        print(
            json.dumps(
                get_group_detail(arguments.database, arguments.group_id),
                ensure_ascii=False,
                indent=2,
                sort_keys=True,
            )
        )
        return 0
    if arguments.command == "build-park-info":
        park_info_result = build_park_info_sqlite(
            arguments.source,
            arguments.media,
            arguments.charging_database,
            arguments.output,
            arguments.media_output,
            replace=arguments.replace,
        )
        print(json.dumps(asdict(park_info_result), indent=2, sort_keys=True))
        return 0
    if arguments.command == "validate-park-info":
        validate_park_info_sqlite(arguments.database)
        print(json.dumps({"database": str(arguments.database), "valid": True}, indent=2))
        return 0
    return None


def _normalized_snapshot(arguments: argparse.Namespace) -> NormalizedSnapshot:
    return normalize_file(
        arguments.source,
        load_namespaces(arguments.namespaces),
        load_connector_types(arguments.connector_types),
    )
