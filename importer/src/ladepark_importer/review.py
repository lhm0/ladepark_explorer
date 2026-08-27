import csv
import json
import re
import unicodedata
from collections import Counter
from collections.abc import Callable
from dataclasses import asdict, dataclass
from decimal import Decimal
from difflib import SequenceMatcher
from pathlib import Path

from ladepark_importer.clustering import ProximityGroup
from ladepark_importer.models import NormalizedSnapshot, Station

HPC_MINIMUM_POWER_KW = Decimal("100")

# Unterstützt die manuelle Qualitätsprüfung für FR-GROUP-001 und FR-DATA-003.

FIELD_NAMES = (
    "selection_reasons",
    "rank_by_hpc",
    "rank_by_evses",
    "rank_by_stations",
    "group_id",
    "anchor_station_id",
    "anchor_source_station_id",
    "anchor_display_name",
    "anchor_street",
    "anchor_house_number",
    "anchor_postal_code",
    "anchor_city",
    "anchor_latitude",
    "anchor_longitude",
    "medoid_station_id",
    "medoid_latitude",
    "medoid_longitude",
    "display_names",
    "statuses",
    "configured_diameter_m",
    "actual_diameter_m",
    "station_count",
    "evse_count",
    "ac_evse_count",
    "dc_evse_count",
    "hpc_evse_count",
    "maximum_power_kw",
    "maximum_identical_coordinate_count",
    "operator_count",
    "operators",
    "connector_types",
    "source_station_ids",
)

OPERATOR_FIELD_NAMES = (
    "rank_by_evses",
    "operator_source_name",
    "normalized_key",
    "comparison_key",
    "station_count",
    "evse_count",
    "ac_evse_count",
    "dc_evse_count",
    "hpc_evse_count",
    "maximum_power_kw",
    "federal_states",
    "sample_cities",
    "similar_source_names",
    "canonical_operator",
    "review_status",
)

_LEGAL_FORM_WORDS = frozenset(
    {
        "ag",
        "eg",
        "gbr",
        "gmbh",
        "kg",
        "kgaa",
        "mbh",
        "ohg",
        "se",
        "ug",
    }
)
_NON_ALPHANUMERIC = re.compile(r"[^0-9a-zäöüß]+")


@dataclass(frozen=True, slots=True)
class ReviewExportResult:
    output_path: str
    group_count: int
    limit_per_category: int

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


@dataclass(frozen=True, slots=True)
class OperatorReviewExportResult:
    output_path: str
    operator_count: int
    candidate_limit: int

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


@dataclass(frozen=True, slots=True)
class _GroupMetrics:
    group: ProximityGroup
    stations: tuple[Station, ...]
    evse_count: int
    ac_evse_count: int
    dc_evse_count: int
    hpc_evse_count: int
    maximum_power_kw: Decimal


@dataclass(frozen=True, slots=True)
class OperatorStatistics:
    source_name: str
    normalized_key: str
    comparison_key: str
    stations: tuple[Station, ...]
    evse_count: int
    ac_evse_count: int
    dc_evse_count: int
    hpc_evse_count: int
    maximum_power_kw: Decimal


def export_operator_review_csv(
    output_path: Path,
    snapshot: NormalizedSnapshot,
    candidate_limit: int = 5,
) -> OperatorReviewExportResult:
    """Export source-name statistics and fuzzy review hints without merging identities."""
    if candidate_limit < 0:
        raise ValueError("candidate_limit darf nicht negativ sein")
    metrics = build_operator_statistics(snapshot)
    ordered = sorted(
        metrics,
        key=lambda item: (
            -item.evse_count,
            -item.hpc_evse_count,
            -len(item.stations),
            item.source_name.casefold(),
            item.source_name,
        ),
    )
    candidates = find_operator_candidates(metrics, candidate_limit)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=OPERATOR_FIELD_NAMES, delimiter=";")
        writer.writeheader()
        for rank, item in enumerate(ordered, 1):
            writer.writerow(_operator_review_row(rank, item, candidates[item.source_name]))
    return OperatorReviewExportResult(
        output_path=str(output_path),
        operator_count=len(ordered),
        candidate_limit=candidate_limit,
    )


