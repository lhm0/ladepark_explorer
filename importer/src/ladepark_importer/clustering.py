import heapq
import math
from dataclasses import dataclass
from uuid import UUID

from ladepark_importer.errors import DataValidationError
from ladepark_importer.normalization import stable_uuid

EARTH_RADIUS_M = 6_371_008.8
SUPPORTED_DIAMETERS_M = (25, 50, 100, 200, 300)
BOUNDARY_TOLERANCE_M = 1e-7

# Implementiert den Build-Anteil von FR-GROUP-001 und NFR-DATA-001.


@dataclass(frozen=True, slots=True)
class StationPoint:
    station_id: str
    latitude: float
    longitude: float


@dataclass(frozen=True, slots=True)
class ProximityGroup:
    group_id: str
    anchor_station_id: str
    station_ids: tuple[str, ...]
    diameter_m: int
    actual_diameter_m: float
    medoid_station_id: str
    latitude: float
    longitude: float


@dataclass(slots=True)
class _WorkingGroup:
    internal_id: int
    members: tuple[int, ...]
    anchor_station_id: str


def haversine_distance_m(first: StationPoint, second: StationPoint) -> float:
    latitude_1 = math.radians(first.latitude)
    latitude_2 = math.radians(second.latitude)
    latitude_delta = latitude_2 - latitude_1
    longitude_delta = math.radians(second.longitude - first.longitude)
    haversine = (
        math.sin(latitude_delta / 2) ** 2
        + math.cos(latitude_1) * math.cos(latitude_2) * math.sin(longitude_delta / 2) ** 2
    )
    return 2 * EARTH_RADIUS_M * math.asin(min(1.0, math.sqrt(haversine)))


def build_proximity_groups(
    points: tuple[StationPoint, ...],
    dataset_version: str,
    diameter_m: int,
    namespace: UUID,
) -> tuple[ProximityGroup, ...]:
    if diameter_m not in SUPPORTED_DIAMETERS_M:
        raise ValueError(f"Nicht unterstützter Gruppendurchmesser: {diameter_m}")
    ordered_points = tuple(sorted(points, key=lambda point: point.station_id))
    _validate_points(ordered_points)
    if not ordered_points:
        return ()

    neighbors, pair_distances = _candidate_pairs(ordered_points, diameter_m)
    groups: dict[int, _WorkingGroup] = {
        index: _WorkingGroup(index, (index,), point.station_id)
        for index, point in enumerate(ordered_points)
    }
    station_groups = list(range(len(ordered_points)))
    candidates: list[tuple[float, str, str, int, int]] = []
    for (first, second), distance in pair_distances.items():
        heapq.heappush(
            candidates,
            (
                distance,
                ordered_points[first].station_id,
                ordered_points[second].station_id,
                first,
                second,
            ),
        )

    next_group_id = len(groups)
    while candidates:
        _, _, _, first_group_id, second_group_id = heapq.heappop(candidates)
        first_group = groups.get(first_group_id)
        second_group = groups.get(second_group_id)
        if first_group is None or second_group is None:
            continue
        _, maximum_distance = _cross_distances(
            first_group.members, second_group.members, ordered_points
        )
        if maximum_distance > diameter_m + BOUNDARY_TOLERANCE_M:
            continue

        merged_members = tuple(sorted(first_group.members + second_group.members))
        merged_group = _WorkingGroup(
            internal_id=next_group_id,
            members=merged_members,
            anchor_station_id=min(first_group.anchor_station_id, second_group.anchor_station_id),
        )
        del groups[first_group_id]
        del groups[second_group_id]
        groups[next_group_id] = merged_group
        for member in merged_members:
            station_groups[member] = next_group_id

        neighboring_group_ids = {
            station_groups[neighbor]
            for member in merged_members
            for neighbor in neighbors[member]
            if station_groups[neighbor] != next_group_id
        }
        for other_group_id in neighboring_group_ids:
            other_group = groups.get(other_group_id)
            if other_group is None:
                continue
            candidate_distance, _ = _cross_distances(
                merged_group.members, other_group.members, ordered_points
            )
            first_anchor, second_anchor = sorted(
                (merged_group.anchor_station_id, other_group.anchor_station_id)
            )
            heapq.heappush(
                candidates,
                (
                    candidate_distance,
                    first_anchor,
                    second_anchor,
                    merged_group.internal_id,
                    other_group.internal_id,
                ),
            )
        next_group_id += 1

    return tuple(
        sorted(
            (
                _finalize_group(
                    group,
                    ordered_points,
                    dataset_version,
                    diameter_m,
                    namespace,
                )
                for group in groups.values()
            ),
            key=lambda group: group.anchor_station_id,
        )
    )


