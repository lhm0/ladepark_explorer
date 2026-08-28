# ADR-0023 – Ladezustandsfärbung der Route

Status: Angenommen

Datum: 28. August 2026

## Kontext

`FR-ROUTE-006` verlangt, den geschätzten Ladezustandsverlauf entlang der Route
sichtbar zu machen. Der Produktwunsch ist eine anschauliche Darstellung: die
Routenlinie verläuft farblich von Grün über Gelb nach Rot, wobei Rot dem
Reserve-Ladezustand entspricht. An jedem Ladestopp beginnt die Färbung wieder
bei Grün. So ist auf einen Blick erkennbar, wo der nächste Ladestopp nötig ist.

Die Route wird nativ als Overlay in `MKMapView` gezeichnet (`ADR-0019`). Der
`RoutePlanningService` liefert eine dezimierte Polyline; die Verbrauchs- und
Ladeplanung liegt hinter den Schnittstellen aus `ADR-0020`. Ein
`TripEnergySimulator` wendet `EnergyModel` und `ChargingModel` entlang der
Teilstrecken an und erzeugt einen Ladezustandsverlauf.

`MKPolylineRenderer` kann keinen Farbverlauf entlang einer einzelnen Polylinie
zeichnen. Die Färbung muss deshalb aus mehreren, je einfarbigen Abschnitten
bestehen.

## Entscheidung

- Der `TripEnergySimulator` liefert je Stützpunkt der dezimierten Polyline
  einen geschätzten Ladezustand in Prozent. Zwischen zwei Ladestopps sinkt er
  gemäß `EnergyModel` monoton; an einem Ladestopp springt er auf den
  Abfahrt-Ladezustand. In Version 1.1 ist der Abfahrtswert der Ziel-Ladezustand
  des Fahrzeugprofils; ab `FR-ROUTE-008` stammt er aus dem `ChargingModel`.
- Die App bildet jeden Polylinienabschnitt (zwei benachbarte Stützpunkte) über
  seinen mittleren Ladezustand auf eine Farbe ab. Die Verlaufsfunktion ist
  stückweise linear zwischen festen Stützfarben:
  - `>= 60 %` Grün,
  - `35 %` Gelb,
  - `<= Reserve` (Vorgabe 10 %) Rot,
  - Werte unterhalb der Reserve bleiben Rot.
  Die genauen Prozentwerte und RGB-Werte werden vor der M16-Abnahme in einer
  gemeinsamen, testbaren Konstante festgelegt.
- Die eingefärbten Abschnitte werden über den bestehenden Kartenkanal
  übergeben: `showRoute` erhält zusätzlich zur Polyline optional eine geordnete
  Liste von ARGB-Farbwerten, einen je Abschnitt (also `Punktzahl − 1`
  Einträge). Fehlt die Liste, zeichnet die native Seite die Route wie bisher
  einfarbig.
- Nativ wird je Abschnitt eine kurze `MKPolyline` mit eigenem
  `MKPolylineRenderer` und `strokeColor` gezeichnet. Die Abschnitte teilen
  sich Linienbreite, `lineCap` und `lineJoin`, sodass die Route trotz Zerlegung
  durchgehend wirkt.
- Ein optionaler halbtransparenter Farbsaum (breitere, deckungsreduzierte
  Linie unter der eigentlichen Route) ist als spätere Ausbaustufe vorgesehen.
  Breite und Deckkraft werden dann festgelegt; die Farbcodierung bleibt
  identisch.
- Ohne vollständiges Fahrzeugprofil wird keine Farbliste übergeben; die Route
  bleibt einfarbig.
- Die Farbcodierung der Route ist von der Markerfarbe der Korridor-Ladeparks
  (`ADR-0022`, derzeit Orange) und der Ladestopps (Blau) unterscheidbar zu
  halten.

## Gründe

- Zerlegte einfarbige Abschnitte sind mit vorhandenen MapKit-Renderern
  zuverlässig darstellbar; ein echter Gradient wäre nur mit eigenem Rendering
  erreichbar.
- Die Farbliste als optionale Beigabe zu `showRoute` hält den Kanalvertrag
  klein und abwärtskompatibel; ohne Profil ändert sich nichts.
- Die Zuständigkeit bleibt getrennt: der `TripEnergySimulator` (Domäne)
  liefert Ladezustände, die Präsentation bildet sie auf Farben ab, die
  Plattform zeichnet. Ein genaueres `EnergyModel` verändert nur die Zahlen,
  nicht die Darstellung.
- „Neustart bei Grün am Ladestopp" ergibt sich zwangsläufig aus dem Sprung des
  Ladezustands auf den Abfahrtswert; es ist keine Sonderbehandlung in der
  Darstellung nötig.

## Folgen

Positiv:

- unmittelbar verständliche Anzeige, wann der nächste Ladestopp nötig ist,
- kein neues Overlay-Konzept; die opake-Route-Regel aus `ADR-0011` bleibt
  unberührt, da weiterhin nur nativ gezeichnet wird,
- die Darstellung ist unabhängig vom konkreten Verbrauchsmodell.

Negativ beziehungsweise zu beachten:

- Die dezimierte Polyline begrenzt die Farbauflösung; bei sehr langen
  Abschnitten kann der Farbwechsel grob wirken. Bei Bedarf werden vor der
  Färbung zusätzliche Stützpunkte eingefügt.
- Viele kurze `MKPolyline`-Abschnitte kosten etwas Renderleistung; die
  Abschnittszahl folgt der ohnehin begrenzten Polylinienpunktzahl.
- Farbwahl und Kontrast (auch für Farbsehschwäche) sind Teil der
  M16-Zugänglichkeitsprüfung; die Reserve-Stelle wird zusätzlich nicht nur
  über Farbe markiert.

## Referenzen

- [`ADR-0019 – Plattformneutraler Route-Planning-Service`](ADR-0019-Route-Planning-Service.md)
- [`ADR-0020 – Energie- und Segmentmodell`](ADR-0020-Energy-and-Segment-Model.md)
- [`ADR-0021 – Lokaler Fahrzeugprofil-Speicher`](ADR-0021-Vehicle-Profile-Store.md)
