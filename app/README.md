# Ladepark Explorer App

Flutter-App für den iPhone-zentrierten Wurf A. Das Projekt führt ein
Android-Gerüst mit, die erste Kartenimplementierung verwendet jedoch Apple
MapKit.

## Voraussetzungen

- Flutter 3.44.8 Stable mit Dart 3.12.2,
- Xcode 16.2 mit iOS-18.3-Simulatorruntime,
- CocoaPods 1.17.0 als Fallback für Plugins ohne Swift-Package-Unterstützung,
- später Android Studio und Android SDK für Android-Builds.

Die iOS-Toolchain ist auf dem Entwicklungs-Mac vollständig eingerichtet. Der
Simulator-Build wurde mit Flutter 3.44.8 und Xcode 16.2 verifiziert.

## Im iPhone-Simulator starten

Aus dem Repository-Stamm:

```text
./tooling/run_ios_simulator.sh
```

Das Skript startet standardmäßig den Simulator `iPhone 16`, wartet auf dessen
Bereitschaft und führt `flutter run` aus. Ein anderes vorhandenes Gerät kann
übergeben werden:

```text
IOS_SIMULATOR_DEVICE="iPhone SE (3rd generation)" \
  ./tooling/run_ios_simulator.sh
```

`r` löst im laufenden Terminal Hot Reload aus, `R` einen Hot Restart und `q`
beendet die Flutter-Sitzung. Der Simulator kann geöffnet bleiben.

Die Toolchain lässt sich separat prüfen:

```text
./tooling/check_ios_toolchain.sh
```

Ein einmaliger nicht-residenter Starttest ist auch direkt möglich:

```text
cd app
flutter run -d "iPhone 16" --no-resident
```

Ein inzwischen behobener Freeze trat auf, wenn Flutter-Details wiederholt als
sichtbares Panel über dem nativen MapKit-View geöffnet und geschlossen wurden.
Die Erkenntnisse und die Entscheidung für eine opake Vollbildroute sind in
ADR-0011 dokumentiert. Die dafür angelegten temporären Diagnosemodi wurden nach
erfolgreichem Regressionstest wieder entfernt.

## Struktur

```text
lib/
├── app/                    App-Komposition und Theme
├── data/charging/sqlite/   read-only SQLite-Repository und Isolate
├── features/
│   └── explorer/
│       ├── application/  Riverpod-Kartenstatus und Koordination
│       ├── domain/         Modelle und ChargingRepository-Vertrag
│       └── presentation/   datengetriebene Kartenoberfläche
├── platform/
│   └── maps/               Kartenvertrag und Dart-MapKit-Adapter
└── l10n/                   deutsche und englische ARB-Dateien
```

Konkrete Adapter werden bei ihrer Implementierung unter `data/` beziehungsweise
`platform/` ergänzt. Suche, Filter, Karte und Details bleiben zunächst im
gemeinsamen Feature `explorer`.

Der SQLite-Adapter ist implementiert. Er hält genau eine read-only Verbindung
in einem langlebigen Hintergrund-Isolate, validiert Schemaversion und
Datensatzmetadaten und liefert ausschließlich typisierte Domainobjekte. Die UI
enthält kein SQL. Kartenabfragen sind im Domainvertrag auf höchstens 500
kompakte Ergebnisse begrenzt.

Der native MapKit-Adapter ist seit M3 implementiert. Kartenbewegungen werden
mit 300 ms Verzögerung und 15 Prozent Rand gegen SQLite abgefragt; veraltete
Ergebnisse werden verworfen. Marker werden differenziell aktualisiert und
visuell geclustert. Die Auswahl lädt kompakte Details auf eine opake,
vollständig deckende Flutter-Seite ohne Übergangsanimation.

