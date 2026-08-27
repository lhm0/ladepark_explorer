from ladepark_importer.opening_hours import normalize_opening_hours


def test_accepts_unambiguous_bnetza_always_open_values() -> None:
    full_days = "; ".join(["00:00-23:59"] * 7)
    all_days = "; ".join(
        [
            "Montag",
            "Dienstag",
            "Mittwoch",
            "Donnerstag",
            "Freitag",
            "Samstag",
            "Sonntag",
        ]
    )

    assert normalize_opening_hours("247", all_days, full_days).status == "always_open"
    assert normalize_opening_hours("24/7", None, None).status == "always_open"


def test_rejects_restricted_unknown_and_conflicting_values() -> None:
    assert normalize_opening_hours("Eingeschränkt", "Montag", "08:00-20:00").status == (
        "restricted"
    )
    assert normalize_opening_hours("Keine Angabe", None, None).status == "unknown"
    assert normalize_opening_hours(None, None, None).status == "unknown"
    assert normalize_opening_hours("247", "Montag", "00:00-23:59").status == "restricted"
