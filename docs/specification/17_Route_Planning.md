# Routenplanung – Version 1.1

Status: Verbindlicher Spezifikationskern für das Routen-Update

Stand: 28. August 2026

Zielrelease: Version 1.1 („Routen-Update“)

## 1. Verwendung

Dieses Kapitel beschreibt das beobachtbare Produktverhalten der Routenplanung.
Es folgt derselben Kennzeichnung wie
[`02_Requirements.md`](02_Requirements.md): `FR` für funktionale, `NFR` für
nicht-funktionale Anforderungen; Priorität `Muss` für den Umfang von
Version 1.1, Priorität `Soll` für wichtige, bei dokumentiertem Grund
verschiebbare Anforderungen.

Die Routenplanung ist kein Bestandteil von Version 1.0. Version 1.0 bleibt
unverändert offline-first, iPhone-zentriert und ohne dauerhaftes fachliches
Backend. Version 1.1 fügt der bestehenden App die Routenplanung hinzu; der
gemeinschaftliche Ausbau folgt erst danach (siehe
[`14_Roadmap.md`](14_Roadmap.md)).

## 2. Zielbild

Nutzende geben Start und Ziel ein. Über die vorhandene Filterfunktion ist eine
Teilmenge von Ladeparks aktiv. Die App berechnet eine Straßenroute und schlägt
darin Ladestopps an gefilterten Ladeparks vor, sodass der geschätzte
Ladezustand zwischen einer Reserve und der nutzbaren Obergrenze bleibt. Jeder
vorgeschlagene Stopp lässt sich durch eine Alternative ersetzen, ergänzen oder
entfernen; die Planung passt sich an.

Die Verbrauchs- und Reichweitenvorhersage ist in Version 1.1 bewusst einfach:
sie beruht ausschließlich auf nutzbarer Batteriekapazität, einem
Durchschnittsverbrauch je 100 Kilometer und dem Start-Ladezustand. Eine spätere
„intelligente“ Vorhersage, die Straßenart, Steigung, Gefälle, Temperatur,
Ladekurve und weitere Größen berücksichtigt, ist ein eigener späterer
Produktbereich. Die Architektur bereitet sie vor (siehe Abschnitt 6 und
[`ADR-0020`](../adr/ADR-0020-Energy-and-Segment-Model.md)), zieht sie aber
nicht vor.

### Abgrenzung

- Die Routenplanung ist eine Planungshilfe, keine Turn-by-Turn-Navigation. Die
  eigentliche Navigation bleibt Sache von Apple Maps oder Google Maps
  (`FR-NAV-001`, `FR-ROUTE-011`).
- Die Routen- und Teilstreckenberechnung erfolgt online über Apple
  `MKDirections`. Sie ist derselben Klasse zuzuordnen wie die bereits
  vorhandene Online-Ortssuche über `MKLocalSearch` (`ADR-0013`).
- Live-Belegung, Tarife, Preise, Reservierung und Bezahlung bleiben
  ausgeschlossen.

## 3. Beziehung zur bestehenden App

- **Filter:** Die Korridorsuche verwendet denselben `ExplorerFilters`-Zustand
  wie die Kartenansicht (Ladeangebot, Betreiber, Steckertyp, Öffnungszeiten,
  Infrastruktur, nur Favoriten). Es entsteht kein zweites Filtermodell.
- **Detailansicht:** Ein Korridor-Ladepark öffnet die bestehende opake
  Detailroute (`FR-DETAIL-001`, `ADR-0011`).
- **Karte:** Routengeometrie und Ladestopp-Markierungen werden nativ als
  Überlagerung in der bestehenden `MKMapView` gezeichnet
  (`ADR-0009`, `ADR-0019`). Über der Karte erscheint kein interaktives
  Flutter-Vollbild-Panel; die Planungsoberfläche nutzt opake, animationslose
  Vollbildrouten wie Filter und Suche.
- **Navigation:** Die Übergabe an eine Navigations-App folgt der bestehenden
  Navigationswahl aus `FR-NAV-001` und `ADR-0016`.
- **Datenschutz:** Der zusätzliche Netzwerkzugriff wird in
  [`16_Privacy_and_Diagnostics.md`](16_Privacy_and_Diagnostics.md) und auf der
  Datenschutzseite ergänzt.

