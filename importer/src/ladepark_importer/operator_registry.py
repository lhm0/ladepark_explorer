import csv
import hashlib
import json
from dataclasses import asdict, dataclass
from datetime import date
from pathlib import Path
from typing import Any
from uuid import UUID

from ladepark_importer.errors import ImporterError
from ladepark_importer.models import NormalizedSnapshot
from ladepark_importer.normalization import stable_uuid
from ladepark_importer.review import (
    OperatorStatistics,
    build_operator_statistics,
    find_operator_candidates,
)

WORKLIST_FIELD_NAMES = (
    "selection_reason",
    "rank_by_evses",
    "operator_source_name",
    "station_count",
    "evse_count",
    "dc_evse_count",
    "hpc_evse_count",
    "similar_source_names",
    "decision",
    "canonical_registry_key",
    "canonical_name",
    "display_name",
    "rationale",
    "review_status",
)


@dataclass(frozen=True, slots=True)
class OperatorRegistryEntry:
    registry_key: str
    operator_id: str
    canonical_name: str
    display_name: str
    aliases: tuple[str, ...]
    reviewed_at: str
    rationale: str


@dataclass(frozen=True, slots=True)
class OperatorRegistry:
    version: int
    operators: tuple[OperatorRegistryEntry, ...]

    @property
    def aliases(self) -> dict[str, OperatorRegistryEntry]:
        return {alias: operator for operator in self.operators for alias in operator.aliases}


@dataclass(frozen=True, slots=True)
class OperatorWorklistResult:
    output_path: str
    requested_top: int
    source_name_count: int
    included_candidate_count: int

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


@dataclass(frozen=True, slots=True)
class OperatorRegistryValidationResult:
    registry_path: str
    version: int
    operator_count: int
    alias_count: int
    registry_sha256: str

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


def load_operator_registry(
    path: Path,
    operator_namespace: UUID,
    known_source_names: set[str] | None = None,
) -> OperatorRegistry:
    try:
        raw: Any = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ImporterError(f"Betreiberregister kann nicht gelesen werden: {error}") from error
    if not isinstance(raw, dict) or raw.get("version") != 1:
        raise ImporterError("Betreiberregister benötigt die Version 1.")
    raw_operators = raw.get("operators")
    if not isinstance(raw_operators, list):
        raise ImporterError("Betreiberregister benötigt eine Operatorliste.")
    entries: list[OperatorRegistryEntry] = []
    registry_keys: set[str] = set()
    aliases: set[str] = set()
    for index, value in enumerate(raw_operators, 1):
        if not isinstance(value, dict):
            raise ImporterError(f"Betreiberregistereintrag {index} ist ungültig.")
        registry_key = _required_text(value, "registry_key", index)
        canonical_name = _required_text(value, "canonical_name", index)
        display_name = _required_text(value, "display_name", index)
        status = _required_text(value, "status", index)
        rationale = _required_text(value, "rationale", index)
        reviewed_at = _required_text(value, "reviewed_at", index)
        raw_aliases = value.get("aliases")
        if status != "reviewed":
            raise ImporterError(f"Betreiberregistereintrag {index} ist nicht reviewed.")
        try:
            date.fromisoformat(reviewed_at)
        except ValueError as error:
            raise ImporterError(
                f"Betreiberregistereintrag {index} hat ein ungültiges reviewed_at."
            ) from error
        if not isinstance(raw_aliases, list) or not raw_aliases:
            raise ImporterError(f"Betreiberregistereintrag {index} benötigt Aliase.")
        entry_aliases = tuple(_non_empty_string(alias, "Alias", index) for alias in raw_aliases)
        if registry_key in registry_keys:
            raise ImporterError(f"Doppelter registry_key: {registry_key}")
        duplicate_aliases = aliases.intersection(entry_aliases)
        if duplicate_aliases:
            raise ImporterError(f"Alias mehrfach zugeordnet: {sorted(duplicate_aliases)[0]}")
        if len(set(entry_aliases)) != len(entry_aliases):
            raise ImporterError(f"Alias in {registry_key} doppelt aufgeführt.")
        if known_source_names is not None:
            unknown = set(entry_aliases).difference(known_source_names)
            if unknown:
                raise ImporterError(f"Unbekannter BNetzA-Alias: {sorted(unknown)[0]}")
        registry_keys.add(registry_key)
        aliases.update(entry_aliases)
        entries.append(
            OperatorRegistryEntry(
                registry_key=registry_key,
                operator_id=stable_uuid(operator_namespace, f"operator:{registry_key}"),
                canonical_name=canonical_name,
                display_name=display_name,
                aliases=entry_aliases,
                reviewed_at=reviewed_at,
                rationale=rationale,
            )
        )
    return OperatorRegistry(version=1, operators=tuple(entries))


