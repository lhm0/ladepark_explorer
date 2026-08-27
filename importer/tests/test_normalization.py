from decimal import Decimal
from uuid import UUID

import pytest

from ladepark_importer.errors import DataValidationError
from ladepark_importer.normalization import (
    normalize_text,
    parse_coordinate,
    parse_nonnegative_decimal,
    parse_positive_int,
    require_text,
    stable_uuid,
)
from ladepark_importer.transformation import _canonical_evse_id


def test_normalize_text_collapses_whitespace_and_placeholders() -> None:
    assert normalize_text("  Test   Wert ") == "Test Wert"
    assert normalize_text(" - ") is None
    assert normalize_text("Cafe\u0301") == "Café"


def test_require_text_rejects_placeholder() -> None:
    with pytest.raises(DataValidationError, match="Wert fehlt"):
        require_text("-", "Betreiber")


def test_parse_decimal_comma_coordinate() -> None:
    assert parse_coordinate("52,52", "latitude", Decimal("-90"), Decimal("90")) == Decimal("52.52")


def test_parse_coordinate_rejects_out_of_range() -> None:
    with pytest.raises(DataValidationError, match="außerhalb"):
        parse_coordinate("91", "latitude", Decimal("-90"), Decimal("90"))


def test_parse_positive_int_rejects_fraction() -> None:
    with pytest.raises(DataValidationError, match="positive Ganzzahl"):
        parse_positive_int("1,5", "count")


def test_parse_nonnegative_decimal_rejects_negative_value() -> None:
    with pytest.raises(DataValidationError, match="nichtnegative"):
        parse_nonnegative_decimal("-1", "power")


def test_stable_uuid_is_deterministic() -> None:
    namespace = UUID("2cdffb3a-b252-45e9-b61d-ec1e7711e202")
    assert stable_uuid(namespace, "bnetza:example") == stable_uuid(namespace, "bnetza:example")


@pytest.mark.parametrize(
    ("source", "canonical"),
    [
        ("DE*ABC*E123*1", "DE*ABC*E123*1"),
        ("DEABCE123", "DE*ABC*E123"),
        ("DE-ABC-E123", "DE*ABC*E123"),
        ("DE.ABC.E123", "DE*ABC*E123"),
    ],
)
def test_evse_id_variants_are_canonicalized(source: str, canonical: str) -> None:
    assert _canonical_evse_id(source) == canonical
