# ADR-0007 – Modulares Monorepo und versionierter Datensatzvertrag

Status: Angenommen

Datum: 23. August 2026

## Kontext

Das Repository enthält eine Python-Datenpipeline und eine Flutter-App. Mit
SQLite-Anbindung, MapKit, Datensatzupdates, OSM-Infrastruktur und lokalen
Benutzerdaten wächst die Zahl der technischen Adapter deutlich. Gleichzeitig
soll Version 1.0 ohne Backend und ohne unnötige Paket- oder Schichtkomplexität
lieferbar bleiben.

Python erzeugt den Produktdatensatz, Dart liest ihn. Das SQLite-Format ist
damit eine sprachübergreifende, versionierte Schnittstelle und darf nicht nur
implizit durch eine Python-Implementierung definiert sein.

## Entscheidung

- App, Importer, Verträge und Dokumentation bleiben in einem Monorepo.
- `contracts/charging_dataset/v1/` enthält den ausführbaren Vertrag für Schema
  Version 1: eine kleine reproduzierbare SQLite-Fixture, Abfragen und erwartete
  Ergebnisse.
- Python- und Flutter-Tests verwenden dieselben Contract-Artefakte.
- Der Importer trennt CLI, Pipeline-Orchestrierung, fachliche Verarbeitung und
  Charging-SQLite-Zugriff. Bestehende öffentliche Python-Importpfade dürfen
  während der Umstellung als Kompatibilitätsfassaden erhalten bleiben.
- Die Flutter-App wird pragmatisch nach App-Komposition, gemeinsamem Kern,
  Datenadaptern, Produktfeatures und Plattformadaptern gegliedert.
- Suche, Filter, Karte und Gruppendetails bleiben zunächst im gemeinsamen
  Feature `explorer`. Eine weitere Aufteilung erfolgt erst bei eigenständigem
  Verhalten.
- Favoriten und Einstellungen greifen nie auf den read-only Ladebestand
  schreibend zu.
- Neue Top-Level-Dienste oder ein Backend werden erst bei einem konkreten
  Releasebedarf ergänzt.

## Abhängigkeitsrichtung

```text
Flutter presentation -> application/domain <- data and platform adapters

Importer CLI -> pipeline -> domain/source processing -> artifact adapters

Python producer -> contracts/charging_dataset/v1 <- Dart consumer
```

Domänen- und Anwendungscode importieren keine UI-, SQLite- oder
plattformspezifischen Implementierungen. Adapter implementieren die von innen
definierten Verträge.

## Folgen

Positiv:

- Schema- und Filterabweichungen zwischen Python und Dart werden früh erkannt.
- SQLite-, MapKit-, Update- und Benutzerspeicher bleiben austauschbar.
- Version 1.5 und ein späteres Backend können ergänzt werden, ohne Version 1.0
  vorzeitig darauf auszurichten.
- Große technische Module können entlang ihrer Verantwortung wachsen.

Negativ:

- Contract-Artefakte müssen bei jeder Schemaänderung bewusst versioniert und
  aktualisiert werden.
- Zusätzliche Verzeichnisse und Kompatibilitätsfassaden erhöhen kurzfristig
  die Zahl der Dateien.
- Abhängigkeitsgrenzen müssen durch Tests und Reviews eingehalten werden.

## Nicht entschieden

Dieses ADR wählt noch keine konkrete Flutter-Bibliothek für SQLite, State
Management oder Dependency Injection. Diese Entscheidungen werden vor der
jeweiligen Adapterimplementierung separat dokumentiert und anhand nativer
iOS-Tests geprüft.