def _candidate_pairs(
    points: tuple[StationPoint, ...], diameter_m: int
) -> tuple[list[set[int]], dict[tuple[int, int], float]]:
    latitude_cell_degrees = math.degrees(diameter_m / EARTH_RADIUS_M)
    minimum_longitude_scale = min(
        max(math.cos(math.radians(point.latitude)), 0.01) for point in points
    )
    longitude_cell_degrees = latitude_cell_degrees / minimum_longitude_scale
    buckets: dict[tuple[int, int], list[int]] = {}
    neighbors: list[set[int]] = [set() for _ in points]
    distances: dict[tuple[int, int], float] = {}

    for index, point in enumerate(points):
        latitude_cell = math.floor((point.latitude + 90.0) / latitude_cell_degrees)
        longitude_cell = math.floor((point.longitude + 180.0) / longitude_cell_degrees)

        for latitude_offset in (-1, 0, 1):
            for longitude_offset in (-1, 0, 1):
                for other_index in buckets.get(
                    (latitude_cell + latitude_offset, longitude_cell + longitude_offset), ()
                ):
                    distance = haversine_distance_m(points[other_index], point)
                    if distance <= diameter_m + BOUNDARY_TOLERANCE_M:
                        pair = (other_index, index)
                        distances[pair] = distance
                        neighbors[other_index].add(index)
                        neighbors[index].add(other_index)
        buckets.setdefault((latitude_cell, longitude_cell), []).append(index)

    return neighbors, distances


def _cross_distances(
    first_members: tuple[int, ...],
    second_members: tuple[int, ...],
    points: tuple[StationPoint, ...],
) -> tuple[float, float]:
    minimum = math.inf
    maximum = 0.0
    for first in first_members:
        for second in second_members:
            distance = haversine_distance_m(points[first], points[second])
            minimum = min(minimum, distance)
            maximum = max(maximum, distance)
    return minimum, maximum


def _finalize_group(
    group: _WorkingGroup,
    points: tuple[StationPoint, ...],
    dataset_version: str,
    diameter_m: int,
    namespace: UUID,
) -> ProximityGroup:
    station_ids = tuple(sorted(points[index].station_id for index in group.members))
    actual_diameter = 0.0
    distance_sums: dict[int, float] = {member: 0.0 for member in group.members}
    for position, first in enumerate(group.members):
        for second in group.members[position + 1 :]:
            distance = haversine_distance_m(points[first], points[second])
            actual_diameter = max(actual_diameter, distance)
            distance_sums[first] += distance
            distance_sums[second] += distance
    medoid_index = min(
        group.members,
        key=lambda member: (distance_sums[member], points[member].station_id),
    )
    identity_name = f"{dataset_version}:{diameter_m}:{','.join(station_ids)}"
    return ProximityGroup(
        group_id=stable_uuid(namespace, identity_name),
        anchor_station_id=station_ids[0],
        station_ids=station_ids,
        diameter_m=diameter_m,
        actual_diameter_m=actual_diameter,
        medoid_station_id=points[medoid_index].station_id,
        latitude=points[medoid_index].latitude,
        longitude=points[medoid_index].longitude,
    )


def _validate_points(points: tuple[StationPoint, ...]) -> None:
    station_ids: set[str] = set()
    for point in points:
        if point.station_id in station_ids:
            raise DataValidationError(f"Doppelte station_id: {point.station_id}")
        station_ids.add(point.station_id)
        if not math.isfinite(point.latitude) or not -90 <= point.latitude <= 90:
            raise DataValidationError(f"Ungültiger Breitengrad für Station {point.station_id!r}")
        if not math.isfinite(point.longitude) or not -180 <= point.longitude <= 180:
            raise DataValidationError(f"Ungültiger Längengrad für Station {point.station_id!r}")
