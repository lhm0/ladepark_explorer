# Tests und Qualitätsprüfungen

Status: Importer-Testbasis und Flutter-Gerüstprüfungen implementiert

Stand: 23. August 2026

## 1. Ziel

Automatisierte Prüfungen sichern die reproduzierbare Datenpipeline, den
SQLite-Vertrag und die plattformneutralen App-Grenzen. Neue Verhaltensänderungen
müssen auf die betroffenen Requirement-IDs aus `02_Requirements.md`
zurückführbar sein.

## 2. Implementierter Stand

### 2.1 Importer

Die Importer-Suite umfasst derzeit 58 Tests für:

- CLI und Fehlerausgaben,
- CSV-/XLSX-Inspektion und Schemaerkennung,
- Normalisierung und stabile IDs,
- Transformation in Stationen, EVSEs und Connectoren,
- alle zehn Referenzfälle der dynamischen Abstandsgruppierung,
- Determinismus, Medoidwahl und Vergleich mit einer naiven
  Referenzimplementierung,
- SQLite-Schema, Export, Doppelbuild und Validierung,
- read-only Gruppen-, Filter-, Text-, Karten- und Umkreisabfragen,
- Validierung und Referenzabfragen des gemeinsamen Schema-v2-Contracts.

Die synthetische BNetzA-Fixture unter `importer/tests/fixtures/` ist klein,
versioniert und darf in Unit- und Contract Tests verwendet werden. Der echte
Deutschlanddatensatz bleibt außerhalb von Git.

### 2.2 Flutter-App

Die Flutter-App besitzt derzeit dreißig Tests. Neben den vier
Gerüstprüfungen
sichern sechs M2-Adaptertests den produktiven Datenzugriff:

- Standardwerte und Ergebnislimit einer Gruppenabfrage,
- Ablehnung eines Kartenlimits über 500 Ergebnissen,
- lokalisierte Darstellung der Wurf-A-Platzhalteroberfläche,
- Verfügbarkeit und SQLite-Kennung der gemeinsamen Contract-Fixture.
- identische IDs und Sortierung für alle versionierten Contract-Abfragen,
- kombinierten Betreiber-, Connector-, Text- und Kartenausschnittfilter,
- typisiertes Summary- und Detailmapping sowie fehlende Gruppen,
- unveränderten Datenbankinhalt nach read-only Abfragen,
- Fehlerübersetzung für fehlende und inkompatible Datenbanken,
- ungültige Abfragen und Zugriffe nach dem Schließen des Repositorys.

Zwei M3-Tests prüfen zusätzlich die Riverpod-Kartenkoordination:

- 300-ms-Debounce, 15-prozentiger Abfragerand und nur eine Abfrage für rasch
  aufeinanderfolgende Bounds-Änderungen,
- Nachladen typisierter Details erst nach Auswahl einer Gruppe.

Der Widgettest verwendet ein überschriebenes Repository und prüft den
plattformneutralen Fallback. Der native Swift-Adapter wird derzeit durch den
iOS-Simulator-Build und einen manuellen Laufzeittest abgedeckt; automatisierte
XCUITests für Bounds, Marker und Auswahl sind noch geplant.

Die M10-Navigationstests prüfen die typisierten Method-Channel-Verträge für
Apple Maps und Google Maps, einschließlich nativer Verfügbarkeitsabfrage. Ein
SQLite-Neuöffnungstest belegt, dass Sprach- und Navigationswahl dauerhaft
gespeichert und sichere Standardwerte verwendet werden. Der gemeinsame
Detail-Contract prüft zusätzlich
Adresse, Koordinaten, Leistung, Öffnungszeiten, Leistungsbänder,
Datensatzversion und Quelle. Der lokale iOS-Lauf mit dem vollständigen
Deutschlandbestand belegt außerdem die direkte Bundle-Auflösung und die
Darstellung von 500 gefilterten Gruppen samt nativen Clustern.

Ein weiterer Kartenvertragstest prüft den nativen Befehl zum Wiederherstellen
der Deutschlandansicht; der Widgettest sichert die sichtbare Schaltfläche.
Der iOS-Simulator-Build kompiliert die explizite native Zoomkonfiguration. Die
Pinch-Geste selbst bleibt zusätzlich auf Simulator und echtem iPhone manuell
zu prüfen, weil die Flutter-Unit-Testumgebung keine echte iOS-Mehrfinger-Geste
an einen UIKit Platform View übergeben kann.