def export_group_review_csv(
    output_path: Path,
    groups: tuple[ProximityGroup, ...],
    snapshot: NormalizedSnapshot,
    limit_per_category: int = 100,
) -> ReviewExportResult:
    if limit_per_category < 1:
        raise ValueError("limit_per_category muss positiv sein")
    stations_by_id = {station.station_id: station for station in snapshot.stations}
    metrics = tuple(_metrics_for_group(group, stations_by_id) for group in groups)
    rankings = {
        "hpc": _rank(metrics, lambda item: item.hpc_evse_count),
        "evses": _rank(metrics, lambda item: item.evse_count),
        "stations": _rank(metrics, lambda item: len(item.stations)),
    }
    selected_ids = {
        group_id
        for ranking in rankings.values()
        for group_id, rank in ranking.items()
        if rank <= limit_per_category
    }
    selected = sorted(
        (item for item in metrics if item.group.group_id in selected_ids),
        key=lambda item: (
            -item.hpc_evse_count,
            -item.evse_count,
            -len(item.stations),
            item.group.anchor_station_id,
        ),
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELD_NAMES, delimiter=";")
        writer.writeheader()
        for item in selected:
            writer.writerow(_review_row(item, rankings, limit_per_category))
    return ReviewExportResult(
        output_path=str(output_path),
        group_count=len(selected),
        limit_per_category=limit_per_category,
    )


def _metrics_for_group(group: ProximityGroup, stations_by_id: dict[str, Station]) -> _GroupMetrics:
    stations = tuple(stations_by_id[station_id] for station_id in group.station_ids)
    evses = tuple(evse for station in stations for evse in station.evses)
    return _GroupMetrics(
        group=group,
        stations=stations,
        evse_count=len(evses),
        ac_evse_count=sum(evse.current_type == "ac" for evse in evses),
        dc_evse_count=sum(evse.current_type == "dc" for evse in evses),
        hpc_evse_count=sum(
            evse.current_type == "dc" and evse.max_power_kw >= HPC_MINIMUM_POWER_KW
            for evse in evses
        ),
        maximum_power_kw=max((evse.max_power_kw for evse in evses), default=Decimal("0")),
    )


def _rank(
    metrics: tuple[_GroupMetrics, ...],
    value: Callable[[_GroupMetrics], int],
) -> dict[str, int]:
    ordered = sorted(
        metrics,
        key=lambda item: (
            -value(item),
            item.group.anchor_station_id,
        ),
    )
    return {item.group.group_id: index for index, item in enumerate(ordered, 1)}


def _review_row(
    item: _GroupMetrics,
    rankings: dict[str, dict[str, int]],
    limit_per_category: int,
) -> dict[str, object]:
    group = item.group
    anchor = next(
        station for station in item.stations if station.station_id == group.anchor_station_id
    )
    coordinate_counts = Counter((station.latitude, station.longitude) for station in item.stations)
    reasons = [
        name for name, ranking in rankings.items() if ranking[group.group_id] <= limit_per_category
    ]
    operators = sorted({station.operator_source_name for station in item.stations})
    connector_types = sorted(
        {
            connector.connector_type
            for station in item.stations
            for evse in station.evses
            for connector in evse.connectors
        }
    )
    display_names = sorted(
        {station.display_name for station in item.stations if station.display_name is not None}
    )
    statuses = sorted({station.status for station in item.stations})
    return {
        "selection_reasons": "|".join(reasons),
        "rank_by_hpc": rankings["hpc"][group.group_id],
        "rank_by_evses": rankings["evses"][group.group_id],
        "rank_by_stations": rankings["stations"][group.group_id],
        "group_id": group.group_id,
        "anchor_station_id": group.anchor_station_id,
        "anchor_source_station_id": anchor.source_station_id,
        "anchor_display_name": anchor.display_name or "",
        "anchor_street": anchor.address.street,
        "anchor_house_number": anchor.address.house_number or "",
        "anchor_postal_code": anchor.address.postal_code,
        "anchor_city": anchor.address.city,
        "anchor_latitude": str(anchor.latitude),
        "anchor_longitude": str(anchor.longitude),
        "medoid_station_id": group.medoid_station_id,
        "medoid_latitude": f"{group.latitude:.8f}",
        "medoid_longitude": f"{group.longitude:.8f}",
        "display_names": "|".join(display_names),
        "statuses": "|".join(statuses),
        "configured_diameter_m": group.diameter_m,
        "actual_diameter_m": f"{group.actual_diameter_m:.6f}",
        "station_count": len(item.stations),
        "evse_count": item.evse_count,
        "ac_evse_count": item.ac_evse_count,
        "dc_evse_count": item.dc_evse_count,
        "hpc_evse_count": item.hpc_evse_count,
        "maximum_power_kw": str(item.maximum_power_kw),
        "maximum_identical_coordinate_count": max(coordinate_counts.values()),
        "operator_count": len(operators),
        "operators": "|".join(operators),
        "connector_types": "|".join(connector_types),
        "source_station_ids": "|".join(
            sorted(station.source_station_id for station in item.stations)
        ),
    }


