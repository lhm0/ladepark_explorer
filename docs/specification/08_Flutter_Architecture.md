# Flutter-Architektur

Status: M10 Navigation, Sprache und Einstellungen implementiert

Entschieden sind Flutter, Apple MapKit für die iPhone-Version 1.0, lokale
SQLite-Datenhaltung und Repository Pattern. Fachlogik und Datenzugriff werden
von plattformspezifischen Funktionen getrennt, um eine Android-Portierung zu
erleichtern. MapKit liegt hinter einer eigenen Kartenschnittstelle; ein
Android-Adapter kann später voraussichtlich MapLibre verwenden.

Der App-Bestand wird read-only geöffnet. Favoriten und Einstellungen liegen in
einem getrennten Benutzerspeicher. Die UI verwendet ausschließlich ein
`ChargingRepository`; SQL bleibt in dessen SQLite-Implementierung.
Datenbankoperationen laufen asynchron.

Kartenabfragen liefern höchstens 500 kompakte Ergebnisse. Details werden bei
Auswahl nachgeladen. Gemeinsame Contract Tests führen definierte Abfragen
gegen dieselbe kleine SQLite-Fixture in Python und Flutter aus und vergleichen
Gruppen-IDs, Reihenfolge und Grenzfälle.

Wurf A umfasst Karte, reale Abstandsgruppen im sichtbaren Ausschnitt,
Marker-Auswahl, vollständig deckende Detailseite und Übergabe an Apple Maps.
Internationalisierung wird strukturell vorbereitet.

## Implementierter Gerüststand

Das Gerüst unter `app/` verwendet Flutter 3.44.8 Stable und Dart 3.12.2.
iOS 14 und Android API 24 sind als Plattformuntergrenzen konfiguriert.

```text
lib/
├── app/                 App-Komposition und Theme
├── data/charging/       read-only SQLite-Adapter und Datenbank-Isolate
├── data/favorites/      schreibbarer, app-lokaler SQLite-Adapter
├── data/settings/       versionierter lokaler Einstellungsspeicher
├── features/explorer/
│   ├── application/     Riverpod-Kartenstatus und Abfragekoordination
│   ├── domain/          Query, Gruppenobjekte und ChargingRepository
│   └── presentation/    datengetriebene Kartenoberfläche
├── features/favorites/  Favoritenmodell, Zustand und Favoritenliste
├── features/settings/   Sprache und bevorzugte Navigations-App
├── platform/maps/       MapAdapter und Dart-MapKit-Kanal
├── platform/navigation/ plattformneutrale Apple-/Google-Maps-Adapter
└── l10n/                DE-/EN-Lokalisierung
```

Implementiert sind Verträge, App-Shell, Riverpod-Composition-Root und der
produktive `SqliteChargingRepository`-Adapter. Eine langlebige, ausschließlich
read-only geöffnete SQLite-Verbindung lebt in einem eigenen Isolate. Der
Adapter prüft vor der ersten Abfrage `PRAGMA user_version` und die verpflichtenden
Schema-v2-Metadaten. Er bildet Kartenabfragen und Gruppendetails auf typisierte
Domainobjekte ab und übersetzt technische Fehler in stabile
`ChargingRepositoryError`-Kategorien.

Die Abfrage implementiert den gemeinsamen Vertrag für Kartenausschnitt,
Gruppendurchmesser, Mindestanzahl, Leistungsband, Betreiber, Connector und
lokale FTS-Suche. Große Ausschnitte verwenden den Direktfilter, kleine
Ausschnitte den Gruppen-R*Tree. Es werden höchstens 500 Ergebnisse an den
aufrufenden Isolate übertragen.

M3 implementiert den UIKit Platform View und die sichtbare Verdrahtung:

- `MKMapView` startet mit einer Deutschlandansicht,
- Swift meldet sichtbare Bounds und Markerauswahl über einen pro View
  benannten Method Channel,
- Riverpod wartet 300 ms nach Bounds-Änderungen, erweitert den Ausschnitt um
  15 Prozent und verwirft Ergebnisse veralteter Abfragen,
- Marker werden anhand der `group_id` differenziell aktualisiert und von
  MapKit bei niedrigen Zoomstufen visuell geclustert,
- HPC- und sonstige Ladegruppen sind farblich unterschieden,
- Gruppendetails werden erst nach Markerauswahl read-only nachgeladen.

Die Karteninteraktion übergibt alle Zeigersequenzen mit einem expliziten
`EagerGestureRecognizer` an den UIKit Platform View. `MKMapView` aktiviert
Scrollen, Zoomen, Rotation und Neigung ausdrücklich. Der `MapAdapter` bietet
zusätzlich `showGermanyOverview()`, sodass die UI unabhängig von einer
Mehrfinger-Geste zur Ausgangsansicht zurückkehren kann.