## 4. Funktionale Anforderungen

### FR-ROUTE-001 – Basisroute zwischen zwei Punkten

- Priorität: Muss
- Beschreibung: Die App berechnet online eine Straßenroute für ein
  Kraftfahrzeug von einem Startpunkt zu einem Zielpunkt und stellt sie auf der
  Karte dar.
- Akzeptanz:
  - Start und Ziel können als eigener Standort, Ort, Adresse, Koordinate oder
    ausgewählter Ladepark angegeben werden. Es gelten dieselben Eingabe- und
    Auflösungswege wie in `FR-SEARCH-001`.
  - Die Route wird nativ als Linienüberlagerung in der Karte gezeichnet und in
    einen sichtbaren Maßstab eingepasst.
  - Gesamtdistanz und erwartete reine Fahrzeit ohne Ladepausen werden
    angezeigt.
  - Sind Alternativrouten verfügbar, können sie ausgewählt werden.
  - Ohne Netzverbindung erklärt die App den Zustand verständlich; Karte, lokale
    Suche, Filter, Details und Favoriten bleiben nutzbar.
  - Eine gedrosselte oder fehlgeschlagene Berechnung wird verständlich gemeldet
    und kann wiederholt werden.
  - Die Routengeometrie wird nicht als Fahranweisung dargestellt.

### FR-ROUTE-002 – Zwischenziele

- Priorität: Soll
- Beschreibung: Eine Route kann geordnete Zwischenziele enthalten, die keine
  Ladestopps sind.
- Akzeptanz:
  - Zwischenziele nutzen dieselben Eingabearten wie Start und Ziel.
  - Die Reihenfolge der Zwischenziele ist manuell änderbar.
  - Die App berechnet die Teilstrecken zwischen aufeinanderfolgenden Punkten
    und weist Distanz und Fahrzeit gesamthaft aus.

### FR-ROUTE-003 – Ladeparks entlang der Route

- Priorität: Muss
- Beschreibung: Die App zeigt aus dem installierten Datensatz Ladeparks in
  einem Korridor um die berechnete Route, die die aktiven Filter erfüllen.
- Akzeptanz:
  - Es gelten dieselben Lade-, Betreiber-, Anschluss-, Infrastruktur-, 24/7-
    und Favoritenfilter wie in der Kartenansicht; Mehrfachwerte und
    UND-Verknüpfung bleiben unverändert.
  - Die gefundenen Ladeparks werden als Marker auf der Routenkarte gezeigt;
    andere Ladeparks werden dort nicht dargestellt.
  - Die Korridorbreite ist begrenzt und dokumentiert.
  - Die Suche arbeitet auf dem lokalen Datensatz und benötigt außer der zuvor
    bezogenen Route keine Netzverbindung.
  - Die Auswahl eines Korridor-Markers öffnet die bestehende Detailansicht.
  - Überschreitet die Trefferzahl die technische Obergrenze der Kartenabfrage,
    wird sichtbar begrenzt statt unvollständig ohne Hinweis dargestellt.

### FR-ROUTE-004 – Manuelle Ladestopps

- Priorität: Muss
- Beschreibung: Nutzende können Korridor-Ladeparks als Ladestopps übernehmen
  und wieder entfernen.
- Akzeptanz:
  - Ein Ladepark wird aus seiner Detailansicht als Ladestopp übernommen oder
    entfernt.
  - Ein übernommener Stopp wird als geordneter Wegpunkt in die Route
    aufgenommen; die Reihenfolge folgt der Position entlang der Route.
  - Nach jeder Änderung werden die betroffenen Teilstrecken neu berechnet.
  - Distanz und Fahrzeit werden mit den Stopps aktualisiert.
  - Übernommene Ladestopps sind auf der Karte eigens hervorgehoben, bleiben
    sichtbar, solange die Route angezeigt wird, und lassen sich dort erneut
    antippen, um sie über die Detailansicht wieder zu entfernen.
  - Ein Ladestopp kann ohne Fahrzeugprofil gesetzt werden; Reichweiten- und
    Ladeschätzungen bleiben dann leer.

### FR-ROUTE-005 – Fahrzeugprofil

- Priorität: Muss
- Beschreibung: Die App speichert ein lokales Fahrzeugprofil für die
  Reichweiten- und Ladeplanung.