Zwei Stabilisierungstests simulieren schnelle Folgen von Kartenänderungen:

- Während einer blockierten Repository-Abfrage wird keine zweite Abfrage
  parallel gestartet; nach Freigabe läuft ausschließlich der neueste
  aufbewahrte Ausschnitt und nur dessen Ergebnis wird sichtbar.
- Während eines blockierten Platform-Channel-Markerupdates werden mehrere
  Folgeupdates zu genau dem neuesten Markerzustand zusammengefasst.

Ein zusätzlicher Widget-Regressionstest rendert vollständige Gruppendetails in
dem aus dem Simulatorfehler bekannten 373-Pixel-Höhenlimit. Er prüft, dass kein
Layoutfehler entsteht, ein Scrollbereich vorhanden ist und der
Apple-Maps-Button durch Scrollen erreichbar bleibt.

Ein zweiter Detail-Regressionstest öffnet und schließt die opake Vollbildroute
viermal nacheinander. Er prüft dabei die Navigation, fehlerfreies Layout und
die Freigabe des jeweils seitengebundenen Scroll-Controllers.

Der frühere Freeze beim wiederholten Öffnen und Schließen eines Flutter-Panels
über MapKit wurde mit gezielten A/B-Läufen untersucht. SQLite-Details,
Detailinhalt, Annotation-Auswahl, Gestenrouting und Simulator konnten als
alleinige Ursache ausgeschlossen werden. Stabil war der native Markertap nur,
wenn anschließend keine sichtbare Flutter-Überlagerung über der Karte entstand.
ADR-0011 hält deshalb die Entscheidung für eine opake Vollbildroute ohne
Animation fest. Der normale Produktpfad wurde am 24. August 2026 im
iPhone-16-Simulator wiederholt ohne Freeze geprüft. Die temporären
Diagnoseschalter und ihre ausschließlich diagnostischen Tests sind entfernt.

Vier M5-Regressionstests prüfen zusätzlich:

- materialisierte Top-Betreiber, begrenzte Suche ungeprüfter Quellnamen und
  lokal geladene Connectorauswahlwerte; die Top-Auswahl wird alphabetisch mit
  Ladepunktzahl in derselben Zeile dargestellt,
- unmittelbare Neuabfrage des aktuellen Ausschnitts mit allen geänderten
  Filterparametern; die sichtbare Anzahl wird dabei zugleich als Mindestzahl
  im gewählten Leistungsband übergeben,
- Mehrfachauswahl eines Betreibers auf der Filterseite,
- kompakte Anschlusszeilen und Auswahl eines Steckertyps,
- Wiederherstellung des Standardzustands mit 50 Metern Gruppendurchmesser und
  mindestens 20 Ladepunkten mit jeweils mindestens 100 kW.

Die M6-Tests prüfen zusätzlich:

- lokale Textsuche mit den aktiven Ladefiltern,
- nativer MapKit-Vertrag für die Online-Auflösung eines Ortsnamens,
- schrittweise Radiusvergrößerung bis zum nächsten passenden Ladepark,
- Parsing direkter Koordinaten sowie nicht verkürzter Apple- und
  Google-Maps-URLs,
- Kartenfokus und Standortvertrag mit ausgewähltem Radius,
- exakte Haversine-Nachprüfung nach der räumlichen Vorauswahl.

Der Detailvertrag prüft außerdem die disjunkte Leistungsklasse und
Steckertypzählung je Betreiber, die Verwendung eines kuratierten Anzeigenamens
sowie horizontale und vertikale Scrollbarkeit ohne Layout-Overflow.

MapKit-, Update- sowie Filtertests für noch nicht implementierte
Öffnungszeiten-, Entfernungs- und Infrastrukturfilter fehlen. Favoritentests
decken Persistenz, Aktualisierung, Entfernung, Anker- und Aliasauflösung,
Detailumschaltung, Favoriten-SQL-Filter sowie verfügbare und fehlende
Listeneinträge ab. Die Filter-Widgettests prüfen außerdem Übernahme durch
Zurück sowie die seiteninternen Aktionen „Abbruch“ und „Standard herstellen“.
Der MapKit-Kanaltest prüft die zusätzliche `isFavorite`-Markierung im
differenziellen Markerupdate.

Für den redaktionellen Informationsbestand bestehen Schema-/Buildtests,
ein gemeinsames Contract-Fixture, eine Prüfung unbekannter Stationsreferenzen
und die verpflichtende Bilddatei-Prüfsumme. App-Adapter- und Widgettests decken
vorhandene sowie fehlende Abdeckung ab. Sechs reale, visuell geprüfte
Pilotbilder belegen den Medienbuild; ein automatisiertes Fixture mit Bild und
ein Widgettest der Bilddarstellung stehen noch aus.