M5 aktiviert den Filterknopf in der App-Leiste. Auf einer vollständig
deckenden Seite lassen sich Gruppendurchmesser, die gekoppelte Bedingung
„Mindestens N Ladepunkte mit jeweils mindestens P kW“, Betreiber und
Anschlüsse kombinieren. Ladepunkte unter P kW werden nicht auf N angerechnet.
Die 20 größten kuratierten Betreiber werden alphabetisch in kompakten
Einzeilern angezeigt;
ihre Ladepunktzahl steht in Klammern und wird durch einen einmaligen Hinweis
erklärt. Weitere Quellnamen sind ab zwei Zeichen lokal durchsuchbar. Betreiber
und Anschlüsse unterstützen Mehrfachauswahl. Ein Badge kennzeichnet vom
Standard abweichende Filter; „Standard herstellen“ stellt 50 Meter
Gruppendurchmesser und mindestens 20 Ladepunkte mit jeweils mindestens 100 kW
wieder her.

Ohne vorbereiteten Deutschlandbestand verwendet der installierbare Prototyp
`assets/datasets/charging-2026.07.0-contract.sqlite3`, eine Kopie der kleinen
gemeinsamen Contract-Fixture mit synthetischen Standorten in Berlin und
München.

## Vollständigen Deutschlandbestand einbinden

Aus dem Repository-Stamm:

```text
./tooling/prepare_app_dataset.sh
./tooling/run_ios_simulator.sh
```

Das erste Skript validiert standardmäßig
`data/output/charging-de-2026.07.0.sqlite3` und kopiert es nach
`app/assets/generated/charging-de.sqlite3`. Diese große Datei ist
git-ignoriert. Auf iOS öffnet SQLite sie direkt read-only aus dem App-Bundle.
Ist sie nicht vorhanden, verwendet die App weiterhin die Contract-Fixture.

M8 ergänzt daneben einen kleinen, getrennten redaktionellen Bestand. Er wird
mit `./tooling/prepare_park_info_dataset.sh` aus der geprüften JSON-Pflegequelle
und den veröffentlichungsfertigen eigenen Bildern vorbereitet. Die App öffnet
`park-info.sqlite3` read-only und löst einen Eintrag über alle stabilen
Stations-IDs der aktuell dargestellten Abstandsgruppe auf. Ein fehlender
Eintrag bleibt unsichtbar; er bedeutet nicht, dass Infrastruktur fehlt.

M4 zeigt auf der Detailseite Adresse, Aggregate, Leistungsklassen,
Betreiber, Anschlüsse, Öffnungszeiten und Datenquelle. „Route in Apple Maps“
übergibt die Ankerkoordinaten als Fahrziel.

Der vollständige Inhalt ist scrollbar. Die Seite verdeckt den nativen
MapKit-View vollständig und wird ohne Übergangsanimation geöffnet, damit keine
sichtbare Hybrid-Komposition zwischen Karte und Flutter-Details entsteht.
Lange Betreiber-, Anschluss- und Quelldaten bleiben auch auf kleineren Displays
ohne Layout-Overflow zugänglich.

Mehrere Betreiber eines Ladeparks erscheinen als Spalten einer kompakten,
horizontal scrollbar dargestellten Matrix. Die acht Zeilen enthalten
disjunkte Leistungsbereiche; pro Zelle werden Steckertyp und Zahl der
unterschiedlichen Ladepunkte gezeigt. Stationszahlen entfallen. Geprüfte
Betreiber verwenden den kuratierten Anzeigenamen; ungeprüfte Namen bleiben in
der BNetzA-Schreibweise sichtbar.

Die Datenzeilen verwenden nur wenige Pixel Innenabstand. Horizontale,
mehrzeilige und gegebenenfalls gekürzte Betreiberköpfe beeinflussen die
einheitlich kompakte Spaltenbreite nicht.

## Kartenbedienung

- Die Lupe öffnet die Suche nach Ort, Adresse oder Ladepark. Apple Maps löst
  freie Ortsnamen online in eine Koordinate auf; anschließend sucht die App im
  lokalen Bestand den nächsten Ladepark, der die aktiven Filter erfüllt. Der
  Kartenausschnitt bleibt auf dem gesuchten Ort zentriert und wird bis zum
  nächsten Treffer erweitert. Bei fehlendem Netz bleibt der lokale FTS-Index
  als Fallback verfügbar. Das Feld akzeptiert außerdem
  `Breitengrad,Längengrad` sowie direkte Apple- oder Google-Maps-URLs, sofern
  diese die Koordinaten enthalten.
