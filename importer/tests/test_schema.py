import pytest

from ladepark_importer.errors import SchemaError
from ladepark_importer.schema import inspect_schema


def test_schema_detects_slots_and_unknown_columns() -> None:
    schema = inspect_schema(
        (
            "Ladeeinrichtungs-ID",
            "Betreiber",
            "Status",
            "Anzahl Ladepunkte",
            "Straße",
            "Hausnummer",
            "Postleitzahl",
            "Ort",
            "Breitengrad",
            "Längengrad",
            "Steckertypen1",
            "Nennleistung Stecker1",
            "Neue Quellspalte",
        )
    )

    assert schema.slot_numbers == (1,)
    assert schema.unknown_columns == ("Neue Quellspalte",)


def test_schema_rejects_missing_required_column() -> None:
    with pytest.raises(SchemaError, match="Fehlende Pflichtspalten"):
        inspect_schema(("Ladeeinrichtungs-ID", "Steckertypen1", "Nennleistung Stecker1"))


def test_schema_rejects_incomplete_slot() -> None:
    headers = (
        "Ladeeinrichtungs-ID",
        "Betreiber",
        "Status",
        "Anzahl Ladepunkte",
        "Straße",
        "Hausnummer",
        "Postleitzahl",
        "Ort",
        "Breitengrad",
        "Längengrad",
        "Steckertypen1",
    )

    with pytest.raises(SchemaError, match="Unvollständiger Ladepunkt-Slot"):
        inspect_schema(headers)
