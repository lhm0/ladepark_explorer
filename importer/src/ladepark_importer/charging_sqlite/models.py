"""Value objects shared by the charging SQLite modules."""

from dataclasses import dataclass


@dataclass(frozen=True, slots=True)
class SqliteBuildMetadata:
    dataset_id: str
    dataset_version: str
    source_version: str
    created_at: str
    pipeline_version: str
    region: str = "DE"
    license_summary: str = "CC BY 4.0; attribution: Bundesnetzagentur.de"


@dataclass(frozen=True, slots=True)
class SqliteValidationResult:
    station_count: int
    evse_count: int
    connector_count: int
    group_count: int
    group_member_count: int
    diameter_count: int