Die nach M4 ergänzte Stabilisierung begrenzt die Arbeit bei schnellen
Kartenbewegungen zusätzlich:

- Es läuft höchstens eine SQLite-Kartenabfrage gleichzeitig.
- Während einer laufenden Abfrage wird nur der neueste Ausschnitt aufgehoben;
  ältere wartende Ausschnitte werden ersetzt.
- Nahezu identische Bounds-Ereignisse werden ignoriert.
- Ein Ergebnis erreicht den Kartenadapter nur, wenn es noch zur neuesten
  Bounds-Revision gehört.
- Während eines nativen Markerupdates wird ebenfalls nur der neueste
  nachfolgende Markerzustand aufgehoben.
- Debug-Builds protokollieren Laufzeit, Ergebniszahl und wartende Folgearbeit
  für SQLite-Abfragen und Markerupdates.

M4 ergänzt das in ADR-0010 entschiedene Basisdatensatz-Packaging. Lokale und
Release-Builds können einen generierten, git-ignorierten Deutschlandbestand
einbinden. Auf iOS wird er direkt aus dem App-Bundle read-only geöffnet. Fehlt
er, bleibt die kleine Schema-v2-Contract-Fixture der reproduzierbare
Entwicklungs- und CI-Fallback.

Gruppendetails umfassen in M4 Ankername und -adresse, Koordinaten, eine
horizontal scrollbar dargestellte Betreiber-/Leistungs-/Connector-Matrix,
maximale Leistung, Öffnungszeiten, Näherungshinweis, Datensatzversion und Quelle.
Ein eigener plattformneutraler Navigationsadapter übergibt Name und
Ankerkoordinaten an Apple Maps oder – falls installiert – Google Maps.

Die Detailansicht wird als vollständig deckende, opake Flutter-Route ohne
Übergangsanimation geöffnet. MapKit und die Flutter-Detailoberfläche werden
dadurch nicht gleichzeitig sichtbar komponiert. Der gesamte Detailinhalt liegt
in einer gemeinsamen scrollbaren Liste; damit bleiben alle Felder und die
Navigation auch bei kleiner verfügbarer Höhe ohne `RenderFlex`-Overflow
erreichbar. Bis die Route geschlossen ist, wird keine weitere Markerauswahl
verarbeitet.

Der M5-Filterzustand ist als unveränderliches Domainmodell von der
Filterdarstellung getrennt und Bestandteil des `ExplorerMapState`. Beim
Anwenden erzeugt der Controller für den aktuellen Kartenausschnitt unmittelbar
eine neue `ChargingGroupQuery`; laufende Abfragen folgen weiterhin dem
Latest-wins-Vertrag. Anzahl und Mindestleistung bilden dabei eine gekoppelte
Bedingung: Dieselbe Mindestanzahl begrenzt sowohl das kumulierte Leistungsband
als auch – als redundanter schneller Vorfilter – die Gesamtzahl. Die 20
größten kanonischen Betreiber werden aus einer
vorberechneten SQLite-Statistik geladen. Weitere ungeprüfte Quellnamen fragt
die App erst ab zwei Suchzeichen lokal und begrenzt ab; Connectorwerte werden
einmalig geladen. Auch die Filteroberfläche verwendet wegen des
nativen MapKit Platform Views eine opake Vollbildroute ohne Animation.

Die native Einzelmarkerauswahl deselektiert zunächst den MapKit-Auswahlzustand.
Erst im folgenden Main-Runloop-Takt wird die Gruppen-ID über den Method Channel
an Flutter gemeldet. Die Detailroute wurde anschließend im normalen
Produktpfad des iPhone-Simulators wiederholt ohne Freeze geöffnet und
geschlossen.

Neue technische Implementierungen werden bei Bedarf unter `data/` und
`platform/` ergänzt. `core/` ist nur für tatsächlich featureübergreifende,
plattformneutrale Typen vorgesehen und wird nicht vorsorglich befüllt.
Domaincode darf keine Implementierungen aus `data`, `platform` oder
`presentation` importieren; diese Grenze wird automatisiert geprüft.

M10 ergänzt einen eigenständig versionierten SQLite-Einstellungsspeicher im
Application-Support-Verzeichnis. Riverpod lädt und persistiert die Auswahl
zwischen Systemsprache, Deutsch und Englisch sowie „jedes Mal fragen“, Apple
Maps und Google Maps. Eine nicht unterstützte Systemsprache fällt beim ersten
Start auf Deutsch zurück. Die Verfügbarkeit von Google Maps wird nativ über
das registrierte URL-Schema geprüft; ist eine zuvor gewählte App nicht mehr
vorhanden, bietet die Detailansicht Apple Maps als verständliche Alternative
an. Produktnamen und Quelltexte bleiben von der Lokalisierung ausgenommen.