- Akzeptanz:
  - Das Profil enthält mindestens nutzbare Batteriekapazität in kWh,
    Durchschnittsverbrauch in kWh je 100 km, Reserve-Ladezustand in Prozent,
    Ziel-Ladezustand bei Ankunft in Prozent, maximale Ladeleistung in kW und
    kompatible Steckertypen.
  - Es wird genau ein Profil unterstützt; die Persistenz ist für mehrere
    Profile ausgelegt (`ADR-0021`).
  - Das Profil wird ausschließlich lokal gespeichert und benötigt kein Konto.
  - Ohne vollständiges Profil bleiben Basisroute, Korridorsuche und manuelle
    Stopps (`FR-ROUTE-001` bis `FR-ROUTE-004`) nutzbar; die Reichweiten- und
    Ladeplanung ist dann inaktiv.
  - Fehlende Werte werden als unbekannt behandelt und nicht durch einen
    erfundenen Wert ersetzt.
  - Der Start-Ladezustand einer Fahrt ist je Planung einstellbar; der
    Profilwert ist die Vorgabe.

### FR-ROUTE-006 – Einfache Reichweitenvorhersage

- Priorität: Muss
- Beschreibung: Für eine Route mit Fahrzeugprofil schätzt die App den
  Ladezustandsverlauf und weist auf nicht erreichbare Abschnitte hin.
- Akzeptanz:
  - Die Vorhersage der Version 1.1 verwendet ausschließlich Streckenlänge,
    Fahrzeugverbrauch und Start-Ladezustand.
  - Der geschätzte Ladezustand wird als Färbung der Routenlinie auf der Karte
    sichtbar gemacht: ein Verlauf von Grün über Gelb nach Rot, wobei Rot dem
    Reserve-Ladezustand entspricht (Vorgabe 10 Prozent). Die genauen
    Farbschwellen sind dokumentiert (`ADR-0023`).
  - An jedem Ladestopp beginnt die Färbung wieder bei Grün, ausgehend vom
    angenommenen Abfahrt-Ladezustand. In Version 1.1 ist dieser der
    Ziel-Ladezustand des Fahrzeugprofils; ab `FR-ROUTE-008` stammt er aus dem
    Ladeverfahren.
  - Unterschreitet der geschätzte Ladezustand ohne Ladestopp die Reserve, wird
    die Stelle zusätzlich als Warnung markiert.
  - Ohne vollständiges Fahrzeugprofil bleibt die Routenlinie einfarbig; die
    Ladezustandsfärbung ist dann inaktiv.
  - Die Vorhersage ist als Schätzung gekennzeichnet und wird nicht als
    garantierte Reichweite bezeichnet.
  - Das Vorhersageverfahren ist hinter einer austauschbaren Schnittstelle
    gekapselt (`NFR-ROUTE-EXT-001`).

### FR-ROUTE-007 – Automatischer Ladestopp-Vorschlag

- Priorität: Muss
- Beschreibung: Die App schlägt aus den Korridor-Ladeparks eine Folge von
  Ladestopps vor, mit der der geschätzte Ladezustand zwischen Reserve und
  nutzbarer Obergrenze bleibt.
- Akzeptanz:
  - Der Vorschlag berücksichtigt die aktiven Filter und die Steckerkompatibilität
    des Profils.
  - Für jeden Stopp werden geschätzter Ankunfts-Ladezustand, Ziel-Ladezustand,
    nachgeladene Energie in kWh und geschätzte Ladezeit angezeigt.
  - Die geschätzte Gesamtreisezeit einschließlich Ladepausen wird angezeigt.
  - Kann kein zulässiger Plan gefunden werden, wird dies verständlich
    begründet, statt einen unzulässigen Plan darzustellen.
  - Ladeleistung und Ladezeit werden nicht als garantierte Werte bezeichnet.
  - Der Vorschlag ist deterministisch für gleiche Route, gleichen Filterstand,
    gleiches Profil und gleichen Datensatz.

### FR-ROUTE-008 – Lademengen- und Ladezeitschätzung

- Priorität: Muss
- Beschreibung: Die App schätzt je Ladestopp die nachzuladende Energie und die
  Ladedauer.
