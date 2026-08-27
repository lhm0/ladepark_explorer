import hashlib
import json
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path

from ladepark_importer.clustering import ProximityGroup
from ladepark_importer.models import NormalizedSnapshot


@dataclass(frozen=True, slots=True)
class NormalizationReport:
    source_path: str
    sha256: str
    station_count: int
    evse_count: int
    connector_count: int
    ac_evse_count: int
    dc_evse_count: int
    connector_types: dict[str, int]
    unknown_connector_types: dict[str, int]
    operators_without_registry: int
    stations_without_operator_registry: int
    invalid_evse_id_count: int
    duplicate_evse_id_count: int
    ambiguous_connector_power_count: int
    missing_house_number_count: int
    warning_count: int
    warning_examples: tuple[str, ...]

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


@dataclass(frozen=True, slots=True)
class LargestGroupSummary:
    group_id: str
    anchor_station_id: str
    anchor_source_station_id: str
    city: str
    station_count: int
    evse_count: int
    actual_diameter_m: float


@dataclass(frozen=True, slots=True)
class ClusteringReport:
    dataset_version: str
    diameter_m: int
    group_count: int
    singleton_group_count: int
    multi_station_group_count: int
    size_distribution: dict[str, int]
    largest_station_count: int
    largest_evse_count: int
    maximum_actual_diameter_m: float
    membership_sha256: str
    largest_station_groups: tuple[LargestGroupSummary, ...]
    largest_evse_groups: tuple[LargestGroupSummary, ...]

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


def build_normalization_report(path: Path, snapshot: NormalizedSnapshot) -> NormalizationReport:
    evses = [evse for station in snapshot.stations for evse in station.evses]
    connectors = [connector for evse in evses for connector in evse.connectors]
    connector_types = Counter(connector.connector_type for connector in connectors)
    operator_counts = Counter(station.operator_source_name for station in snapshot.stations)
    warnings = snapshot.warnings
    return NormalizationReport(
        source_path=str(path),
        sha256=_sha256(path),
        station_count=len(snapshot.stations),
        evse_count=len(evses),
        connector_count=len(connectors),
        ac_evse_count=sum(evse.current_type == "ac" for evse in evses),
        dc_evse_count=sum(evse.current_type == "dc" for evse in evses),
        connector_types=dict(sorted(connector_types.items())),
        unknown_connector_types=dict(
            sorted(
                (name, count)
                for name, count in connector_types.items()
                if name.startswith("unknown:")
            )
        ),
        operators_without_registry=len(operator_counts),
        stations_without_operator_registry=sum(operator_counts.values()),
        invalid_evse_id_count=sum("ungültige EVSE-ID" in warning for warning in warnings),
        duplicate_evse_id_count=sum("doppelte EVSE-ID" in warning for warning in warnings),
        ambiguous_connector_power_count=sum(
            "Connectorleistung bleibt unbekannt" in warning for warning in warnings
        ),
        missing_house_number_count=sum("Hausnummer fehlt" in warning for warning in warnings),
        warning_count=len(warnings),
        warning_examples=warnings[:20],
    )


def build_clustering_report(
    dataset_version: str,
    diameter_m: int,
    groups: tuple[ProximityGroup, ...],
    snapshot: NormalizedSnapshot,
) -> ClusteringReport:
    stations = {station.station_id: station for station in snapshot.stations}
    summaries = tuple(
        LargestGroupSummary(
            group_id=group.group_id,
            anchor_station_id=group.anchor_station_id,
            anchor_source_station_id=stations[group.anchor_station_id].source_station_id,
            city=stations[group.anchor_station_id].address.city,
            station_count=len(group.station_ids),
            evse_count=sum(len(stations[station_id].evses) for station_id in group.station_ids),
            actual_diameter_m=group.actual_diameter_m,
        )
        for group in groups
    )
    size_counts = Counter(summary.station_count for summary in summaries)
    membership = "\n".join(
        f"{group.group_id}:{','.join(group.station_ids)}" for group in groups
    ).encode()
    return ClusteringReport(
        dataset_version=dataset_version,
        diameter_m=diameter_m,
        group_count=len(groups),
        singleton_group_count=size_counts[1],
        multi_station_group_count=len(groups) - size_counts[1],
        size_distribution={str(size): count for size, count in sorted(size_counts.items())},
        largest_station_count=max(summary.station_count for summary in summaries),
        largest_evse_count=max(summary.evse_count for summary in summaries),
        maximum_actual_diameter_m=max(summary.actual_diameter_m for summary in summaries),
        membership_sha256=hashlib.sha256(membership).hexdigest(),
        largest_station_groups=tuple(
            sorted(
                summaries,
                key=lambda summary: (
                    -summary.station_count,
                    summary.anchor_station_id,
                ),
            )[:10]
        ),
        largest_evse_groups=tuple(
            sorted(
                summaries,
                key=lambda summary: (
                    -summary.evse_count,
                    summary.anchor_station_id,
                ),
            )[:10]
        ),
    )


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
