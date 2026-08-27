# ADR-0011 – Opake Detailroute über MapKit

Status: Angenommen

Datum: 24. August 2026

## Kontext

`FR-DETAIL-001` verlangt abrufbare Details für einen ausgewählten Ladepark.
Die erste Implementierung blendete dafür ein Flutter-Panel über dem nativen
`MKMapView` ein. Auf Simulator und echtem iPhone fror die App reproduzierbar
nach dem zweiten Öffnen und Schließen dieser Ansicht ein.

A/B-Tests schlossen die SQLite-Abfrage, die konkreten Detaildaten, MapKits
Annotation-Auswahlzustand, Flutters expliziten `EagerGestureRecognizer` und
den Simulator als alleinige Ursache aus. Native Markertaps samt
Method-Channel-Meldung blieben dagegen beliebig oft stabil, wenn keine
Flutter-Detailoberfläche über der Karte erzeugt wurde. Damit ist die
problematische Kombination auf den nativen Touch im Platform View und die
anschließende sichtbare Hybrid-Komposition eingegrenzt.

## Entscheidung

- Ladeparkdetails öffnen auf einer vollständig deckenden, opaken Flutter-Route.
- Hin- und Rücktransition haben Dauer null. Karte und Detailseite werden damit
  nicht während einer Animation gleichzeitig sichtbar komponiert.
- Die MapKit-Route bleibt unterhalb der Detailroute erhalten, wird aber nicht
  sichtbar gezeichnet.
- Bis die Detailroute geschlossen ist, wird keine weitere Markerauswahl
  verarbeitet.
- Die Detailseite besitzt eine normale Zurück-Navigation und einen vollständig
  scrollbaren Inhalt.

## Gründe

- Die Entscheidung entfernt genau die im A/B-Test verbliebene gleichzeitige
  Darstellung von UIKit Platform View und Flutter-Überlagerung.
- Sie behält den nativen MapKit-Adapter, die lokale Datenhaltung und den
  bestehenden Detailinhalt bei.
- Eine eigene Seite bietet auf kleinen Displays mehr Platz und eine
  konventionelle iOS-Navigation.

## Folgen

Positiv:

- keine sichtbare Flutter-Überlagerung über der nativen Karte,
- klarer Lebenszyklus mit höchstens einer geöffneten Detailansicht,
- vollständiger Inhalt bleibt ohne Layout-Overflow erreichbar.

Negativ:

- Karte und Details können nicht gleichzeitig betrachtet werden.

## Verifikation

Die opake Route wurde am 24. August 2026 im normalen Produktpfad des
iPhone-16-Simulators wiederholt geöffnet und geschlossen. Karte, Details und
Rückkehr zur Karte blieben ohne Freeze oder sonstige Auffälligkeiten. Der zuvor
reproduzierbare Fehler ist damit für den Simulator behoben; der bereits
erfolgte Gerätebefund betrifft noch die alte Panelimplementierung.