Zusätzlich prüft `tooling/check_flutter_architecture.dart`, dass Domaincode
keine Daten-, Plattform- oder Präsentationsimplementierungen importiert.

## 3. Verbindliche lokale Prüfungen

Für Änderungen am Importer:

```text
cd importer
uv sync
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run mypy src
```

Für Änderungen an der Flutter-App:

```text
cd app
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
dart run ../tooling/check_flutter_architecture.dart
flutter build ios --simulator
```

Die vollständigen funktionalen Probeläufe des Importers stehen in
`AGENTS.md`. Ein nativer iOS-Build setzt ein vollständiges Xcode voraus.

## 4. Anforderungsbezug des aktuellen Testbestands

| Bereich | Hauptanforderungen | Aktueller Nachweis |
| --- | --- | --- |
| Abstandsgruppen | `FR-GROUP-001` | Algorithmus-, Grenz-, Determinismus- und SQLite-Tests |
| Ladefilter | `FR-FILTER-001`, `FR-FILTER-003` | Python-, Dart-Adapter- und Widgettests für die implementierten Ladeangebotsfilter |
| Text- und Umgebungssuche | `FR-SEARCH-001`, `FR-SEARCH-002` | lokale FTS-Suchseite, Core-Location-Vertrag und Haversine-Umkreisfilter; manueller iPhone-Test folgt |
| Detaildaten | `FR-DETAIL-001` | typisiertes Dart-Detailmapping und scrollbare App-Darstellung; Infrastruktur fehlt |
| Favoriten | `FR-FAV-001`, `FR-FILTER-001` | getrennter SQLite-Speicher, Anker-/Aliasauflösung, SQL-Kartenfilter und Widgettests für Herz und Liste |
| Navigation und Sprache | `FR-NAV-001`, `FR-I18N-001` | Apple-/Google-Maps-Kanalverträge, Installationsprüfung und persistenter SQLite-Einstellungstest; manueller iPhone-Test folgt |
| Basisdatensatz | `FR-DATA-001`, `NFR-DATA-001` | reproduzierbarer SQLite-Doppelbuild und Validierung |
| Offline-Datenzugriff | `NFR-OFFLINE-001` | read-only SQLite-App-Adapter im Hintergrund-Isolate |
| Performance | `NFR-PERF-001` | explorative Deutschlandmessungen; formaler Gerätetest fehlt |
| Portierbarkeit | `NFR-PORT-001` | plattformneutrale Repository- und Kartenverträge |

Ein Testnachweis auf Importer-Ebene bedeutet noch nicht, dass die zugehörige
Produktanforderung in der App erfüllt ist.

## 5. Nächste Testausbaustufen

1. Weitere inklusive Filtergrenzen und Abbruch veralteter Kartenabfragen in
   der sichtbaren App-Integration prüfen.
2. MapKit-Adapter und sichtbaren Kartenausschnitt auf iOS testen.
3. Update-, Prüfsummen-, Rollback- und Favoritenerhalt-Szenarien abdecken.
4. Filter, Details, Standortberechtigungen, Navigation, Lokalisierung und
   Barrierefreiheit als Widget- beziehungsweise Integrationstests ergänzen.
5. Referenzgerät, Datensatzgröße und Messverfahren für die 500-ms-Ziele aus
   `NFR-PERF-001` dokumentieren und automatisierbare Benchmarks ergänzen.

## 6. Qualitätsgates für einen Datensatzrelease

Vor einem produktiven Release müssen mindestens erfolgreich sein:

- alle Unit-, Contract- und Integritätstests,
- Formatter, Linter und statische Typprüfung,
- Prüfung der Eingabehashes und Quellmetadaten,
- Schema-, Fremdschlüssel- und Aggregatvalidierung,
- vollständige Gruppenzuordnung für alle fünf Durchmesser,
- Prüfung aller Muss-Grenzwerte des Qualitätsberichts,
- byteidentischer Wiederholungsbuild bei gleichen Eingaben und Metadaten,
- Manifest-, Größen- und Prüfsummenprüfung des fertigen Releasepakets.

Die konkreten Muss-Grenzwerte für Warnungs- und Review-Kategorien sind noch
offen und vor Abschluss von M2 festzulegen.
