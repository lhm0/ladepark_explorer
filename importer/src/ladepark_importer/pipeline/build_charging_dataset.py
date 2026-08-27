"""Orchestrate the FR-DATA-001 and NFR-DATA-001 charging dataset build."""

from dataclasses import dataclass
from pathlib import Path

from ladepark_importer.charging_sqlite import (
    SqliteBuildMetadata,
    SqliteValidationResult,
    export_charging_sqlite,
)
from ladepark_importer.clustering import (
    SUPPORTED_DIAMETERS_M,
    StationPoint,
    build_proximity_groups,
)
from ladepark_importer.configuration import load_connector_types, load_namespaces
from ladepark_importer.operator_registry import load_operator_registry
from ladepark_importer.transformation import normalize_file


@dataclass(frozen=True, slots=True)
class ChargingDatasetBuildRequest:
    source: Path
    output: Path
    namespaces: Path
    connector_types: Path
    operators: Path
    dataset_version: str
    source_version: str
    created_at: str
    pipeline_version: str
    replace: bool = False


def build_charging_dataset(request: ChargingDatasetBuildRequest) -> SqliteValidationResult:
    """Normalize, group, export, and validate one charging dataset."""
    namespaces = load_namespaces(request.namespaces)
    snapshot = normalize_file(
        request.source,
        namespaces,
        load_connector_types(request.connector_types),
    )
    operator_registry = load_operator_registry(
        request.operators,
        namespaces.operator,
        {station.operator_source_name for station in snapshot.stations},
    )
    points = tuple(
        StationPoint(
            station.station_id,
            float(station.latitude),
            float(station.longitude),
        )
        for station in snapshot.stations
    )
    groups_by_diameter = {
        diameter: build_proximity_groups(
            points,
            request.dataset_version,
            diameter,
            namespaces.proximity_group,
        )
        for diameter in SUPPORTED_DIAMETERS_M
    }
    return export_charging_sqlite(
        request.output,
        snapshot,
        groups_by_diameter,
        SqliteBuildMetadata(
            dataset_id="ladepark-explorer-de",
            dataset_version=request.dataset_version,
            source_version=request.source_version,
            created_at=request.created_at,
            pipeline_version=request.pipeline_version,
        ),
        namespaces.operator,
        request.source,
        operator_registry,
        replace=request.replace,
    )
