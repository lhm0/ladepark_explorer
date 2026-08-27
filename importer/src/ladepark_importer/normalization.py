from decimal import Decimal, InvalidOperation
from unicodedata import normalize
from uuid import UUID, uuid5

from ladepark_importer.errors import DataValidationError


def normalize_text(value: object) -> str | None:
    if value is None:
        return None
    normalized = normalize("NFC", " ".join(str(value).strip().split()))
    if not normalized or normalized.lower() in {"-", "n/a", "null"}:
        return None
    return normalized


def require_text(value: object, field_name: str) -> str:
    normalized = normalize_text(value)
    if normalized is None:
        raise DataValidationError(f"{field_name}: Wert fehlt")
    return normalized


def parse_decimal(value: object, field_name: str) -> Decimal:
    normalized = normalize_text(value)
    if normalized is None:
        raise DataValidationError(f"{field_name}: Wert fehlt")
    candidate = normalized.replace(".", "").replace(",", ".") if "," in normalized else normalized
    try:
        result = Decimal(candidate)
    except InvalidOperation as error:
        raise DataValidationError(f"{field_name}: ungültige Zahl {normalized!r}") from error
    return result


def parse_nonnegative_decimal(value: object, field_name: str) -> Decimal:
    number = parse_decimal(value, field_name)
    if number < 0:
        raise DataValidationError(f"{field_name}: nichtnegative Zahl erwartet")
    return number


def parse_positive_int(value: object, field_name: str) -> int:
    number = parse_decimal(value, field_name)
    if number != number.to_integral_value() or number < 1:
        raise DataValidationError(f"{field_name}: positive Ganzzahl erwartet")
    return int(number)


def parse_coordinate(value: object, field_name: str, minimum: Decimal, maximum: Decimal) -> Decimal:
    coordinate = parse_decimal(value, field_name)
    if coordinate < minimum or coordinate > maximum:
        raise DataValidationError(
            f"{field_name}: {coordinate} liegt außerhalb [{minimum}, {maximum}]"
        )
    return coordinate


def stable_uuid(namespace: UUID, name: str) -> str:
    return str(uuid5(namespace, name))