- Akzeptanz:
  - Die Schätzung der Version 1.1 verwendet die kleinere von Fahrzeug- und
    Ladepark-Leistung sowie einen dokumentierten Wirkungsgrad- beziehungsweise
    Pufferfaktor.
  - Die Schätzung ist als Näherung gekennzeichnet.
  - Das Ladeverfahren ist hinter einer austauschbaren Schnittstelle gekapselt
    (`NFR-ROUTE-EXT-001`).

### FR-ROUTE-009 – Alternative Ladestopps und adaptive Neuplanung

- Priorität: Muss
- Beschreibung: Nutzende können jeden vorgeschlagenen Ladestopp durch eine
  Alternative aus dem Korridor ersetzen; die App passt die Planung an.
- Akzeptanz:
  - Zu jedem Stopp bietet die App eine Liste alternativer Korridor-Ladeparks,
    sortiert nach Position und geschätztem Umweg, unter Beachtung der aktiven
    Filter und der Steckerkompatibilität.
  - Nach einem Austausch werden die nachgelagerten Teilstrecken, Lademengen und
    Ladezeiten neu berechnet.
  - Vorangehende und ausdrücklich gesperrte Stopps bleiben unverändert.
  - Nutzende können zusätzlich Stopps hinzufügen oder entfernen; die Planung
    bleibt konsistent oder weist verständlich aus, dass sie nicht mehr
    zulässig ist.

### FR-ROUTE-010 – Stoppbezogene Anpassungen

- Priorität: Soll
- Beschreibung: Nutzende können je Ladestopp den Ziel-Ladezustand anpassen und
  einen Stopp gegen automatische Änderungen sperren.
- Akzeptanz:
  - Eine Änderung des Ziel-Ladezustands wirkt sich auf die nachgelagerte
    Reichweiten- und Zeitplanung aus.
  - Ein gesperrter Stopp wird von der automatischen Neuplanung weder verändert
    noch entfernt.
  - Die Vorgabewerte stammen aus dem Fahrzeugprofil.

### FR-ROUTE-011 – Übergabe der geplanten Route an eine Navigations-App

- Priorität: Soll
- Beschreibung: Die geplante Route einschließlich Ladestopps kann an Apple Maps
  oder Google Maps übergeben werden.
- Akzeptanz:
  - Soweit die Ziel-App mehrere Wegpunkte annimmt, werden Start, Ladestopps und
    Ziel in Reihenfolge übergeben.
  - Andernfalls wird mindestens der nächste Ladestopp beziehungsweise das Ziel
    übergeben; die Einschränkung wird erklärt.
  - Es gelten die bestehenden Navigationswahl- und Fallback-Regeln aus
    `FR-NAV-001`.

## 5. Nicht-funktionale Anforderungen

### NFR-ROUTE-OFFLINE-001 – Abgegrenzte Onlineabhängigkeit

- Priorität: Muss
- Beschreibung: Nur die Routen- und Teilstreckenberechnung benötigt eine
  Netzverbindung.
- Akzeptanz:
  - Korridorsuche, Reichweitenvorhersage, Stopp-Auswahl und Neuplanung arbeiten
    auf der zuvor bezogenen Route ohne weitere Netzverbindung.
  - Ohne Netz zeigen Routenfunktionen einen verständlichen Zustand und
    beeinträchtigen die lokalen Kernfunktionen der App nicht.
  - Ein zuletzt berechneter Plan bleibt für die laufende Sitzung erhalten.

### NFR-ROUTE-PRIV-001 – Datenschutz der Routenplanung

- Priorität: Muss
- Beschreibung: Die Routenplanung überträgt nur die für die Berechnung nötigen
  Standortangaben an den Kartendienst und speichert Profil und Plan
  ausschließlich lokal.
- Akzeptanz:
  - An den Kartendienst gehen ausschließlich Start, Ziel und Wegpunkte der
    Route.
  - Fahrzeugprofil und berechneter Plan verlassen das Gerät nicht.
  - Der Netzwerkzugriff ist in [`16_Privacy_and_Diagnostics.md`](16_Privacy_and_Diagnostics.md)
    und auf der Datenschutzseite beschrieben.
  - Es entsteht keine Telemetrie und kein personenbezogenes Nutzungsprofil.

### NFR-ROUTE-EXT-001 – Nachrüstbare Vorhersage

