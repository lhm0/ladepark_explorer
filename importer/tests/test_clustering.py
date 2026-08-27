import math
import random
from uuid import UUID

import pytest

from ladepark_importer.clustering import (
    EARTH_RADIUS_M,
    ProximityGroup,
    StationPoint,
    build_proximity_groups,
)
from ladepark_importer.errors import DataValidationError

NAMESPACE = UUID("9fee479d-1b03-44a9-b280-a914a3745f53")
DATASET_VERSION = "test-2026-07-07"

# Referenztests PG-001 bis PG-010 für FR-GROUP-001.


def test_pg_001_single_station() -> None:
    point = StationPoint("A", 51.0, 10.0)

    for diameter in (25, 50, 100, 200, 300):
        groups = build_proximity_groups((point,), DATASET_VERSION, diameter, NAMESPACE)
        assert _members(groups) == (("A",),)


def test_pg_002_distance_exactly_on_boundary() -> None:
    points = (_point("A", 0), _point("B", 50))

    assert _members(build_proximity_groups(points, DATASET_VERSION, 50, NAMESPACE)) == (("A", "B"),)
    assert _members(build_proximity_groups(points, DATASET_VERSION, 25, NAMESPACE)) == (
        ("A",),
        ("B",),
    )


def test_pg_003_distance_just_above_boundary() -> None:
    points = (_point("A", 0), _point("B", 50.01))

    assert _members(build_proximity_groups(points, DATASET_VERSION, 50, NAMESPACE)) == (
        ("A",),
        ("B",),
    )


def test_pg_004_chain_does_not_exceed_diameter() -> None:
    points = (_point("A", 0), _point("B", 40), _point("C", 80))

    assert _members(build_proximity_groups(points, DATASET_VERSION, 50, NAMESPACE)) == (
        ("A", "B"),
        ("C",),
    )


def test_pg_005_tie_is_resolved_by_station_id() -> None:
    points = (_point("C", 100), _point("B", 50), _point("A", 0))

    assert _members(build_proximity_groups(points, DATASET_VERSION, 50, NAMESPACE)) == (
        ("A", "B"),
        ("C",),
    )


def test_pg_006_operator_is_not_an_input() -> None:
    points = (_point("operator-one", 0), _point("operator-two", 20))

    assert len(build_proximity_groups(points, DATASET_VERSION, 25, NAMESPACE)) == 1


def test_pg_007_street_is_not_an_input() -> None:
    points = (_point("north-side", 0), _point("south-side", 20))

    assert len(build_proximity_groups(points, DATASET_VERSION, 25, NAMESPACE)) == 1


def test_pg_008_diameter_change_changes_membership() -> None:
    points = (_point("A", 0), _point("B", 40), _point("C", 240))

    assert len(build_proximity_groups(points, DATASET_VERSION, 25, NAMESPACE)) == 3
    assert _members(build_proximity_groups(points, DATASET_VERSION, 50, NAMESPACE)) == (
        ("A", "B"),
        ("C",),
    )
    assert _members(build_proximity_groups(points, DATASET_VERSION, 300, NAMESPACE)) == (
        ("A", "B", "C"),
    )


def test_pg_009_dataset_update_changes_group_id_but_preserves_anchor() -> None:
    initial = build_proximity_groups(
        (_point("A", 0), _point("B", 20)), DATASET_VERSION, 50, NAMESPACE
    )[0]
    updated = build_proximity_groups(
        (_point("A", 0), _point("B", 20), _point("C", 30)),
        "test-2026-08-01",
        50,
        NAMESPACE,
    )[0]

    assert initial.group_id != updated.group_id
    assert initial.anchor_station_id == updated.anchor_station_id == "A"


def test_pg_010_invalid_coordinate_is_rejected() -> None:
    with pytest.raises(DataValidationError, match="Breitengrad"):
        build_proximity_groups(
            (StationPoint("A", math.nan, 10.0),),
            DATASET_VERSION,
            50,
            NAMESPACE,
        )


def test_medoid_uses_smallest_station_id_on_tie() -> None:
    group = build_proximity_groups(
        (_point("B", 0), _point("A", 20)), DATASET_VERSION, 50, NAMESPACE
    )[0]

    assert group.anchor_station_id == "A"
    assert group.medoid_station_id == "A"


def test_group_id_is_deterministic() -> None:
    points = (_point("B", 20), _point("A", 0))

    first = build_proximity_groups(points, DATASET_VERSION, 50, NAMESPACE)
    second = build_proximity_groups(tuple(reversed(points)), DATASET_VERSION, 50, NAMESPACE)

    assert first == second


def test_spatial_candidate_search_matches_naive_reference() -> None:
    randomizer = random.Random(20260726)
    points = tuple(
        StationPoint(
            f"S{index:02d}",
            51.0 + randomizer.uniform(-0.003, 0.003),
            10.0 + randomizer.uniform(-0.005, 0.005),
        )
        for index in range(20)
    )

    for diameter in (25, 50, 100, 200, 300):
        optimized = _members(build_proximity_groups(points, DATASET_VERSION, diameter, NAMESPACE))
        assert optimized == _naive_members(points, diameter)


def _point(station_id: str, north_m: float) -> StationPoint:
    latitude = math.degrees(north_m / EARTH_RADIUS_M)
    return StationPoint(station_id, latitude, 10.0)


def _members(groups: tuple[ProximityGroup, ...]) -> tuple[tuple[str, ...], ...]:
    return tuple(group.station_ids for group in groups)


def _naive_members(
    points: tuple[StationPoint, ...], diameter_m: int
) -> tuple[tuple[str, ...], ...]:
    from ladepark_importer.clustering import haversine_distance_m

    ordered = tuple(sorted(points, key=lambda point: point.station_id))
    groups: list[tuple[int, ...]] = [(index,) for index in range(len(ordered))]
    while True:
        candidates: list[tuple[float, str, str, int, int]] = []
        for first_index, first in enumerate(groups):
            for second_index in range(first_index + 1, len(groups)):
                second = groups[second_index]
                distances = [
                    haversine_distance_m(ordered[a], ordered[b]) for a in first for b in second
                ]
                if max(distances) <= diameter_m + 1e-7:
                    candidates.append(
                        (
                            min(distances),
                            ordered[min(first)].station_id,
                            ordered[min(second)].station_id,
                            first_index,
                            second_index,
                        )
                    )
        if not candidates:
            break
        *_, first_index, second_index = min(candidates)
        groups[first_index] = tuple(sorted(groups[first_index] + groups[second_index]))
        del groups[second_index]
    return tuple(
        sorted(
            (tuple(ordered[index].station_id for index in group) for group in groups),
            key=lambda members: members[0],
        )
    )
