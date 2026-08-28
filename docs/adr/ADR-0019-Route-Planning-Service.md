# ADR-0019 – Plattformneutraler Route-Planning-Service

Status: Angenommen

Datum: 28. August 2026

## Kontext

Version 1.1 ergänzt die App um eine Routenplanung (siehe
[`../specification/17_Route_Planning.md`](../specification/17_Route_Planning.md),
`FR-ROUTE-001` bis `FR-ROUTE-004`). Eine Route von A nach B, optional mit
Ladestopps als Wegpunkten, muss berechnet, auf der Karte dargestellt und mit
Kennzahlen zusammengefasst werden.

Die App zeichnet die Karte bereits über einen app-lokalen UIKit Platform View
mit `MKMapView` (`ADR-0009`). `ADR-0011` hat gezeigt, dass eine sichtbare
Flutter-Überlagerung über diesem nativen View nach nativem Touch reproduzierbar
einfriert; Vollbildansichten sind deshalb opake, animationslose Routen.
`ADR-0013` hat für die Ortssuche entschieden, freie Ortsnamen online über
`MKLocalSearch` aufzulösen und diesen Schritt als online zu kennzeichnen.

Apple `MKDirections` liefert Autorouten einschließlich Alternativrouten,
Distanz, erwarteter Fahrzeit und Schrittinformationen. Es liefert keine
EV-spezifische, ladebewusste Routenoptimierung; diese Logik bleibt in der App
(`ADR-0020`). `MKDirections` sendet Start-, Ziel- und Wegpunktkoordinaten an
Apple und ist drosselbar.

## Entscheidung

- Ein plattformneutraler Domänen-Port `RoutePlanningService` wird in
  `app/lib/features/route_planning/domain/` definiert. Er nimmt eine
  `RouteRequest` (Start, Ziel, geordnete Wegpunkte, Option „Alternativen
  einbeziehen“) entgegen und liefert eine oder mehrere `RouteOption`-Objekte.
- Eine `RouteOption` enthält die für die Fachlogik nötigen Angaben:
  Gesamtdistanz, erwartete reine Fahrzeit, Bounding-Box, geordnete
  Teilstrecken (`RouteLeg`) und je Option eine **dezimierte** Polyline als
  Liste von `GeoCoordinate`. Die exakte Apple-Polyline verbleibt nativ.
- Die MapKit-Umsetzung liegt in `app/lib/platform/route/` als
  `MkDirectionsRoutePlanningService`. Sie ruft `MKDirections` über einen
  kleinen Method Channel im nativen Code auf und reduziert die
  Apple-Polyline vor der Übergabe an Flutter mit einem
  Douglas-Peucker-Verfahren auf eine begrenzte Punktzahl (Zielgröße im
  Bereich einiger hundert Punkte, ausreichend für die Korridorsuche nach
  `ADR-0022`).
- Die Routengeometrie wird **nativ** als `MKOverlay` in der bestehenden
  `MKMapView` gezeichnet. Der native Kartenkanal wird um `showRoute`,
  `clearRoute` und `fitRoute` sowie um Ladestopp-Markierungen erweitert. Die
  exakte Polyline wird nicht über den Method Channel transportiert, wenn die
  native Seite sie ohnehin besitzt; Flutter erhält sie nur in dezimierter Form
  für fachliche Berechnungen.
- Die gesamte Routenoberfläche – Eingabe von Start/Ziel/Wegpunkten,
  Zusammenfassung, Alternativauswahl, spätere Planbearbeitung und „Route
  beenden“ – liegt auf opaken, animationslosen Vollbildrouten wie Filter und
  Suche. Über der nativen Karte wird **keine** Flutter-Fläche zur
  Routenanzeige komponiert; sichtbar ist dort ausschließlich das native
  Routen-Overlay. Dies hält an ADR-0011 fest (siehe Nachtrag).
- Die Onlineberechnung wird in der Oberfläche als online gekennzeichnet.
  Offline-, Fehler- und Drosselungszustände werden ausdrücklich behandelt und
  erlauben einen erneuten Versuch. Ein zuletzt bezogenes Ergebnis bleibt für
  die Sitzung erhalten.
- Zustand und Koordination laufen über Riverpod in
  `app/lib/features/route_planning/application/`. Domänencode importiert keine
  Implementierungen aus `data`, `platform` oder `presentation`; die
  Architekturprüfung schützt diese Richtung.

## Gründe

- Der Port trennt die Fachlogik der Routenplanung von der heutigen
  MapKit-Umsetzung. Ein späterer Wechsel auf einen anderen Routing-Anbieter
  oder eine Android-Umsetzung tauscht nur den Adapter.
