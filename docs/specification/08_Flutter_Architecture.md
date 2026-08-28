# Flutter-Architektur

Status: M0 bis M12 implementiert; M13 Release-Härtung offen; M14 (Basisroute
der Routenplanung, Version 1.1) implementiert

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
Marker-Auswahl, vollständig deckende Detailseite und Übergabe an Apple Maps
oder Google Maps. Deutsch und Englisch sind implementiert.

## Implementierter Gerüststand

Das Gerüst unter `app/` verwendet Flutter 3.44.8 Stable und Dart 3.12.2.
iOS 14 und Android API 24 sind als Plattformuntergrenzen konfiguriert.

```text
lib/
├── app/                 App-Komposition und Theme
├── data/charging/       read-only SQLite-Adapter und Datenbank-Isolate
├── data/dataset_update/ HTTP-Quelle und atomare Datensatzinstallation
├── data/favorites/      schreibbarer, app-lokaler SQLite-Adapter
├── data/park_info/      getrennter redaktioneller read-only Bestand
├── data/settings/       versionierter lokaler Einstellungs- und Fahrzeugprofilspeicher
├── features/dataset_update/ Manifestvertrag und Updatezustand
├── features/explorer/
│   ├── application/     Riverpod-Kartenstatus und Abfragekoordination
│   ├── domain/          Query, Gruppenobjekte und ChargingRepository
│   └── presentation/    datengetriebene Kartenoberfläche
├── features/favorites/  Favoritenmodell, Zustand und Favoritenliste
├── features/park_info/  redaktionelle Informationen und Medienmodelle
├── features/route_planning/ Routenmodelle, RoutePlanningService und Routenzustand (Version 1.1)
├── features/settings/   Sprache, Navigation, Updates und Datenschutz
├── platform/inbound/    eingehende Koordinaten und App-Link
├── platform/maps/       MapAdapter und Dart-MapKit-Kanal
├── platform/navigation/ plattformneutrale Apple-/Google-Maps-Adapter
├── platform/route/      MKDirections-Routenadapter (Version 1.1)
├── platform/search/     native Apple-Ortssuche
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
einen app-lokalen UIKit Platform View mit `MKMapView`. Der separate
Benutzerspeicher ist mit ADR-0014 entschieden.

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

M11 ergänzt den statischen Updatepfad aus ADR-0017. Ein kleiner HTTPS-Adapter
lädt das Manifest des neuesten GitHub Releases. Erst nach Bestätigung streamt
die App das gzip-Artefakt in einen temporären Bestand. Komprimierte und
unkomprimierte Größe und SHA-256, SQLite-Integrität, Schema und Metadaten werden
vor einer atomaren `active.json`-Umschaltung geprüft. Aktueller und vorheriger
Downloadbestand bleiben erhalten; Favoriten, Einstellungen und redaktionelle
Informationen werden nicht ersetzt.

M12 ergänzt gemäß ADR-0018 eine zweisprachige Datenschutz- und Diagnoseseite.
Die App enthält kein Analyse-, Werbe-, Tracking- oder automatisches
Crash-Reporting-SDK. Ein kleiner Diagnosestatus gelangt nur durch eine
ausdrückliche Aktion in die Zwischenablage und enthält keine Koordinaten,
Suchbegriffe, Favoriten oder Gerätekennung.

M14 beginnt das Routen-Update der Version 1.1 (Kapitel `17_Route_Planning.md`,
ADR-0019). Der plattformneutrale `RoutePlanningService` in
`features/route_planning/domain/` liefert typisierte `RouteOption`-Objekte mit
Kennzahlen, Teilstrecken und einer dezimierten Polyline. Der
`MkDirectionsRoutePlanningService` in `platform/route/` ruft je Teilstrecke
natives `MKDirections`, klassifiziert Netz-, Drossel- und Nicht-gefunden-Fehler
zu stabilen `RoutePlanningError`-Kategorien und reduziert die Geometrie per
Douglas–Peucker vor der Übergabe an Flutter. Die ausgewählte Route wird nativ
als `MKPolyline`-Overlay in der bestehenden `MKMapView` gezeichnet
(`showRoute`/`clearRoute`). Gemäß ADR-0011 wird über der Karte keine
Flutter-Fläche zur Routenanzeige komponiert. Start-/Zieleingabe läuft auf einer
opaken, animationslosen Vollbildroute (`RoutePlanningPage`). Die Routenvorschau
(`RoutePreviewPage`) ist ebenfalls eine opake Route, aber ein nicht
überlappendes Split-Layout: eine eigene `MKMapView`-Instanz füllt in einem
`Column` den Bereich über einem statischen Auswahlpanel, sodass Route und
Alternativen gleichzeitig sichtbar sind, ohne dass eine Flutter-Ebene über dem
Platform View liegt. Das Kartenwidget wird zwischengespeichert, und die
Vorschaukarte verzichtet auf den `EagerGestureRecognizer`. Ein erster Versuch
mit einem schmalen Zusammenfassungsbalken über der Hauptkarte reproduzierte den
ADR-0011-Freeze auf dem Gerät und wurde nach Internetrecherche als bekannte
iOS-`UiKitView`-Freeze-Klasse verworfen (ADR-0019 Nachtrag).

M15 ergänzt die Korridorsuche (`features/route_planning/domain/route_corridor.dart`
für die reine Geometrie, `application/corridor_providers.dart` für den
`CorridorController`). Gemäß ADR-0022 tastet der Controller die dezimierte
Route alle 20 km ab und ruft je Punkt `ExplorerMapController.findGroupsNear`
mit 10 km Radius; die Abfragen laufen sequentiell im Charging-Isolate. Treffer
werden über `groupId` dedupliziert. Die Interaktion ist kartenbasiert: der
Panel-Knopf der `RoutePreviewPage` startet die Suche, die Treffer erscheinen
als native orange Marker (`showRouteCorridor`) auf der Vorschaukarte. Ein Tippen
meldet die `groupId` über den Kanal (`corridorParkSelected`); die Vorschau
öffnet dann die bestehende Detailansicht mit dem Knopf „Ladestop einfügen".
Übernommene Stopps liegen als geordnete `RouteStop`s im `RoutePlanningState`,
werden `MKDirections` als Wegpunkte übergeben und nativ als blaue nummerierte
Marker gezeigt (`showRouteStops`); sie bleiben sichtbar, solange die Route auf
der Karte liegt. Korridormarker erscheinen nur in der Vorschau und schließen
die bereits gewählten Stopps aus.

M16a ergänzt das Fahrzeugprofil (`FR-ROUTE-005`, ADR-0021). `VehicleProfile`
und der `VehicleProfileRepository`-Vertrag liegen in
`features/route_planning/domain/`; die Ablage teilt sich die
schema-versionierte Einstellungsdatenbank: die Schemaversion steigt auf 2, die
neue Tabelle `vehicle_profiles` hält eine Zeile, und `SqliteSettingsRepository`
implementiert zusätzlich `VehicleProfileRepository`. Editiert wird das Profil in
den Einstellungen (`features/settings/presentation/vehicle_profile_page.dart`).

## Verifizierte iOS-Entwicklungsumgebung

- macOS 15.0,
- Xcode 16.2, Build `16C5032a`,
- iOS-18.3-Simulatorruntime,
- CocoaPods 1.17.0 als Fallback für Plugins ohne SwiftPM-Unterstützung,
- erfolgreicher Simulator-Build mit nativen `sqlite3`-Hooks,
- erfolgreicher Start auf einem simulierten iPhone 16.

Der lokale Ablauf ist in `app/README.md` dokumentiert. Der verbleibende
Release- und Abnahmeumfang steht in `14_Roadmap.md`; die kontextfreie
Architekturübergabe in `../AI_HANDOVER.md`. Der öffentliche GitHub-Actions-
Workflow einschließlich iOS-Simulator-Build lief bis einschließlich Commit
`fb49f22` erfolgreich.
