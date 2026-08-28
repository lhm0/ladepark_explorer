# UI

Status: Wurf-A-Kernfluss bis Apple-Maps-Übergabe implementiert

Die App ist kartenzentriert; der Ladestandort ist das zentrale Anzeigeobjekt.
Suche und aktive Filter müssen unmittelbar erkennbar und schnell erreichbar
sein. Die Kernabläufe und Zugänglichkeitsregeln aus `02_Requirements.md` sind
vor dem UI-Entwurf in konkrete Zustände und Nutzerflüsse zu überführen.

## 1. Ausbaureihenfolge

Die App beginnt mit Wurf A als bewusst kleinem, durchgängigem
iPhone-Prototyp:

1. App und Apple-Karte öffnen,
2. read-only SQLite-Bestand laden,
3. Abstandsgruppen im sichtbaren Kartenausschnitt anzeigen,
4. Marker auswählen,
5. kompakte Details auf einer vollständig deckenden Seite anzeigen,
6. Koordinaten an Apple Maps übergeben.

Die Schritte 1 bis 6 sind seit M4 technisch durchgängig umgesetzt. Das
Die Detailseite zeigt bekannte Kernangaben, Datenquelle und den Hinweis auf
die räumliche Näherung. Die Navigation verwendet die Koordinaten der
Ankerstation und öffnet Apple Maps im Fahrmodus.

Ein vorbereiteter lokaler beziehungsweise Release-Build verwendet den
vollständigen Deutschlandbestand. Ohne Vorbereitung bleibt die kleine
Schema-v2-Contract-Fixture der Entwicklungs- und CI-Fallback.

Vollständige Filter, Favoriten, Updates, Einstellungen, Telemetrie und
Infrastruktur folgen erst nach einem erfolgreichen Test dieses Ablaufs auf
einem echten iPhone. Die Internationalisierung wird technisch von Beginn an
vorbereitet; Wurf A darf zunächst nur vollständige deutsche Texte enthalten.

M5 stellt die bereits datenwirksamen Ladeangebotsfilter auf einer vollständig
deckenden Seite bereit. Editierbar sind Gruppendurchmesser, die gekoppelte
Mindestanzahl ausreichend leistungsfähiger Ladepunkte, deren Mindestleistung,
Betreiber und Anschlusstypen. Ein dynamischer Klartextsatz fasst die Bedingung
„Mindestens N Ladepunkte mit jeweils mindestens P kW“ zusammen. Die 20 größten
Betreiber erscheinen direkt mit kuratiertem Anzeigenamen, alphabetisch sortiert
und in stark verdichteten
Einzeilern. Die Ladepunktzahl steht ohne wiederholte Einheit in Klammern; ein
einmaliger Hinweis erklärt ihre Bedeutung. Weitere Betreiber werden über ein
lokales Textsuchfeld gefunden; beide Wege erlauben Mehrfachauswahl. „Nur
Favoriten anzeigen“ ergänzt die Auswahl als lokaler Stationsankerfilter.
Änderungen werden beim Verlassen über Zurück übernommen. „Abbruch“ stellt den
Stand beim Öffnen wieder her, „Standard herstellen“ alle definierten
Standardwerte; beide Aktionen lassen die Seite offen. Ein Badge am Filterknopf
macht abweichende aktive Filter sichtbar.

M9.1 ergänzt eine kompakte Karte „Ausstattung“ mit Restaurant, Shop,
Kaffeeautomat, Snackautomat und Toilette. Jede Zeile ist unabhängig anwählbar;
alle ausgewählten Merkmale müssen gemeinsam als vorhanden geprüft sein. Ein
Hinweis erklärt, dass fehlende Angaben als unbekannt gelten. Eine aktive
Infrastrukturauswahl zählt im Badge als eine zusätzliche Filterkategorie und
wird von „Abbruch“ und „Standard herstellen“ wie die übrigen Filter behandelt.

Favorisierte Gruppen verwenden auf der Karte einen grünen Marker mit dem
SF-Symbol `bolt.heart.fill`; falls das Symbol auf einer unterstützten
iOS-Version fehlt, dient `heart.fill` als Fallback. Normale Marker behalten den
Blitz. Favoriten erhalten eine hohe Darstellungspriorität und nehmen nicht am
MapKit-Clustering teil, damit sie auch in größeren Kartenausschnitten als
eigene Marker erkennbar bleiben.
Bei sich überdeckenden Gruppen erhält der Favoritenmarker die maximale native
Z-Priorität, sodass ein benachbarter Standardmarker das Herz nicht verdeckt.

Die Anschlussauswahl zeigt Steckertypen in kompakten, einzeiligen
Auswahlzeilen mit stark reduziertem vertikalem Zwischenraum. Die gesamte Zeile
bleibt auswählbar.

