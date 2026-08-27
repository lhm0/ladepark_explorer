import csv
from pathlib import Path

from openpyxl import Workbook

from ladepark_importer.inspection import inspect_file

FIXTURE = Path(__file__).parent / "fixtures" / "bnetza_minimal.csv"


def test_inspect_minimal_csv() -> None:
    report = inspect_file(FIXTURE)

    assert report.source_format == "csv"
    assert report.row_count == 2
    assert report.station_count == 2
    assert report.evse_slot_count == 3
    assert report.slot_numbers == (1, 2)
    assert report.unknown_columns == ()
    assert report.warnings == ()
    assert len(report.sha256) == 64


def test_inspect_minimal_xlsx_with_preamble(tmp_path: Path) -> None:
    with FIXTURE.open(encoding="utf-8", newline="") as handle:
        source_rows = list(csv.reader(handle, delimiter=";"))

    workbook = Workbook()
    worksheet = workbook.active
    worksheet.append(["Bundesnetzagentur-Testdaten"])
    for row in source_rows:
        worksheet.append(row)
    target = tmp_path / "bnetza_minimal.xlsx"
    workbook.save(target)

    report = inspect_file(target)

    assert report.source_format == "xlsx"
    assert report.row_count == 2
    assert report.station_count == 2
    assert report.evse_slot_count == 3
    assert report.warnings == ()


def test_inspect_minimal_csv_with_preamble(tmp_path: Path) -> None:
    target = tmp_path / "bnetza_with_preamble.csv"
    source = FIXTURE.read_text(encoding="utf-8")
    target.write_text(
        "Ladesäulenregister Bundesnetzagentur;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n"
        "Hinweis: synthetische Testdaten;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;\n"
        f"{source}",
        encoding="utf-8",
    )

    report = inspect_file(target)

    assert report.source_format == "csv"
    assert report.row_count == 2
    assert report.station_count == 2
    assert report.evse_slot_count == 3


def test_inspect_csv_with_multiline_quoted_field(tmp_path: Path) -> None:
    with FIXTURE.open(encoding="utf-8", newline="") as handle:
        rows = list(csv.reader(handle, delimiter=";"))
    rows[1][rows[0].index("EVSE-ID1")] = "\nDE*BSP*E0001*1"
    target = tmp_path / "bnetza_multiline.csv"
    with target.open("w", encoding="utf-8", newline="") as handle:
        csv.writer(handle, delimiter=";").writerows(rows)

    report = inspect_file(target)

    assert report.row_count == 2
    assert report.station_count == 2
    assert report.evse_slot_count == 3