def validate_operator_registry(
    path: Path,
    snapshot: NormalizedSnapshot,
    operator_namespace: UUID,
) -> OperatorRegistryValidationResult:
    known_names = {station.operator_source_name for station in snapshot.stations}
    registry = load_operator_registry(path, operator_namespace, known_names)
    return OperatorRegistryValidationResult(
        registry_path=str(path),
        version=registry.version,
        operator_count=len(registry.operators),
        alias_count=len(registry.aliases),
        registry_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
    )


def export_operator_worklist_csv(
    output_path: Path,
    snapshot: NormalizedSnapshot,
    top: int = 20,
    candidate_limit: int = 5,
) -> OperatorWorklistResult:
    if top < 1 or candidate_limit < 0:
        raise ValueError("top muss positiv und candidate_limit darf nicht negativ sein")
    statistics = build_operator_statistics(snapshot)
    ordered = _ordered_statistics(statistics)
    rank_by_name = {item.source_name: rank for rank, item in enumerate(ordered, 1)}
    candidates = find_operator_candidates(statistics, candidate_limit)
    top_names = {item.source_name for item in ordered[:top]}
    candidate_names = {
        candidate for source_name in top_names for candidate in candidates[source_name]
    }.difference(top_names)
    selected_names = top_names | candidate_names
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=WORKLIST_FIELD_NAMES, delimiter=";")
        writer.writeheader()
        for item in ordered:
            if item.source_name not in selected_names:
                continue
            writer.writerow(
                {
                    "selection_reason": "top" if item.source_name in top_names else "candidate",
                    "rank_by_evses": rank_by_name[item.source_name],
                    "operator_source_name": item.source_name,
                    "station_count": len(item.stations),
                    "evse_count": item.evse_count,
                    "dc_evse_count": item.dc_evse_count,
                    "hpc_evse_count": item.hpc_evse_count,
                    "similar_source_names": "|".join(candidates[item.source_name]),
                    "decision": "",
                    "canonical_registry_key": "",
                    "canonical_name": "",
                    "display_name": "",
                    "rationale": "",
                    "review_status": "unreviewed",
                }
            )
    return OperatorWorklistResult(
        output_path=str(output_path),
        requested_top=top,
        source_name_count=len(selected_names),
        included_candidate_count=len(candidate_names),
    )


def build_operator_coverage_report(
    snapshot: NormalizedSnapshot,
    registry: OperatorRegistry,
) -> dict[str, object]:
    statistics = build_operator_statistics(snapshot)
    by_name = {item.source_name: item for item in statistics}
    total_evses = sum(item.evse_count for item in statistics)
    covered_names = set(registry.aliases).intersection(by_name)
    covered_evses = sum(by_name[name].evse_count for name in covered_names)
    covered_stations = sum(len(by_name[name].stations) for name in covered_names)
    operator_rows = []
    for operator in registry.operators:
        matched = [by_name[alias] for alias in operator.aliases if alias in by_name]
        operator_rows.append(
            {
                "registry_key": operator.registry_key,
                "operator_id": operator.operator_id,
                "display_name": operator.display_name,
                "source_name_count": len(matched),
                "station_count": sum(len(item.stations) for item in matched),
                "evse_count": sum(item.evse_count for item in matched),
            }
        )
    operator_rows.sort(key=_coverage_sort_key)
    return {
        "registry_version": registry.version,
        "canonical_operator_count": len(registry.operators),
        "mapped_source_name_count": len(covered_names),
        "unmapped_source_name_count": len(statistics) - len(covered_names),
        "covered_station_count": covered_stations,
        "covered_evse_count": covered_evses,
        "total_evse_count": total_evses,
        "covered_evse_percent": round(covered_evses * 100 / total_evses, 2),
        "operators": operator_rows,
    }


def _ordered_statistics(
    statistics: tuple[OperatorStatistics, ...],
) -> list[OperatorStatistics]:
    return sorted(
        statistics,
        key=lambda item: (
            -item.evse_count,
            -item.hpc_evse_count,
            -len(item.stations),
            item.source_name.casefold(),
            item.source_name,
        ),
    )


def _coverage_sort_key(row: dict[str, object]) -> tuple[int, str]:
    evse_count = row["evse_count"]
    registry_key = row["registry_key"]
    if not isinstance(evse_count, int) or not isinstance(registry_key, str):
        raise TypeError("Ungültige interne Betreiberabdeckung")
    return -evse_count, registry_key


def _required_text(value: dict[str, Any], key: str, index: int) -> str:
    return _non_empty_string(value.get(key), key, index)


def _non_empty_string(value: Any, name: str, index: int) -> str:
    if not isinstance(value, str) or not value.strip() or value != value.strip():
        raise ImporterError(f"Betreiberregistereintrag {index}: {name} ist ungültig.")
    return value