- Die native Darstellung der Geometrie hält an `ADR-0009` und `ADR-0011` fest
  und vermeidet die bekannte Freeze-Kombination.
- Die dezimierte Polyline reicht für die Korridorsuche und die
  Segmentbildung, hält den Method-Channel-Verkehr klein und vermeidet, exakte
  Apple-Geometrie unnötig zu kopieren.
- `MKDirections` fügt keine neue Fremdbibliothek hinzu; MapKit ist bereits
  eingebunden.

## Folgen

Positiv:

- klare Portgrenze für spätere Anbieter- oder Plattformwechsel,
- keine sichtbare Flutter-Überlagerung über der nativen Karte,
- begrenzter, überprüfbarer Datenabfluss (nur Start, Ziel, Wegpunkte).

Negativ beziehungsweise zu beachten:

- Die Routenplanung ist ohne Netz nicht verfügbar; nur die lokale
  Weiterverarbeitung einer bereits bezogenen Route ist offlinefähig.
- Teilstrecken-Neuberechnungen bei jeder Stoppänderung erzeugen mehrere
  `MKDirections`-Anfragen; Ergebnisse werden für die Sitzung zwischengespeichert
  und Drosselung wird sichtbar gemacht.
- Start-, Ziel- und Wegpunktkoordinaten gehen an Apple. Der Zugriff wird in
  [`../specification/16_Privacy_and_Diagnostics.md`](../specification/16_Privacy_and_Diagnostics.md)
  und auf der Datenschutzseite ergänzt (`NFR-ROUTE-PRIV-001`).

## Nachtrag (28. August 2026)

Die erste M14-Umsetzung zeigte über der Hauptkarte einen kleinen Flutter-Balken
mit Kennzahlen und Alternativumschaltung – bewusst schmal, „analog zum
Status-Chip“. Auf Simulator und echtem iPhone fror die App reproduzierbar ein,
sobald dieser Balken nach Nutzung der Route wieder geschlossen wurde. Das ist
der in `ADR-0011` beschriebene Freeze der Hybrid-Komposition aus nativem
Platform View und einer sichtbaren, dynamisch ein- und ausgeblendeten
Flutter-Überlagerung. Eine Internetrecherche bestätigte dies als bekannte,
weiterhin offene Klasse von iOS-`UiKitView`-Fehlern (flutter/flutter #37579,
#62717, #150478, #116267, #46167): Flutter-Inhalt über einem Platform View
wird in zusätzliche native Overlay-/Clip-Ebenen zerlegt; deren Einfügen,
Entfernen oder Größenänderung – besonders nach einer nativen Geste – lässt den
UIKit-Gestenzustand hängen. Das Zusammenlegen von UI- und Plattform-Thread in
Flutter 3.29 hat diese Klasse nicht geschlossen.

Die frühere Zulassung eines schmalen Flutter-Elements über der Karte ist damit
zurückgenommen. Über der nativen Karte wird **keine** Flutter-Fläche zur
Routenanzeige komponiert.

Damit Route und Auswahl trotzdem gleichzeitig sichtbar sind, verwendet die
Routenvorschau ein **nicht überlappendes Split-Layout** auf einer opaken
Vollbildroute (`RoutePreviewPage`):

- eine eigene `MKMapView`-Instanz füllt in einem `Column` den Bereich über
  einem statischen Auswahlpanel; Karte und Panel überlappen nie,
- das Panel wird nicht ein- oder ausgeblendet und ändert seine Höhe während
  der Nutzung nicht, die Kartengröße bleibt konstant,
- das Kartenwidget wird zwischengespeichert, damit Panel-Aktualisierungen den
  Platform View nicht neu aufbauen (flutter/flutter #62717),
- die Vorschaukarte verzichtet auf den `EagerGestureRecognizer`, um das
  Gesten-Wedge-Risiko weiter zu senken; die Hauptkarte behält ihn.

Die Auswahl einer Alternative zeichnet die Polyline über den Kartenadapter der
Vorschau neu, das Panel bleibt stehen.

## Referenzen

- [Apple MKDirections](https://developer.apple.com/documentation/mapkit/mkdirections)
- [`ADR-0009 – Native MapKit-Integration als iOS Platform View`](ADR-0009-Native-MapKit-Platform-View.md)
- [`ADR-0011 – Opake Detailroute über MapKit`](ADR-0011-Opaque-Detail-Route-over-MapKit.md)
- [`ADR-0013 – Lokale Standortsuche und eingehende Koordinaten`](ADR-0013-Location-Search-and-Inbound-Coordinates.md)
- iOS-Platform-View-Freeze: flutter/flutter Issues 37579, 62717, 150478, 116267, 46167
- [iOS platform views – Flutter docs](https://docs.flutter.dev/platform-integration/ios/platform-views)
