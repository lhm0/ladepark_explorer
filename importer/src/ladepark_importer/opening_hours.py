"""Conservative BNetzA opening-hours normalization for FR-FILTER-001."""

from dataclasses import dataclass

_ALL_DAYS = (
    "Montag",
    "Dienstag",
    "Mittwoch",
    "Donnerstag",
    "Freitag",
    "Samstag",
    "Sonntag",
)
_FULL_DAY_INTERVALS = {"00:00-23:59", "00:00-24:00", "00:00-00:00"}


@dataclass(frozen=True, slots=True)
class NormalizedOpeningHours:
    status: str
    raw: str | None
    weekdays_raw: str | None
    times_raw: str | None


def normalize_opening_hours(
    raw: str | None,
    weekdays_raw: str | None,
    times_raw: str | None,
) -> NormalizedOpeningHours:
    """Return always_open only for an unambiguous non-conflicting 24/7 value."""
    raw = _clean(raw)
    weekdays_raw = _clean(weekdays_raw)
    times_raw = _clean(times_raw)
    marker = (raw or "").casefold().replace(" ", "")
    if marker in {"247", "24/7"} and _supports_always_open(weekdays_raw, times_raw):
        status = "always_open"
    elif not raw or raw.casefold() == "keine angabe":
        status = "unknown"
    else:
        status = "restricted"
    return NormalizedOpeningHours(status, raw, weekdays_raw, times_raw)


def _supports_always_open(weekdays_raw: str | None, times_raw: str | None) -> bool:
    if weekdays_raw is None and times_raw is None:
        return True
    if weekdays_raw is None or times_raw is None:
        return False
    days = tuple(part.strip() for part in weekdays_raw.split(";") if part.strip())
    intervals = tuple(part.strip() for part in times_raw.split(";") if part.strip())
    return (
        days == _ALL_DAYS
        and len(intervals) == 7
        and all(interval in _FULL_DAY_INTERVALS for interval in intervals)
    )


def _clean(value: str | None) -> str | None:
    value = value.strip() if value else ""
    return value or None