- Priorität: Muss
- Beschreibung: Verbrauchs-, Lade- und Stopp-Planungslogik liegen hinter
  stabilen Domänenschnittstellen, sodass ein genaueres Modell ohne Änderung der
  aufrufenden Abläufe eingesetzt werden kann.
- Akzeptanz:
  - Die Route wird als geordnete Segmentfolge mit optionalen Attributen
    (Straßenklasse, Steigung, Höhendifferenz) modelliert; Version 1.1 lässt
    diese Attribute leer.
  - `EnergyModel`, `ChargingModel` und `StopPlanner` sind reine
    Domänenschnittstellen ohne Abhängigkeit von Daten-, Plattform- oder
    Präsentationscode; die Architekturprüfung schützt diese Grenze.
  - Der Austausch einer Implementierung erfordert keine Änderung an
    Oberfläche, Persistenz oder Kartenanbindung.

### NFR-ROUTE-PERF-001 – Reaktionsfähigkeit der Routenfunktionen

- Priorität: Soll
- Beschreibung: Korridorsuche und Neuplanung wirken auf dem Referenzgerät
  zügig.
- Akzeptanz:
  - Nach Vorliegen der Route erscheint das Korridorergebnis bei üblicher
    Streckenlänge innerhalb weniger Sekunden; ein Fortschritt ist sichtbar.
  - Eine Neuplanung ohne neue Routenberechnung wird innerhalb von 500 ms
    sichtbar.
  - Messgerät, Streckenlänge und Verfahren werden vor der Abnahme dokumentiert.

## 6. Architektur und Nachrüstbarkeit

Die verbindlichen Entscheidungen stehen in den ADRs:

- [`ADR-0019 – Route-Planning-Service`](../adr/ADR-0019-Route-Planning-Service.md):
  plattformneutraler `RoutePlanningService`-Port, `MKDirections`-Adapter,
  natives Routen-Overlay, dezimierte Polyline an Flutter.
- [`ADR-0020 – Energie- und Segmentmodell`](../adr/ADR-0020-Energy-and-Segment-Model.md):
  Segmentmodell und die austauschbaren Schnittstellen `EnergyModel`,
  `ChargingModel`, `StopPlanner`.
- [`ADR-0021 – Fahrzeugprofil-Speicher`](../adr/ADR-0021-Vehicle-Profile-Store.md):
  schema-versionierte Ablage im lokalen Einstellungsspeicher.
- [`ADR-0022 – Routenkorridor-Suche`](../adr/ADR-0022-Route-Corridor-Search.md):
  Abtastung entlang der dezimierten Polyline mit der bestehenden
  Radiusabfrage; keine Vertragsänderung in Version 1.1.
- [`ADR-0023 – Ladezustandsfärbung der Route`](../adr/ADR-0023-Route-State-Of-Charge-Colouring.md):
  der `TripEnergySimulator` liefert je Polylinienabschnitt einen geschätzten
  Ladezustand; die App bildet ihn auf eine Farbe ab und übergibt die
  eingefärbten Abschnitte nativ an das Routen-Overlay. An jedem Ladestopp
  springt der Ladezustand auf den Abfahrtswert.

### Schnittstellen im Überblick

```text
RoutePath     = geordnete Liste von RouteSegment
RouteSegment  { distanceKm, durationS, start, end,
                roadClass?, grade?, elevationDeltaM? }   // optionale Felder in 1.1 leer
TripContext   { ambientTempC?, ... }                     // erweiterbarer Kontext, in 1.1 leer

EnergyModel.estimate(RoutePath, VehicleProfile, TripContext) -> EnergyEstimate
  Version 1.1: ConstantRateEnergyModel  – Energie = km / 100 * Verbrauch
  Fernziel:    intelligenter Adapter    – nutzt Straßenklasse, Steigung, Temperatur

ChargingModel.estimate(parkPowerKw, VehicleProfile, arrivalSoc, targetSoc) -> ChargeEstimate
  Version 1.1: LinearChargingModel      – Leistung = min(Fahrzeug, Ladepark) * Faktor
  Fernziel:    CurveChargingModel       – fahrzeugspezifische Ladekurve

StopPlanner.plan(candidates, VehicleProfile, EnergyModel, ChargingModel, constraints) -> ChargingPlan
  Version 1.1: GreedyStopPlanner        – fahren bis Reserve, besten erreichbaren Stopp wählen
  Fernziel:    OptimizingStopPlanner    – Gesamtzeit- oder Umwegoptimierung
```

