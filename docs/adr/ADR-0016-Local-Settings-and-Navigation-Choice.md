# ADR-0016 – Lokale Einstellungen und Wahl der Navigations-App

Status: Angenommen

Datum: 27. August 2026

## Kontext

FR-I18N-001 verlangt eine von der Systemsprache unabhängige Sprachwahl.
FR-NAV-001 verlangt Apple Maps, das installierte Google Maps und einen
verständlichen Fallback. Diese Präferenzen dürfen weder vom austauschbaren
Ladebestand abhängen noch ein Konto oder Backend voraussetzen.

## Entscheidung

- Sprache und bevorzugte Navigations-App werden in einer eigenen,
  schema-versionierten SQLite-Datei im Application-Support-Verzeichnis
  gespeichert.
- Unterstützte Sprachwerte sind Systemsprache, Deutsch und Englisch. Bei einer
  nicht unterstützten Systemsprache verwendet die App Deutsch.
- Unterstützte Navigationswerte sind „jedes Mal fragen“, Apple Maps und Google
  Maps. Der Standard ist „jedes Mal fragen“.
- Google Maps wird auf iOS über `canOpenURL` und das registrierte
  `comgooglemaps`-Schema erkannt. Die App übergibt nur die Zielkoordinaten und
  den Fahrmodus.
- Ist Google Maps nicht installiert, wird es nicht als neue Präferenz
  angeboten. Ist es nach einer früheren Auswahl nicht mehr verfügbar, fragt
  die App vor dem Öffnen von Apple Maps nach.
- Persistenz, Zustand und native Navigation bleiben hinter getrennten
  Repository- beziehungsweise Adapterverträgen.

## Folgen

Einstellungen überleben App-Neustarts und Datensatzwechsel, werden aber bei
einer Deinstallation entfernt. Eine spätere Erweiterung um Update- und
Datenschutzeinstellungen kann dasselbe Schlüssel-Wert-Schema migrationssicher
verwenden. Apple Maps bleibt der verfügbare iOS-Fallback; die eigentliche
Navigation ist weiterhin keine Funktion des Ladepark Explorers.

## Nachtrag – persistente Kartenfilter

`FR-FILTER-001` verlangt, dass die Filterauswahl der Kartenansicht einen
App-Neustart überlebt. Sie wird in derselben lokalen Einstellungsdatenbank
gespeichert wie App-Einstellungen und Fahrzeugprofil (`ADR-0021`):

- Ein eigener Vertrag `ExplorerFiltersRepository` (`loadFilters` /
  `saveFilters`) trennt die Persistenz vom Zustand, analog zum
  Fahrzeugprofil. `SqliteSettingsRepository` implementiert ihn zusätzlich.
- Der Filterstand wird als ein JSON-Wert unter dem Schlüssel
  `explorer_filters` in der bestehenden Tabelle `app_setting` abgelegt. Es
  entsteht keine neue Tabelle und keine neue Schemaversion.
- Der transiente Filter „Entfernung zum aktuellen Standort“
  (`nearbyRadiusKm`) wird bewusst nicht gespeichert: er setzt einen aktuellen
  Standort voraus, der beim Start nicht vorliegt.
- Das Speichern ist „best effort“ – schlägt es fehl, bleibt der Filter im
  Speicher wirksam; die Kartenabfrage wird davon nicht beeinträchtigt.
- Unbekannte Enum-Werte (etwa eine später entfernte Infrastrukturkategorie)
  werden beim Laden verworfen, fehlende Felder fallen auf den Standard zurück.

## Nachtrag – Übergabe der geplanten Route an eine Navigations-App

`FR-ROUTE-011` verlangt, die geplante Route einschließlich Ladestopps an die
gewählte Navigations-App zu übergeben. Dieselbe Navigationswahl wie für ein
einzelnes Ziel gilt weiter; die App-Auswahl (`resolveNavigationAdapter`) ist
aus der Detailansicht in eine gemeinsame Hilfsfunktion gezogen.

- Der `NavigationAdapter`-Vertrag erhält `openRoute(NavigationRoute)` neben dem
  bestehenden `openDirections`. `NavigationRoute` trägt Start, geordnete
  Ladestopps und Ziel als reine Koordinaten mit optionalem Namen.
- **Apple Maps** bekommt die vollständige Kette als geordnete Liste von
  `MKMapItem` über `MKMapItem.openMaps(with:launchOptions:)` im Fahrmodus.
- **Google Maps** wird über den universellen Verzeichnis-Link
  `https://www.google.com/maps/dir/?api=1&origin=…&destination=…&waypoints=…`
  geöffnet; bei installierter App fängt diese den Link ab. Der Link nimmt eine
  begrenzte Zahl Wegpunkte, daher werden höchstens acht Zwischenstopps (die
  ersten Richtung Ziel) übergeben.
- Der Adapter meldet über `NavigationHandoff`, wie viele Stopps tatsächlich
  übergeben wurden. Wurde gekürzt, erklärt die Oberfläche das mit einem
  kurzen Hinweis.
- Es werden weiterhin nur Zielkoordinaten übergeben, kein Konto und kein
  Backend; die eigentliche Navigation bleibt Sache der Ziel-App.
