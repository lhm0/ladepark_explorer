import json
import sqlite3
from pathlib import Path

import pytest

from ladepark_importer.cli import main
from ladepark_importer.errors import ImporterError
from ladepark_importer.park_info import build_park_info_sqlite

PROJECT = Path(__file__).parents[2]
SOURCE = Path(__file__).parent / "fixtures" / "park_info_minimal.json"
CHARGING = PROJECT / "app/assets/datasets/charging-2026.07.0-contract.sqlite3"


def test_builds_reproducible_reviewed_park_info(tmp_path: Path) -> None:
    first = tmp_path / "first.sqlite3"
    second = tmp_path / "second.sqlite3"
    first_result = build_park_info_sqlite(SOURCE, tmp_path, CHARGING, first, tmp_path / "m1")
    second_result = build_park_info_sqlite(SOURCE, tmp_path, CHARGING, second, tmp_path / "m2")

    assert first_result.sha256 == second_result.sha256
    with sqlite3.connect(first) as connection:
        assert connection.execute("PRAGMA user_version").fetchone() == (1,)
        assert connection.execute("SELECT COUNT(*) FROM amenity").fetchone() == (5,)
        assert connection.execute(
            "SELECT state FROM amenity WHERE amenity_type = 'shop'"
        ).fetchone() == ("absent",)


def test_rejects_unknown_station(tmp_path: Path) -> None:
    document = json.loads(SOURCE.read_text(encoding="utf-8"))
    document["parks"][0]["station_ids"] = ["unknown"]
    source = tmp_path / "invalid.json"
    source.write_text(json.dumps(document), encoding="utf-8")
    with pytest.raises(ImporterError, match="Unbekannte Stations-IDs"):
        build_park_info_sqlite(source, tmp_path, CHARGING, tmp_path / "out.db", tmp_path / "media")


def test_cli_build_and_validate(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    database = tmp_path / "park-info.sqlite3"
    assert (
        main(
            [
                "build-park-info",
                str(SOURCE),
                "--media",
                str(tmp_path),
                "--charging-database",
                str(CHARGING),
                "--output",
                str(database),
                "--media-output",
                str(tmp_path / "media"),
            ]
        )
        == 0
    )
    assert json.loads(capsys.readouterr().out)["park_count"] == 1
    assert main(["validate-park-info", str(database)]) == 0
