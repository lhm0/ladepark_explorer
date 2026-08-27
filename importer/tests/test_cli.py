import csv
import json
from pathlib import Path

import pytest

from ladepark_importer.cli import main

FIXTURE = Path(__file__).parent / "fixtures" / "bnetza_minimal.csv"


def test_normalize_command_outputs_json(capsys: pytest.CaptureFixture[str]) -> None:
    exit_code = main(["normalize", str(FIXTURE)])

    assert exit_code == 0
    output = json.loads(capsys.readouterr().out)
    assert len(output["stations"]) == 2
    assert output["warnings"] == []


def test_report_command_outputs_compact_summary(
    capsys: pytest.CaptureFixture[str],
) -> None:
    exit_code = main(["report", str(FIXTURE)])

    assert exit_code == 0
    output = json.loads(capsys.readouterr().out)
    assert output["station_count"] == 2
    assert output["evse_count"] == 3
    assert output["connector_count"] == 3
    assert output["connector_types"] == {"ccs": 2, "type_2": 1}
    assert output["unknown_connector_types"] == {}
    assert output["operators_without_registry"] == 2


def test_cluster_report_command_outputs_group_summary(
    capsys: pytest.CaptureFixture[str],
) -> None:
    exit_code = main(
        [
            "cluster-report",
            str(FIXTURE),
            "--dataset-version",
            "test-2026-07-07",
            "--diameter",
            "50",
        ]
    )

    assert exit_code == 0
    output = json.loads(capsys.readouterr().out)
    assert output["diameter_m"] == 50
    assert output["group_count"] == 2
    assert output["singleton_group_count"] == 2
    assert len(output["membership_sha256"]) == 64


def test_cluster_review_command_writes_csv(
    capsys: pytest.CaptureFixture[str], tmp_path: Path
) -> None:
    output_path = tmp_path / "review" / "groups.csv"
    exit_code = main(
        [
            "cluster-review",
            str(FIXTURE),
            "--output",
            str(output_path),
            "--dataset-version",
            "test-2026-07-07",
            "--diameter",
            "50",
            "--limit-per-category",
            "1",
        ]
    )

    assert exit_code == 0
    result = json.loads(capsys.readouterr().out)
    assert result["output_path"] == str(output_path)
    with output_path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    assert 1 <= len(rows) <= 2
    assert rows[0]["hpc_evse_count"] == "2"
    assert rows[0]["connector_types"] == "ccs"
    assert rows[0]["source_station_ids"] == "DE-BNA-0001"


def test_operator_review_command_writes_ranked_csv(
    capsys: pytest.CaptureFixture[str], tmp_path: Path
) -> None:
    output_path = tmp_path / "review" / "operators.csv"
    exit_code = main(
        [
            "operator-review",
            str(FIXTURE),
            "--output",
            str(output_path),
            "--candidate-limit",
            "3",
        ]
    )

    assert exit_code == 0
    result = json.loads(capsys.readouterr().out)
    assert result == {
        "candidate_limit": 3,
        "operator_count": 2,
        "output_path": str(output_path),
    }
    with output_path.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    assert [row["rank_by_evses"] for row in rows] == ["1", "2"]
    assert rows[0]["operator_source_name"] == "Beispiel Energie GmbH"
    assert rows[0]["comparison_key"] == "beispiel energie"
    assert rows[0]["station_count"] == "1"
    assert rows[0]["evse_count"] == "2"
    assert rows[0]["dc_evse_count"] == "2"
    assert rows[0]["hpc_evse_count"] == "2"
    assert rows[0]["review_status"] == "unreviewed"


def test_operator_worklist_registry_and_coverage_commands(
    capsys: pytest.CaptureFixture[str], tmp_path: Path
) -> None:
    worklist = tmp_path / "operator-worklist.csv"
    assert (
        main(
            [
                "operator-worklist",
                str(FIXTURE),
                "--output",
                str(worklist),
                "--top",
                "1",
            ]
        )
        == 0
    )
    worklist_result = json.loads(capsys.readouterr().out)
    assert worklist_result["requested_top"] == 1
    assert worklist_result["source_name_count"] == 1
    with worklist.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.DictReader(handle, delimiter=";"))
    assert rows[0]["selection_reason"] == "top"
    assert rows[0]["decision"] == ""
    assert rows[0]["review_status"] == "unreviewed"

    registry = tmp_path / "operators.json"
    registry.write_text(
        json.dumps(
            {
                "version": 1,
                "operators": [
                    {
                        "registry_key": "example-energy",
                        "canonical_name": "Beispiel Energie GmbH",
                        "display_name": "Beispiel Energie",
                        "status": "reviewed",
                        "aliases": ["Beispiel Energie GmbH"],
                        "reviewed_at": "2026-08-24",
                        "rationale": "Testentscheidung",
                    }
                ],
            },
            ensure_ascii=False,
        ),
        encoding="utf-8",
    )
    assert (
        main(
            [
                "operator-registry-validate",
                str(FIXTURE),
                "--registry",
                str(registry),
            ]
        )
        == 0
    )
    validation = json.loads(capsys.readouterr().out)
    assert validation["operator_count"] == 1
    assert validation["alias_count"] == 1

    assert (
        main(
            [
                "operator-coverage",
                str(FIXTURE),
                "--registry",
                str(registry),
            ]
        )
        == 0
    )
    coverage = json.loads(capsys.readouterr().out)
    assert coverage["canonical_operator_count"] == 1
    assert coverage["covered_evse_count"] == 2
    assert coverage["total_evse_count"] == 3
    assert coverage["covered_evse_percent"] == 66.67


def test_build_and_validate_sqlite_commands(
    capsys: pytest.CaptureFixture[str], tmp_path: Path
) -> None:
    output_path = tmp_path / "charging.sqlite3"
    build_exit_code = main(
        [
            "build-sqlite",
            str(FIXTURE),
            "--output",
            str(output_path),
            "--dataset-version",
            "2026.07.0-test",
            "--source-version",
            "2026-07-07-test",
            "--created-at",
            "2026-07-26T12:00:00Z",
            "--operators",
            str(Path(__file__).parent / "fixtures" / "operators_empty.json"),
        ]
    )

    assert build_exit_code == 0
    build_result = json.loads(capsys.readouterr().out)
    assert build_result["station_count"] == 2
    assert build_result["diameter_count"] == 5
    assert output_path.exists()

    validate_exit_code = main(["validate-sqlite", str(output_path)])

    assert validate_exit_code == 0
    validate_result = json.loads(capsys.readouterr().out)
    assert validate_result == build_result

    query_exit_code = main(
        [
            "query-sqlite",
            str(output_path),
            "--diameter",
            "50",
            "--min-power",
            "100",
            "--limit",
            "1",
        ]
    )

    assert query_exit_code == 0
    query_result = json.loads(capsys.readouterr().out)
    assert query_result["returned_count"] == 1
    assert query_result["groups"][0]["city"] == "Berlin"

    detail_exit_code = main(
        [
            "group-detail",
            str(output_path),
            query_result["groups"][0]["group_id"],
        ]
    )

    assert detail_exit_code == 0
    detail_result = json.loads(capsys.readouterr().out)
    assert detail_result["group"]["city"] == "Berlin"
