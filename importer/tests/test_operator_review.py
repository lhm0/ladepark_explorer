import csv
from dataclasses import replace
from pathlib import Path

from ladepark_importer.configuration import load_connector_types, load_namespaces
from ladepark_importer.models import NormalizedSnapshot
from ladepark_importer.review import export_operator_review_csv
from ladepark_importer.transformation import normalize_file

FIXTURE = Path(__file__).parent / "fixtures" / "bnetza_minimal.csv"
PROJECT_DIRECTORY = Path(__file__).resolve().parents[1]


def test_operator_review_suggests_only_candidates_without_merging(tmp_path: Path) -> None:
    snapshot = normalize_file(
        FIXTURE,
        load_namespaces(PROJECT_DIRECTORY / "config" / "namespaces.json"),
        load_connector_types(PROJECT_DIRECTORY / "config" / "connector_types.json"),
    )
    stations = (
        replace(snapshot.stations[0], operator_source_name="Beispiel Energie GmbH"),
        replace(snapshot.stations[1], operator_source_name="Beispiel Energie GMBH"),
    )
    output = tmp_path / "operators.csv"

    export_operator_review_csv(output, NormalizedSnapshot(stations, ()), candidate_limit=2)

    with output.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    assert len(rows) == 2
    candidates = {row["operator_source_name"]: row["similar_source_names"] for row in rows}
    assert candidates == {
        "Beispiel Energie GmbH": "Beispiel Energie GMBH",
        "Beispiel Energie GMBH": "Beispiel Energie GmbH",
    }
    assert all(row["canonical_operator"] == "" for row in rows)
    assert all(row["review_status"] == "unreviewed" for row in rows)


def test_operator_review_is_deterministic(tmp_path: Path) -> None:
    snapshot = normalize_file(
        FIXTURE,
        load_namespaces(PROJECT_DIRECTORY / "config" / "namespaces.json"),
        load_connector_types(PROJECT_DIRECTORY / "config" / "connector_types.json"),
    )
    first = tmp_path / "first.csv"
    second = tmp_path / "second.csv"

    export_operator_review_csv(first, snapshot)
    export_operator_review_csv(second, snapshot)

    assert first.read_bytes() == second.read_bytes()