def build_operator_statistics(snapshot: NormalizedSnapshot) -> tuple[OperatorStatistics, ...]:
    stations_by_operator: dict[str, list[Station]] = {}
    for station in snapshot.stations:
        stations_by_operator.setdefault(station.operator_source_name, []).append(station)
    return tuple(
        _operator_statistics(source_name, tuple(stations))
        for source_name, stations in stations_by_operator.items()
    )


def _operator_statistics(
    source_name: str,
    stations: tuple[Station, ...],
) -> OperatorStatistics:
    evses = tuple(evse for station in stations for evse in station.evses)
    return OperatorStatistics(
        source_name=source_name,
        normalized_key=_normalized_operator_key(source_name),
        comparison_key=_comparison_operator_key(source_name),
        stations=stations,
        evse_count=len(evses),
        ac_evse_count=sum(evse.current_type == "ac" for evse in evses),
        dc_evse_count=sum(evse.current_type == "dc" for evse in evses),
        hpc_evse_count=sum(
            evse.current_type == "dc" and evse.max_power_kw >= HPC_MINIMUM_POWER_KW
            for evse in evses
        ),
        maximum_power_kw=max((evse.max_power_kw for evse in evses), default=Decimal("0")),
    )


def _normalized_operator_key(value: str) -> str:
    normalized = unicodedata.normalize("NFKC", value).casefold().replace("&", " und ")
    return " ".join(_NON_ALPHANUMERIC.sub(" ", normalized).split())


def _comparison_operator_key(value: str) -> str:
    words = _normalized_operator_key(value).split()
    significant = tuple(word for word in words if word not in _LEGAL_FORM_WORDS)
    return " ".join(significant or words)


def find_operator_candidates(
    metrics: tuple[OperatorStatistics, ...],
    candidate_limit: int,
) -> dict[str, tuple[str, ...]]:
    if candidate_limit == 0:
        return {item.source_name: () for item in metrics}
    blocks: dict[str, list[OperatorStatistics]] = {}
    for item in metrics:
        key = item.comparison_key.replace(" ", "")[:4]
        blocks.setdefault(key, []).append(item)
    result: dict[str, tuple[str, ...]] = {}
    for item in metrics:
        key = item.comparison_key.replace(" ", "")[:4]
        scored = sorted(
            (
                (
                    SequenceMatcher(
                        None,
                        item.comparison_key,
                        candidate.comparison_key,
                    ).ratio(),
                    candidate.source_name,
                )
                for candidate in blocks[key]
                if candidate.source_name != item.source_name
            ),
            key=lambda value: (-value[0], value[1].casefold(), value[1]),
        )
        result[item.source_name] = tuple(name for score, name in scored if score >= 0.72)[
            :candidate_limit
        ]
    return result


def _operator_review_row(
    rank: int,
    item: OperatorStatistics,
    candidates: tuple[str, ...],
) -> dict[str, object]:
    federal_states = sorted(
        {
            station.address.federal_state
            for station in item.stations
            if station.address.federal_state
        }
    )
    cities = sorted({station.address.city for station in item.stations})[:10]
    return {
        "rank_by_evses": rank,
        "operator_source_name": item.source_name,
        "normalized_key": item.normalized_key,
        "comparison_key": item.comparison_key,
        "station_count": len(item.stations),
        "evse_count": item.evse_count,
        "ac_evse_count": item.ac_evse_count,
        "dc_evse_count": item.dc_evse_count,
        "hpc_evse_count": item.hpc_evse_count,
        "maximum_power_kw": str(item.maximum_power_kw),
        "federal_states": "|".join(federal_states),
        "sample_cities": "|".join(cities),
        "similar_source_names": "|".join(candidates),
        "canonical_operator": "",
        "review_status": "unreviewed",
    }
