import hashlib
import json
from dataclasses import asdict, dataclass
from decimal import Decimal
from pathlib import Path

from ladepark_importer.errors import DataValidationError
from ladepark_importer.normalization import (
    normalize_text,
    parse_coordinate,
    parse_positive_int,
)
from ladepark_importer.schema import STATION_ID_COLUMN, inspect_schema
from ladepark_importer.source import open_source


@dataclass(frozen=True, slots=True)
class InspectionReport:
    source_path: str
    source_format: str
    sha256: str
    row_count: int
    station_count: int
    evse_slot_count: int
    slot_numbers: tuple[int, ...]
    unknown_columns: tuple[str, ...]
    warnings: tuple[str, ...]

    def to_json(self) -> str:
        return json.dumps(asdict(self), ensure_ascii=False, indent=2, sort_keys=True)


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def inspect_file(path: Path) -> InspectionReport:
    source = open_source(path)
    schema = inspect_schema(source.headers)
    station_ids: set[str] = set()
    row_count = 0
    evse_slot_count = 0
    warnings: list[str] = []

    for row_number, row in enumerate(source.rows(), start=1):
        row_count += 1
        external_id = normalize_text(row.get(STATION_ID_COLUMN))
        if external_id is None:
            raise DataValidationError(f"Zeile {row_number}: Ladeeinrichtungs-ID fehlt")
        if external_id in station_ids:
            raise DataValidationError(
                f"Zeile {row_number}: doppelte Ladeeinrichtungs-ID {external_id!r}"
            )
        station_ids.add(external_id)

        parse_coordinate(
            row.get("Breitengrad"),
            f"Zeile {row_number} Breitengrad",
            Decimal("-90"),
            Decimal("90"),
        )
        parse_coordinate(
            row.get("Längengrad"),
            f"Zeile {row_number} Längengrad",
            Decimal("-180"),
            Decimal("180"),
        )
        declared_points = parse_positive_int(
            row.get("Anzahl Ladepunkte"), f"Zeile {row_number} Anzahl Ladepunkte"
        )
        populated_slots = sum(
            normalize_text(row.get(f"Steckertypen{slot}")) is not None
            for slot in schema.slot_numbers
        )
        evse_slot_count += populated_slots
        if declared_points != populated_slots:
            warnings.append(
                f"Zeile {row_number}: Anzahl Ladepunkte={declared_points}, "
                f"belegte Slots={populated_slots}"
            )

    return InspectionReport(
        source_path=str(path),
        source_format=path.suffix.lower().removeprefix("."),
        sha256=_sha256(path),
        row_count=row_count,
        station_count=len(station_ids),
        evse_slot_count=evse_slot_count,
        slot_numbers=schema.slot_numbers,
        unknown_columns=schema.unknown_columns,
        warnings=tuple(warnings),
    )