Der ausführbare Datensatzvertrag unter `contracts/charging_dataset/v2/` wird
von Python- und Flutter-Tests gemeinsam verwendet. Das Vorgehen folgt ADR-0007.

M6 löst freie Orts- und Adressnamen über natives `MKLocalSearch` in eine
Koordinate auf. Der lokale Ladebestand wird danach mit den aktiven Filtern in
wachsenden Radien durchsucht und nach Haversine-Distanz sortiert. Die Karte
bleibt auf dem gesuchten Ort zentriert und umfasst mindestens den nächsten
Treffer. Der vorhandene FTS-Index bleibt als Offline-Fallback für bereits im
Ladebestand enthaltene Namen erhalten. Core Location wird im MapKit-Adapter erst nach Auswahl eines
Umkreisradius angefordert. Die lokale Abfrage begrenzt zunächst über den
Radius-Bounding-Box-Ausschnitt und prüft Treffer anschließend mit der
Haversine-Distanz. Eingehende Koordinaten liegen hinter einem eigenen
Platform-Channel-Adapter gemäß ADR-0013.

ADR-0008 entscheidet direkten `sqlite3`-Zugriff in einem langlebigen
Hintergrund-Isolate und Riverpod ohne Codegenerierung. ADR-0009 entscheidet
einen app-lokalen UIKit Platform View mit `MKMapView`. Der Updateablauf wird vor
seiner Implementierung weiter konkretisiert; der separate Benutzerspeicher ist
mit ADR-0014 entschieden.

M7 ergänzt einen getrennten, schreibbaren SQLite-Benutzerspeicher im
Application-Support-Verzeichnis. Ein Favorit referenziert die stabile
`anchor_station_id` und enthält nur einen kleinen Darstellungssnapshot. Die
aktuelle Gruppe wird über Mitgliedschaft und den aktuell gewählten
Gruppendurchmesser aufgelöst; ein expliziter Stationsalias wird berücksichtigt.
Details erlauben das Hinzufügen und Entfernen über ein Herz, die Hauptansicht
öffnet eine eigene Favoritenliste. Nicht mehr auflösbare Einträge bleiben dort
sichtbar und löschbar. ADR-0014 dokumentiert die Speicherentscheidung.

M9.1 ergänzt `ExplorerFilters` um eine geordnete Menge erforderlicher
Infrastrukturmerkmale. Beim Übernehmen der Filterseite fragt die
Application-Komposition den getrennten `ParkInformationRepository` einmalig
nach Stationsankern, deren redaktioneller Eintrag sämtliche gewählten Merkmale
als `present` ausweist. Die resultierenden Anker werden analog zu Favoriten im
Charging-Isolate auf Gruppen des aktuellen Durchmessers aufgelöst und mit den
übrigen Kartenfiltern per UND verknüpft. Detaildaten und Bilder werden dabei
nicht geladen. Eine leere Merkmalsauswahl lässt den bisherigen Abfragepfad
unverändert; eine aktive Auswahl ohne passende Anker liefert bewusst keine
Gruppen.

M9.2 führt den zuvor nur transienten Umkreis in `ExplorerFilters` zusammen.
Der Filter speichert ausschließlich den gewählten Radius; die aktuelle
Koordinate bleibt flüchtiger Sitzungszustand in `ExplorerMapState`. Beim
erstmaligen Aktivieren oder Ändern des Radius fordert die Presentation über den
MapKit-Adapter eine aktuelle Position an und übernimmt den Filter nur bei
Erfolg. Die Charging-Abfrage kombiniert Bounding Box und exakte
Haversine-Distanz weiterhin mit allen übrigen Kriterien per UND. Das Aufheben
des Radius, eine Orts-/Koordinatensuche und die Deutschlandübersicht entfernen
Position und Umkreis gemeinsam.

M9.3 verwendet gemäß ADR-0015 den Schema-v2-Index
`group_always_open_power_band`. Bei aktivem Schalter muss die gekoppelte
Mindestzahl ausreichend leistungsfähiger Ladepunkte vollständig aus Stationen
mit dem normalisierten Status `always_open` stammen. Die Abfrage bleibt im
langlebigen Charging-Isolate und benötigt keine Laufzeitinterpretation von
Öffnungszeiten-Texten.

## Verifizierte iOS-Entwicklungsumgebung

- macOS 15.0,
- Xcode 16.2, Build `16C5032a`,
- iOS-18.3-Simulatorruntime,
- CocoaPods 1.17.0 als Fallback für Plugins ohne SwiftPM-Unterstützung,
- erfolgreicher Simulator-Build mit nativen `sqlite3`-Hooks,
- erfolgreicher Start auf einem simulierten iPhone 16.

Der lokale Ablauf ist in `app/README.md` dokumentiert. GitHub Actions enthält
zusätzlich einen geplanten iOS-Simulator-Build auf einem macOS-Runner; dieser
Workflow wurde noch nicht auf GitHub ausgeführt.