- Der Standortknopf bietet 5, 10, 25, 50 und 100 km Umkreis und fordert die
  iOS-Berechtigung erst nach der Radiusauswahl an.
- Ziehen verschiebt die Karte.
- Pinch zoomt hinein und heraus; im Simulator wird die zweite Berührung mit
  gedrückter `⌥`-Taste erzeugt.
- Doppeltippen zoomt hinein, ein Zwei-Finger-Tipp zoomt heraus.
- Der Button mit den vier nach außen gerichteten Pfeilen stellt die
  Deutschlandansicht wieder her.

Eine Koordinate kann auch per App-Link geöffnet werden:

```text
ladeparkexplorer://location?lat=53.5511&lon=9.9937
```

Apple Maps und Google Maps bieten keinen gemeinsamen direkten
Rückübergabestandard an Dritt-Apps. Eine spätere iOS Share Extension kann den
Ladepark Explorer im Teilen-Menü ergänzen; verkürzte Google-Links benötigen
zudem eine Online-Auflösung.

Der UIKit Platform View übernimmt die Zeigersequenz ausdrücklich, sodass
MapKits Mehrfinger-Gesten nicht von der Flutter-Gesture-Arena blockiert werden.

Bei schnellen Kartenbewegungen lässt die App höchstens eine SQLite-Abfrage und
ein natives Markerupdate gleichzeitig laufen. Wartende Zwischenstände werden
durch den jeweils neuesten Ausschnitt beziehungsweise Markerzustand ersetzt.
Debug-Ausgaben mit dem Präfix `[LadeparkMap]` zeigen die gemessenen Laufzeiten
und ob Folgearbeit wartet.

## Favoriten

Das Herz in den Ladeparkdetails speichert oder entfernt einen Favoriten. Das
Herz in der oberen Leiste öffnet die lokale Favoritenliste. Favoriten liegen in
einer getrennten schreibbaren Datenbank im Application-Support-Verzeichnis und
werden über eine stabile Stations-ID mit der aktuellen Abstandsgruppe
verbunden. Fehlt die Station in einem späteren Datensatz, bleibt der Eintrag als
„nicht verfügbar“ sichtbar und kann weiterhin entfernt werden. Es gibt weder
ein Benutzerkonto noch eine Synchronisation zwischen Geräten.

Die Filterseite bietet zusätzlich „Nur Favoriten anzeigen“. Dieser Filter wird
mit allen übrigen Kriterien verknüpft; ohne gespeicherte Favoriten bleibt die
Karte leer. Änderungen werden beim Verlassen der Seite über Zurück übernommen.
„Abbruch“ stellt den Filterstand beim Öffnen wieder her, „Standard herstellen“
die Produktvorgaben. Beide Schaltflächen lassen die Filterseite geöffnet.

Favorisierte Ladeparks erscheinen auch in der normalen Kartenansicht mit einem
grünen Herz-Blitz-Marker. Die Zuordnung entsteht gemeinsam mit der vorhandenen
Gruppenabfrage; pro Marker wird nur der Favoritenstatus zusätzlich an MapKit
übertragen. Favoriten nehmen nicht am MapKit-Clustering teil und bleiben daher
auch in größeren Kartenausschnitten als eigene Marker sichtbar.
Bei nahezu überlappenden Gruppen wird der Favoritenmarker mit maximaler
MapKit-Z-Priorität vor einem Standardmarker gezeichnet.

Entschieden sind direkter `sqlite3`-Zugriff in einem Hintergrund-Isolate und
Riverpod für State Management und Composition. Die native Karte wird als
eigener `MKMapView`-Platform-View umgesetzt. Details stehen in ADR-0008 und
ADR-0009.

Die App und der Python-Importer verwenden den gemeinsamen Vertrag unter
`../contracts/charging_dataset/v2/`. Eine Architekturprüfung verhindert
Importe aus `data`, `platform` oder `presentation` in Domaincode.

## Prüfen

```bash
cd app
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed lib test
flutter analyze
flutter test
```

Ein iOS-Build ist erst nach Installation und Ersteinrichtung des vollständigen
Xcode möglich.
