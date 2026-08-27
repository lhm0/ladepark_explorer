# ADR-0008 – Direkter SQLite-Zugriff und Riverpod-Komposition

Status: Angenommen

Datum: 23. August 2026

## Kontext

Der Importer erzeugt eine vorhandene, versionierte SQLite-Datenbank mit
komplexen, bereits optimierten Abfragen, FTS5- und R*Tree-Indizes. Die App
öffnet diesen Bestand read-only. Favoriten und Einstellungen liegen in einem
getrennten schreibbaren Speicher. Kartenabfragen dürfen den UI-Isolate nicht
blockieren und müssen bei wechselnden Kartenausschnitten kontrolliert
abgebrochen beziehungsweise verworfen werden können.

Die App benötigt außerdem eine testbare Composition Root für Repositorys,
Adapter und asynchrone Zustände. Codegenerierung soll für Version 1.0 nur
eingesetzt werden, wenn sie einen belegbaren Mehrwert bringt.

## Entscheidung

- Die App verwendet `sqlite3` ab Version 3.5 als direkten Dart-FFI-Zugriff auf
  den Ladebestand.
- Der Ladebestand wird mit `OpenMode.readOnly` geöffnet. Schreibende SQL-Befehle
  gehören nicht in dessen Adapter.
- Eine langlebige Datenbankverbindung und alle fachlichen Abfragen laufen in
  einem eigenen Hintergrund-Isolate. Die UI erhält ausschließlich typisierte
  Domainobjekte.
- Das vorhandene SQL und der Schema-v1-Vertrag bleiben maßgeblich. Es wird kein
  ORM-Schema parallel zum Importer gepflegt.
- Flutter Riverpod ab Version 3.4 übernimmt State Management, asynchrone
  Zustände und Dependency Composition.
- `ProviderScope` bildet die Composition Root. Konkrete Adapter werden über
  Provider an Anwendungscode übergeben und in Tests überschrieben.
- Riverpod-Codegenerierung wird zunächst nicht verwendet. Provider und
  Notifier werden explizit geschrieben.
- Experimentelle Persistenzfunktionen von Riverpod sind für Version 1.0 nicht
  Teil der Entscheidung.
- Die genauen Versionen werden durch `app/pubspec.lock` reproduzierbar
  festgeschrieben.

## Gründe

- Direkter SQLite-Zugriff bildet die bestehenden FTS5-, R*Tree- und
  Aggregatabfragen ohne zweite Schemasprache ab.
- `sqlite3` bündelt die native Bibliothek über Dart/Flutter-Hooks und benötigt
  keine separate `sqlite3_flutter_libs`-Abhängigkeit.
- Ein Hintergrund-Isolate erfüllt die Architekturvorgabe, synchrone FFI-Zugriffe
  vom UI-Isolate fernzuhalten.
- Riverpod modelliert Laden, Daten und Fehler explizit und erlaubt
  Adapterüberschreibungen in Widget- und Integrationstests.

## Folgen

Positiv:

- geringe Abstraktionsdistanz zum versionierten Datensatzvertrag,
- keine doppelte Schema- oder Query-Codegenerierung,
- testbare Composition Root,
- kontrollierter Lifecycle einer read-only Datenbankverbindung.

Negativ:

- Isolate-Protokoll, Mapping und Fehlerübersetzung werden projektspezifisch
  implementiert,
- SQL bleibt bewusst handgeschrieben und benötigt starke Contract Tests,
- ein separates Konzept ist später für den schreibbaren Benutzerspeicher
  erforderlich.

## Verworfene Alternativen

- Ein ORM beziehungsweise Drift wurde für den read-only Produktbestand nicht
  gewählt, weil Schema und komplexes SQL bereits außerhalb der App verbindlich
  erzeugt und getestet werden.
- `sqflite` wurde nicht gewählt, weil der direkte FFI-Zugriff besser zum
  sprachübergreifenden Contract und zur expliziten Isolate-Grenze passt.
- Eigenes `ChangeNotifier`-State-Management wurde zugunsten einer einheitlichen,
  testbaren asynchronen Composition verworfen.
