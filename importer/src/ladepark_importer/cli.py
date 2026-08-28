import argparse
import sys
from collections.abc import Sequence
from pathlib import Path

from ladepark_importer.clustering import SUPPORTED_DIAMETERS_M
from ladepark_importer.commands import dispatch
from ladepark_importer.errors import ImporterError

PROJECT_DIRECTORY = Path(__file__).resolve().parents[2]
DEFAULT_NAMESPACES = PROJECT_DIRECTORY / "config" / "namespaces.json"
DEFAULT_CONNECTOR_TYPES = PROJECT_DIRECTORY / "config" / "connector_types.json"
DEFAULT_OPERATORS = PROJECT_DIRECTORY / "config" / "operators.json"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ladepark-importer")
    subparsers = parser.add_subparsers(dest="command", required=True)

    inspect_parser = subparsers.add_parser("inspect", help="BNetzA-Quelldatei und Schema prüfen")
    inspect_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")

    normalize_parser = subparsers.add_parser(
        "normalize", help="BNetzA-Quelldatei in typisierte Objekte umwandeln"
    )
    normalize_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")
    normalize_parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    normalize_parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
    report_parser = subparsers.add_parser(
        "report", help="Kompakten Qualitätsbericht der Normalisierung erzeugen"
    )
    report_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")
    report_parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    report_parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
    cluster_parser = subparsers.add_parser(
        "cluster-report", help="Gruppierung berechnen und kompakt auswerten"
    )
    cluster_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")
    cluster_parser.add_argument(
        "--dataset-version", required=True, help="Version des Quelldatensatzes"
    )
    cluster_parser.add_argument(
        "--diameter",
        type=int,
        required=True,
        choices=(25, 50, 100, 200, 300),
        help="Maximaler Gruppendurchmesser in Metern",
    )
    cluster_parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    cluster_parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
    review_parser = subparsers.add_parser(
        "cluster-review", help="Prüfliste auffälliger und HPC-starker Gruppen exportieren"
    )
    review_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")
    review_parser.add_argument("--output", type=Path, required=True, help="Zielpfad der Review-CSV")
    review_parser.add_argument(
        "--dataset-version", required=True, help="Version des Quelldatensatzes"
    )
    review_parser.add_argument(
        "--diameter",
        type=int,
        required=True,
        choices=(25, 50, 100, 200, 300),
        help="Maximaler Gruppendurchmesser in Metern",
    )
    review_parser.add_argument(
        "--limit-per-category",
        type=_positive_int,
        default=100,
        help="Top-N je Kategorie HPC, EVSEs und Stationen",
    )
    review_parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    review_parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
    operator_review_parser = subparsers.add_parser(
        "operator-review",
        help="Betreiber-Quellnamen nach Ladepunktzahl für die Kanonisierung exportieren",
    )
    operator_review_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")
    operator_review_parser.add_argument(
        "--output", type=Path, required=True, help="Zielpfad der Review-CSV"
    )
    operator_review_parser.add_argument(
        "--candidate-limit",
        type=_non_negative_int,
        default=5,
        help="Maximale Zahl ähnlicher Quellnamen je Betreiber",
    )
    operator_review_parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    operator_review_parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
    operator_worklist_parser = subparsers.add_parser(
        "operator-worklist",
        help="Top-Betreiber und ähnliche Quellnamen als kompakte Arbeitsliste exportieren",
    )
    operator_worklist_parser.add_argument("source", type=Path, help="BNetzA-Quelldatei")
    operator_worklist_parser.add_argument(
        "--output", type=Path, required=True, help="Zielpfad der Arbeitslisten-CSV"
    )
    operator_worklist_parser.add_argument(
        "--top", type=_positive_int, default=20, help="Zahl der größten Quellnamen"
    )
    operator_worklist_parser.add_argument(
        "--candidate-limit",
        type=_non_negative_int,
        default=5,
        help="Maximale Zahl ähnlicher Namen je Quellname",
    )
    _add_normalization_arguments(operator_worklist_parser)
    registry_parser = subparsers.add_parser(
        "operator-registry-validate",
        help="Versioniertes Betreiberregister gegen die BNetzA-Quelle validieren",
    )
    registry_parser.add_argument("source", type=Path, help="BNetzA-Quelldatei")
    registry_parser.add_argument(
        "--registry", type=Path, default=DEFAULT_OPERATORS, help="Betreiberregister"
    )
    _add_normalization_arguments(registry_parser)
    coverage_parser = subparsers.add_parser(
        "operator-coverage",
        help="Abdeckung des Betreiberregisters nach Stationen und Ladepunkten ausgeben",
    )
    coverage_parser.add_argument("source", type=Path, help="BNetzA-Quelldatei")
    coverage_parser.add_argument(
        "--registry", type=Path, default=DEFAULT_OPERATORS, help="Betreiberregister"
    )
    _add_normalization_arguments(coverage_parser)
    build_sqlite_parser = subparsers.add_parser(
        "build-sqlite", help="Vollständige charging.sqlite erzeugen und validieren"
    )
    build_sqlite_parser.add_argument("source", type=Path, help="Pfad zu CSV- oder XLSX-Datei")
    build_sqlite_parser.add_argument(
        "--output", type=Path, required=True, help="Zielpfad der SQLite-Datei"
    )
    build_sqlite_parser.add_argument(
        "--dataset-version", required=True, help="Version des App-Datensatzes"
    )
    build_sqlite_parser.add_argument(
        "--source-version", required=True, help="Stand der BNetzA-Quelle"
    )
    build_sqlite_parser.add_argument(
        "--created-at", required=True, help="Reproduzierbarer RFC-3339-Buildzeitpunkt"
    )
    build_sqlite_parser.add_argument(
        "--pipeline-version", default="0.1.0", help="Version der Importpipeline"
    )
    build_sqlite_parser.add_argument(
        "--replace", action="store_true", help="Vorhandene Ausgabedatei ersetzen"
    )
    build_sqlite_parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    build_sqlite_parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
    build_sqlite_parser.add_argument(
        "--operators", type=Path, default=DEFAULT_OPERATORS, help="Betreiberregister"
    )
    validate_sqlite_parser = subparsers.add_parser(
        "validate-sqlite", help="charging.sqlite vollständig validieren"
    )
    validate_sqlite_parser.add_argument("database", type=Path, help="SQLite-Datei")
    release_parser = subparsers.add_parser(
        "build-release", help="Statisches, verifizierbares App-Updatepaket erzeugen"
    )
    release_parser.add_argument("database", type=Path, help="Validierte charging.sqlite")
    release_parser.add_argument("--output", type=Path, required=True, help="Ausgabeverzeichnis")
    release_parser.add_argument(
        "--repository", required=True, help="Öffentliches GitHub-Repository als owner/name"
    )
    release_parser.add_argument("--git-commit", required=True, help="Erzeugender Git-Commit")
    query_sqlite_parser = subparsers.add_parser(
        "query-sqlite", help="Abstandsgruppen im lokalen App-Datensatz filtern"
    )
    query_sqlite_parser.add_argument("database", type=Path, help="SQLite-Datei")
    query_sqlite_parser.add_argument(
        "--diameter", type=int, choices=SUPPORTED_DIAMETERS_M, default=50
    )
    query_sqlite_parser.add_argument("--min-evse", type=int, default=1)
    query_sqlite_parser.add_argument(
        "--min-power", type=int, choices=(0, 50, 100, 150, 200, 250, 300, 350), default=100
    )
    query_sqlite_parser.add_argument("--min-power-evse", type=int, default=1)
    query_sqlite_parser.add_argument(
        "--operator", action="append", default=[], help="Exakter BNetzA-Betreibername; wiederholbar"
    )
    query_sqlite_parser.add_argument(
        "--connector", action="append", default=[], help="Connector-Code; wiederholbar"
    )
    query_sqlite_parser.add_argument("--search", help="Ort, Adresse, Name oder Betreiber")
    query_sqlite_parser.add_argument(
        "--bounds",
        type=float,
        nargs=4,
        metavar=("SOUTH", "WEST", "NORTH", "EAST"),
        help="Kartenausschnitt in WGS84",
    )
    query_sqlite_parser.add_argument(
        "--near", type=float, nargs=2, metavar=("LATITUDE", "LONGITUDE")
    )
    query_sqlite_parser.add_argument("--radius-km", type=float)
    query_sqlite_parser.add_argument("--limit", type=int, default=100)
    detail_parser = subparsers.add_parser(
        "group-detail", help="Details einer Abstandsgruppe ausgeben"
    )
    detail_parser.add_argument("database", type=Path, help="SQLite-Datei")
    detail_parser.add_argument("group_id", help="Gruppen-ID")
    park_info_parser = subparsers.add_parser(
        "build-park-info", help="Geprüften redaktionellen park_info-Bestand erzeugen"
    )
    park_info_parser.add_argument("source", type=Path, help="Redaktionelle JSON-Quelldatei")
    park_info_parser.add_argument("--media", type=Path, required=True, help="Ordner der App-Bilder")
    park_info_parser.add_argument(
        "--charging-database", type=Path, required=True, help="Ladebestand für Stationsprüfung"
    )
    park_info_parser.add_argument("--output", type=Path, required=True, help="Ziel-SQLite-Datei")
    park_info_parser.add_argument(
        "--media-output", type=Path, required=True, help="Zielordner der veröffentlichten Bilder"
    )
    park_info_parser.add_argument("--replace", action="store_true")
    validate_park_info_parser = subparsers.add_parser(
        "validate-park-info", help="Redaktionellen park_info-Bestand validieren"
    )
    validate_park_info_parser.add_argument("database", type=Path)
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    parser = build_parser()
    arguments = parser.parse_args(argv)
    try:
        result = dispatch(arguments)
        if result is not None:
            return result
    except ImporterError as error:
        print(f"Fehler: {error}", file=sys.stderr)
        return 2
    parser.error(f"Unbekannter Befehl: {arguments.command}")
    return 2


def _positive_int(value: str) -> int:
    parsed = int(value)
    if parsed < 1:
        raise argparse.ArgumentTypeError("muss eine positive Ganzzahl sein")
    return parsed


def _non_negative_int(value: str) -> int:
    parsed = int(value)
    if parsed < 0:
        raise argparse.ArgumentTypeError("darf nicht negativ sein")
    return parsed


def _add_normalization_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument(
        "--namespaces", type=Path, default=DEFAULT_NAMESPACES, help="Namespace-Konfiguration"
    )
    parser.add_argument(
        "--connector-types",
        type=Path,
        default=DEFAULT_CONNECTOR_TYPES,
        help="Connector-Mapping",
    )