Die frühen Versionen sind mit den trivialen Implementierungen vollständig
funktionsfähig. Das Fernziel tauscht Implementierungen, nicht Aufrufer.

## 7. Umsetzung in Meilensteinen

| Meilenstein | Inhalt | Anforderungen |
| --- | --- | --- |
| M14.0 | Anforderungen und ADRs (dieses Kapitel, `ADR-0019` bis `ADR-0023`) | – |
| M14 | Basisroute A→B, natives Overlay, Distanz und Fahrzeit, Alternativrouten, Offline- und Fehlerzustände | `FR-ROUTE-001`, `FR-ROUTE-002`, `NFR-ROUTE-OFFLINE-001` |
| M15 | Korridorsuche mit aktiven Filtern, Position und Umweg, manuelle Ladestopps, Neuberechnung der Teilstrecken | `FR-ROUTE-003`, `FR-ROUTE-004` |
| M16 | Fahrzeugprofil, Segmentmodell, `EnergyModel`, Ladezustandssimulation, farbige Ladezustandsdarstellung der Route (`ADR-0023`) und Reserve-Warnung | `FR-ROUTE-005`, `FR-ROUTE-006`, `NFR-ROUTE-EXT-001` |
| M17 | `ChargingModel`, `StopPlanner`, automatischer Ladestopp-Vorschlag mit Lademenge, Ladezeit und Gesamtreisezeit | `FR-ROUTE-007`, `FR-ROUTE-008` |
| M18 | Alternativenauswahl, adaptive Neuplanung, Hinzufügen/Entfernen/Sperren, stoppbezogene Ziel-Ladezustände, Sitzungspersistenz | `FR-ROUTE-009`, `FR-ROUTE-010` |
| M19 | Datenschutzdokumentation, Offline-Härtung, Zugänglichkeit, DE/EN-Redaktion, Gerätematrix, Routenübergabe an Navigations-App | `FR-ROUTE-011`, `NFR-ROUTE-PRIV-001`, `NFR-ROUTE-OFFLINE-001`, `NFR-ROUTE-PERF-001` |

## 8. Noch zu konkretisierende Werte

Vor Umsetzung beziehungsweise Abnahme der betroffenen Anforderung werden
festgelegt:

- ~~Korridorbreite und Abtastabstand entlang der Route~~ – mit M15 festgelegt:
  20 km Abtastabstand, 10 km Korridorradius (ADR-0022),
- Wirkungsgrad- beziehungsweise Pufferfaktor der Ladezeitschätzung,
- Vorgabewerte des Fahrzeugprofils und zulässige Wertebereiche,
- Standard-Reserve und Standard-Ziel-Ladezustand,
- Farbschwellen und Verlaufsfunktion der Ladezustandsfärbung sowie Breite und
  Deckkraft eines optionalen Farbsaums entlang der Route (`ADR-0023`),
- Referenzgerät und Messverfahren für `NFR-ROUTE-PERF-001`,
- Umfang der an eine Navigations-App übergebbaren Wegpunktkette je Ziel-App.

## 9. Ausblick: „intelligente“ Vorhersage

Jenseits von Version 1.1 kann die Vorhersage genauer werden. Jedes Teilthema
ist eine eigene Produkt- und Architekturentscheidung mit eigenem ADR und
eigenen Anforderungen:

- Straßenklasse je Segment aus `MKRoute`-Schritten und gegebenenfalls
  OpenStreetMap,
- Höhenprofil aus einem getrennten Höhenmodell-Artefakt, analog zur geplanten
  OSM-Trennung,
- Umgebungstemperatur aus einem Wetterdienst mit eigener Datenschutzprüfung,
- fahrzeugspezifische Ladekurven aus einer Fahrzeugdatenbasis
  (Build-versus-Buy),
- lernende Anpassung an Fahrergewohnheiten ausschließlich lokal und
  ausdrücklich einwilligungsbasiert,
- optimierende statt gieriger Stoppauswahl.

Diese Erweiterungen ersetzen die Schnittstellen aus Abschnitt 6 nicht, sondern
liefern neue Implementierungen dahinter.