M6 ergänzt eine opake Suchseite für Ort, Adresse und Ladeparkname. Die Seite
kennzeichnet die Auflösung freier Ortsnamen durch Apple Maps als online.
Direkte Koordinaten und auswertbare Apple-/Google-Maps-URLs verwenden dasselbe
Eingabefeld. Nach der Ortsauflösung bleibt die Karte auf dem Ort zentriert und
zeigt mindestens den nächsten lokal gefundenen Ladepark, der die aktiven Filter
erfüllt. Der Standortknopf öffnet zunächst eine opake
Radiusauswahl für 5, 10, 25, 50 oder 100 Kilometer; erst danach fordert iOS die
Standortberechtigung an. Der Deutschlandknopf beendet eine aktive
Umkreissuche.

Seit M9.2 steht dieselbe Auswahl zusätzlich im Filterbildschirm als
„Entfernung zum aktuellen Standort“ bereit. „Nicht begrenzen“ ist der
Standard. Aktivieren oder Ändern wird beim Verlassen über Zurück übernommen und
fordert erst dann die aktuelle Position an; bei verweigerter Berechtigung
bleibt der vorherige Filterstand erhalten. Ein aktiver Radius zählt im
Filter-Badge als eigene Kategorie und erscheint zusätzlich im Status-Chip der
Karte. „Abbruch“ und „Standard herstellen“ behandeln ihn wie alle übrigen
Filter.

M9.3 ergänzt den Schalter „Nur durchgehend zugängliche Ladeangebote“. Der
Hilfetext macht deutlich, dass die erforderlichen Ladepunkte laut Datenquelle
rund um die Uhr zugänglich sein müssen. Der Schalter zählt als eigene
Filterkategorie, wird per UND mit allen übrigen Kriterien verknüpft und folgt
der bestehenden Zurück-, Abbruch- und Standard-Logik.

Die Ladepunktmatrix der Detailseite verwendet stark reduzierte vertikale
Zellabstände. Betreiberbezeichnungen stehen horizontal und mehrzeilig in einer
kompakten Kopfzeile und werden bei Überlänge gekürzt; der vollständige Name
bleibt als Tooltip zugänglich. Betreiberspalten besitzen unabhängig von der
Länge des Betreibernamens eine einheitliche kompakte Breite.

M12 ergänzt in den Einstellungen eine eigene opake Seite „Datenschutz und
Diagnose“. Kurze Karten unterscheiden fehlende Telemetrie, lokale Daten und
bewusste externe Netzwerkzugriffe. Ein sichtbarer Diagnosestatus kann nur über
eine beschriftete Schaltfläche kopiert werden; die App bietet keine
Einwilligung für einen nicht vorhandenen Dienst an.

## 2. Kartenverhalten und Performance

- Apple MapKit ist der Kartenadapter der iPhone-Version 1.0.
- Verschieben, Pinch-Zoom, Rotation und Neigung werden als native
  MapKit-Gesten vollständig an den Platform View weitergeleitet.
- Ein sichtbarer, zugänglicher „Deutschland anzeigen“-Button stellt jederzeit
  die definierte Ausgangsansicht wieder her.
- Eine MapKit-Markergruppe ist nur eine visuelle Verdichtung und niemals eine
  fachliche `proximity_group`.
- Kartenabfragen verwenden den sichtbaren Ausschnitt zuzüglich ungefähr 15 %
  Rand und liefern höchstens 500 kompakte Gruppen.
- Erreicht eine Abfrage das Limit, zeigt die Statusanzeige `500+` statt eine
  vermeintlich vollständige Trefferzahl.
- Eine Abfrage startet ungefähr 300 ms nach einer Unterbrechung oder dem Ende
  einer Kartenbewegung. Veraltete Ergebnisse werden verworfen.
- Niedrige Zoomstufen verwenden Marker-Clustering; die Auswahl eines Clusters
  zoomt ein, die Auswahl einer Abstandsgruppe öffnet Details.
- Marker werden anhand ihrer `group_id` differenziell hinzugefügt, entfernt
  oder beibehalten, statt die gesamte Ebene neu aufzubauen.
- Detailinformationen werden erst nach der Auswahl nachgeladen.
- Kartenbereichsabfragen verwenden `proximity_group_geo`; dessen
  R*Tree-Tauglichkeit und Laufzeit werden mit dem vollständigen Datensatz und
  später auf einem Referenz-iPhone geprüft.

Die Werte 15 %, 300 ms und 500 Treffer sind Startwerte. Änderungen aufgrund
von Gerätetests werden gemessen und in diesem Dokument nachgeführt.
