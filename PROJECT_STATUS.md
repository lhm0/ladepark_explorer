# Projektstatus – Ladepark Explorer

Stand: 28. August 2026

## Aktueller Zustand

- Git-Repository ist auf dem Branch `main` initialisiert.
- Der erste ausführbare Importer-Stand liegt unter `importer/` vor:
  - projektlokale Python-3.12-Umgebung mit `uv` und Lockdatei,
  - CLI-Befehl `inspect` für lokale CSV- und XLSX-Quelldateien,
  - Prüfung des BNetzA-Spaltenvertrags und nummerierter Ladepunktfelder,
  - Normalisierung und Validierung zentraler Text-, Zahlen- und
    Koordinatenwerte,
  - typisierte Stations-, EVSE- und Connectorobjekte,
  - deterministische UUIDv5-IDs für Stationen, EVSEs und Connectoren,
  - versionierte Connector-Zuordnung; unbekannte Typen werden erhalten und
    als Review-Warnung ausgegeben,
  - konservative Betreiberbehandlung: Quellname bleibt erhalten, aber ohne
    Registereintrag entsteht keine automatische Betreiberidentität,
  - CLI-Befehl `normalize` für eine deterministisch sortierte JSON-Ausgabe,
  - CLI-Befehl `report` für einen kompakten Normalisierungs- und
    Qualitätsbericht,
  - CLI-Befehl `operator-review` für eine nach Ladepunktzahl priorisierte,
    deterministische Prüfliste aller Betreiber-Quellnamen; ähnliche Namen
    bleiben unverbindliche Kandidaten und werden nicht automatisch vereinigt,
  - JSON-Prüfbericht mit SHA-256, Zeilen-, Stations- und Ladepunktanzahl,
    unbekannten Spalten und Warnungen.
- Der Importer ist entlang wachsender Verantwortlichkeiten modularisiert:
  - `commands/` trennt Unterbefehle von der Argumentdefinition,
  - `pipeline/` orchestriert den vollständigen Charging-Datensatzbuild,
  - `charging_sqlite/` trennt Schema, Modelle, Writer, Validator und
    Referenzabfragen,
  - bisherige SQLite-Importpfade bleiben als Kompatibilitätsfassaden erhalten.
- Ein kleiner synthetischer BNetzA-Testdatensatz ist vorhanden. Ein echter
  Deutschlanddatensatz wird lokal unter `data/raw/` verwendet, aber bewusst
  nicht in Git gespeichert.
- Der vollständige Inspector-Lauf über die BNetzA-CSV vom 7. Juli 2026 ist
  erfolgreich:
  - 113.385 Stationen,
  - 204.078 Ladepunkte,
  - sechs mögliche Ladepunktslots,
  - keine unbekannten Spalten oder Mengenwarnungen,
  - SHA-256
    `dbc3a36f48b23759778addb5f7ef2a922e81a3924cca285a78838ecce99fdcc6`.
- Der vollständige Normalisierungslauf über denselben Snapshot ist erfolgreich:
  - 204.078 EVSEs, davon 151.120 AC und 52.958 DC,
  - 214.785 Connectoren und keine unbekannten Connector-Typen,
  - 3.500 unbrauchbare sowie 1.101 mehrfach vorkommende EVSE-IDs mit
    Slot-Fallback,
  - 120 fehlende Hausnummern,
  - eine uneindeutige Connector-Leistungszuordnung,
  - 11.910 Betreiber-Quellnamen ohne Betreiberregister.
- Der erste vollständige Betreiber-Review-Export ist erzeugt:
  - 11.910 nach EVSE-Zahl sortierte Quellbezeichnungen,
  - direkte Stations-, EVSE-, AC-, DC- und HPC-Zählung ohne Mehrfachzählung
    der fünf Gruppendurchmesser,
  - technische Normalisierungs- und Vergleichsschlüssel sowie bis zu fünf
    unverbindliche ähnliche Quellnamen,
  - 1,8 MB unter `data/output/operator-review-2026-07-07.csv`,
  - SHA-256
    `f4c348dfa19d005e48d55752ea895c672c3f3ffaf1e01fa6ef4e8a579578b5cf`.
- Der kontrollierte Betreiber-Reviewkreislauf ist implementiert:
  - `operator-worklist` erzeugt Top-N-Arbeitslisten einschließlich ähnlicher
    Quellnamen, aber ohne automatische Identitätsentscheidung,
  - `config/operators.json` ist das versionierte Register für explizit
    geprüfte kanonische Betreiber und exakte BNetzA-Aliase,
  - stabile `operator_id`s entstehen aus Operator-Namespace und unveränderlichem
    `registry_key`,
  - `operator-registry-validate` weist unbekannte oder mehrfach zugeordnete
    Aliase und unvollständige Entscheidungen zurück,
  - `operator-coverage` berichtet die Abdeckung nach Quellnamen, Stationen und
    EVSEs.
  - die erste Top-20-Arbeitsliste enthält 20 Rangnamen und drei automatisch
    gefundene Reviewkandidaten unter
    `data/output/operator-worklist-top20-2026-07-07.csv`,
  - SHA-256 der Arbeitsliste:
    `ac07290ca8726bd8f06987bb7c710b2ff7ee2f07bad5968207d962e0cc1f1f8e`,
  - Version 1 des Registers enthält die 20 manuell bestätigten Hauptzeilen mit
    kurzen Anzeigenamen; `BP Europa SE` erscheint als „Aral pulse“ und
    `Shell Deutschland GmbH` als „Shell Recharge“,
  - die drei Ähnlichkeitskandidaten `Mercedes-Benz Heritage GmbH`,
    `Mercedes-AMG GmbH` und `Hamburger Energiewerke GmbH` wurden geprüft und
    bewusst als eigenständige Betreiber aufgenommen,
  - das Register ist gegen den vollständigen Snapshot gültig und deckt 32.036
    Stationen sowie 57.368 von 204.078 EVSEs (28,11 Prozent) ab,
  - SHA-256 des Registers:
    `ae7f900bd585f32fe6af6994a639ea75bb9e59038002f7ba352aeb3ace3987f0`.
- Die deterministische Complete-Linkage-Abstandsgruppierung ist implementiert:
  - Haversine-Distanz und verlustfreie räumliche Kandidatensuche,
  - Gruppen-ID, Ankerstation und Medoid,
  - alle zehn spezifizierten Referenzfälle als Tests,
  - CLI-Befehl `cluster-report`,
  - CSV-Befehl `cluster-review` für die gemeinsame Top-N-Prüfliste nach
    Stations-, EVSE- und HPC-Zahl,
  - vollständige Deutschlandläufe für 25, 50, 100, 200 und 300 Meter.
- Beim Standardwert 50 Meter entstehen 59.237 Gruppen, davon 19.339 mit
  mehreren Stationen. Keine Gruppe überschreitet den konfigurierten
  Maximaldurchmesser.
- Der erste 50-Meter-Review-Export enthält 221 Gruppen aus den Top 100 der drei
  Kategorien. Er bestätigt plausible HPC-Kandidaten und macht große reine
  AC-/Werksgruppen sowie identische Massenkoordinaten sichtbar.
- Der vollständige `charging.sqlite`-Build ist implementiert und
  validiert:
  - 266.971 Gruppen und 566.925 Mitgliedschaften für fünf Durchmesser,
  - FTS5-, Stations- und Gruppen-R*Tree-Indizes,
  - sparse Leistungsbänder, Betreiber-Quell-, kanonische Betreiber- und
    Connector-Gruppenaggregate,
  - materialisierte direkte Betreiberstatistik für die Top-20-Auswahl,
  - BNetzA-Provenienz und Lizenzmetadaten,
  - 386 MB unkomprimiert,
  - SHA-256
    `5ee622d1a8b01c1b79c0322d270f0b726dd0ca9404fd5d1fbaafa771b7fdcdce`.
- Das erste Flutter-App-Gerüst liegt unter `app/` vor:
  - Flutter 3.44.8 Stable und Dart 3.12.2,
  - iOS 14 als Mindestversion und Android API 24 als vorbereitete Untergrenze,
  - getrennte App-, Domain-, Feature- und Adaptergrenzen,
  - `ChargingRepository`-Vertrag und typisierte Kartenabfrage mit maximal
    500 kompakten Ergebnissen,
  - plattformneutraler Kartenadapter-Vertrag,
  - datengetriebene Wurf-A-Karte mit deutscher und englischer Lokalisierung.
- Die App besitzt eine Riverpod-Composition-Root und einen produktiven
  `SqliteChargingRepository`-Adapter:
  - genau eine langlebige SQLite-Verbindung in einem Hintergrund-Isolate,
  - ausschließlich read-only geöffneter Ladebestand,
  - Schema-v2- und Metadatenvalidierung beim Öffnen,
  - Kartenfilter für Ausschnitt, Gruppendurchmesser, Mindestanzahl,
    Leistungsband, Betreiber, Connector und lokale FTS-Suche,
  - typisiertes Mapping kompakter Gruppen und nachgeladener Details,
  - stabile Fehlerkategorien für fehlende oder inkompatible Datenbanken,
    ungültige Abfragen sowie Repository-/Isolate-Fehler.
- Die MapKit-Anbindung ist als eigener UIKit Platform View mit `MKMapView`
  implementiert:
  - sichtbare Bounds und Markerauswahl über einen kleinen Method-Channel-Vertrag,
  - 300-ms-Debounce und 15 Prozent Abfragerand,
  - Verwerfen veralteter Abfrageergebnisse,
  - differenzielle Markeraktualisierung anhand `group_id`,
  - natives MapKit-Clustering und HPC-Hervorhebung,
  - nachgeladene Gruppendetails auf einer vollständig deckenden Flutter-Seite.
  - explizite Übergabe nativer Scroll-, Pinch-, Rotations- und
    Neigungsgesten an MapKit,
  - sichtbarer „Deutschland anzeigen“-Button als verlässlicher Rückweg zur
    Ausgangsansicht.
- Die Kartenpipeline ist gegen Rückstau bei schnellen Zoom- und
  Verschiebefolgen stabilisiert:
  - höchstens eine laufende SQLite-Kartenabfrage,
  - Latest-wins-Zusammenfassung wartender Bounds und Markerzustände,
  - Ignorieren nahezu identischer Bounds,
  - keine Übergabe veralteter Abfrageergebnisse an MapKit,
  - Debug-Zeitmessungen für Datenbank- und Markerarbeit.
- Die Detailansicht ist für begrenzte iPhone-Höhen und den nativen
  Platform-View-Lebenszyklus stabilisiert:
  - vollständig deckende, opake Route ohne Übergangsanimation, sodass MapKit
    nicht gleichzeitig mit einer Flutter-Überlagerung dargestellt wird,
  - vollständiger Detailinhalt gemeinsam scrollbar,
  - der reproduzierte 39-Pixel-`RenderFlex`-Overflow ist durch einen
    Widgettest mit 373 Pixel verfügbarer Höhe abgedeckt,
  - vier aufeinanderfolgende Öffnen-/Zurück-Zyklen sind als Widgettest
    abgedeckt.
- Die abgeschlossene A/B-Diagnose hat SQLite-Details, die Detailinhalte und die bloße
  Einbettung des UIKit Platform Views als alleinige Freeze-Ursache
  ausgeschlossen. Der reine native Markertap samt Method-Channel-Meldung war
  bei vollständig unterdrückter Detailansicht beliebig oft stabil. Damit ist
  die problematische Kombination auf einen nativen Touch im Platform View und
  das anschließende Einfügen beziehungsweise Entfernen einer sichtbaren
  Flutter-Überlagerung eingegrenzt.
- Die daraus abgeleitete Korrektur öffnet Details auf einer opaken
  Vollbildroute ohne Animation. Der normale Produktpfad wurde am 24. August
  2026 im iPhone-16-Simulator wiederholt ohne Freeze oder sonstige Probleme
  geprüft. Die temporären Diagnosepfade wurden anschließend aus Dart, Swift,
  Tests, Startskript und Anwenderdokumentation entfernt.
- Die lokale iOS-Entwicklungsumgebung ist vollständig verifiziert:
  - Xcode 16.2, Build `16C5032a`,
  - iOS-18.3-Simulatorruntime und CocoaPods 1.17.0,
  - erfolgreicher Simulator-Build einschließlich nativer `sqlite3`-Hooks,
  - erfolgreiche Installation und Ausführung auf einem simulierten iPhone 16,
  - wiederholbarer Start über `tooling/run_ios_simulator.sh`.
- Die App-Struktur trennt App-Komposition, das Feature `explorer` und
  Plattformadapter. Eine automatisierte Architekturprüfung schützt den
  Domaincode vor Abhängigkeiten auf Daten-, Plattform- und UI-Implementierungen.
- Ein ausführbarer sprachübergreifender Schema-v2-Vertrag liegt unter
  `contracts/charging_dataset/v2/`:
  - deterministische SQLite-Fixture aus der synthetischen BNetzA-Quelle,
  - versionierte Abfrageparameter und erwartete Gruppen-IDs,
  - gemeinsame Verwendung durch Python- und Flutter-Tests.
- Ein GitHub-Actions-Workflow für Importer-, Flutter-, Contract-, Architektur-,
  Dokumentations- und iOS-Simulator-Buildprüfungen ist konfiguriert. Der
  Workflow ist lokal abgebildet, aber noch nicht auf GitHub ausgeführt.
- Der App-Implementierungsmeilenstein M2 ist abgeschlossen. Die sechs neuen
  Adaptertests verwenden dieselbe Schema-v2-Fixture wie Python und prüfen
  Contract-Ergebnisse, kombinierte Filter, Details, Read-only-Verhalten und
  Fehlerfälle.
- Der App-Implementierungsmeilenstein M3 ist abgeschlossen. Riverpod,
  SQLite-Repository und nativer MapKit-Platform-View bilden einen sichtbaren
  vertikalen Kartenfluss. Der installierbare Prototyp bündelt bewusst nur die
  kleine Schema-v2-Contract-Fixture mit synthetischen Standorten in Berlin und
  München; der vollständige Deutschlandbestand ist noch kein App-Asset.
- Der App-Implementierungsmeilenstein M4 ist abgeschlossen:
  - `tooling/prepare_app_dataset.sh` validiert und kopiert einen lokalen
    Deutschlandbestand als git-ignoriertes App-Asset,
  - iOS öffnet die Datenbank direkt read-only aus dem App-Bundle; ohne
    generiertes Asset bleibt die Contract-Fixture als Fallback aktiv,
  - der vollständige lokale Bestand zeigt in der Deutschlandansicht 500+
    gefilterte Gruppen mit nativen MapKit-Clustern,
  - Details enthalten Adresse, Koordinaten, Aggregate, Leistungsklassen,
    Betreiber, Anschlüsse, Öffnungszeiten, Datenstand und Quelle,
  - Betreiber werden in den Details als Spalten einer horizontal scrollbar
    dargestellten Matrix aufgeschlüsselt; acht disjunkte Leistungszeilen
    enthalten Steckertyp und EVSE-Zahl, Stationszahlen entfallen,
  - stark verdichtete Datenzeilen und horizontale, mehrzeilige Betreiberköpfe
    bleiben durch einheitlich kompakte Spaltenbreiten von langen
    Betreiberbezeichnungen entkoppelt,
  - geprüfte Betreiber verwenden den kuratierten Anzeigenamen, ungeprüfte
    bleiben quellnamenscharf,
  - Apple Maps kann mit Name und Ankerkoordinaten als Fahrziel geöffnet werden.
- Der App-Implementierungsmeilenstein M5 ist implementiert und manuell im
  Simulator abgenommen:
  - unveränderlicher Filterzustand im `ExplorerMapState`,
  - editierbarer Gruppendurchmesser und gekoppelte Bedingung „mindestens N
    Ladepunkte mit jeweils mindestens P kW“; schwächere Ladepunkte werden nicht
    auf N angerechnet,
  - direkt anklickbare Top 20 nach Ladepunktzahl mit kuratierten Anzeigenamen,
  - alphabetische, stark verdichtete Darstellung dieser Auswahl mit der
    Ladepunktzahl in Klammern und einem einmaligen Erklärungstext,
  - lokale Suche weiterer ungeprüfter Betreiber-Quellnamen ab zwei Zeichen,
  - kanonische und quellnamenscharfe Betreiberfilter sowie Connectorauswahl
    mit Mehrfachauswahl in stark verdichteten, vollständig anklickbaren Zeilen,
  - UND-Verknüpfung der Filter und OR-Verknüpfung innerhalb der Mehrfachwerte
    über den bestehenden Queryvertrag,
  - sichtbares Badge für Abweichungen vom Standard und gemeinsames
    Zurücksetzen auf 50 Meter sowie mindestens 20 Ladepunkte mit jeweils
    mindestens 100 kW,
  - opake, animationslose Filterroute zur Vermeidung sichtbarer
    Hybrid-Komposition über MapKit.
- Der App-Implementierungsmeilenstein M6 ist implementiert und automatisiert
  geprüft; die manuelle Abnahme auf Simulator und iPhone steht noch aus:
  - native, als online gekennzeichnete `MKLocalSearch`-Auflösung freier Orts-
    und Adressnamen sowie lokaler FTS-Fallback,
  - lokale Suche des nächsten passenden Ladeparks in wachsenden Radien unter
    Beibehaltung der aktiven Ladefilter,
  - auf dem gesuchten Ort zentrierter Kartenmaßstab, der mindestens den
    nächsten passenden Ladepark umfasst,
  - Eingabe direkter Koordinaten und nicht verkürzter Apple-/Google-Maps-URLs,
  - eigener App-Link `ladeparkexplorer://location?lat=...&lon=...` für Kalt-
    und Warmstart,
  - zweckgebundene iOS-`When In Use`-Standortabfrage erst nach Auswahl von 5,
    10, 25, 50 oder 100 Kilometern,
  - lokale Haversine-Umkreisprüfung nach räumlicher Vorauswahl.
- Der App-Implementierungsmeilenstein M7 ist implementiert und automatisiert
  geprüft:
  - getrennte, schreibbare Schema-v1-Benutzerdatenbank im
    Application-Support-Verzeichnis,
  - lokale Speicherung ohne Konto oder Backend,
  - Favoritenherz in den Ladeparkdetails und eigene Favoritenliste,
  - Kartenfilter „Nur Favoriten“ mit UND-Verknüpfung zu allen weiteren Filtern,
  - grüne Herz-Blitz-Marker für Favoriten auch in der normalen Kartenansicht;
    der Status wird in der bestehenden Gruppenabfrage bestimmt und als ein
    Boolean im differenziellen MapKit-Update übertragen,
  - Favoriten bleiben außerhalb nativer MapKit-Cluster als eigene Marker
    sichtbar; Statuswechsel erzwingen eine unmittelbare Neuklassifizierung,
  - maximale native Z-Priorität schützt Favoritenmarker vor nahezu
    koordinatengleichen Standardmarkern benachbarter Abstandsgruppen,
  - Auflösung über stabile Stationsanker beim aktuell gewählten
    Gruppendurchmesser einschließlich expliziter Stationsaliase,
  - erhaltene und löschbare Darstellungssnapshots für im aktuellen Datensatz
    nicht mehr verfügbare Favoriten.
  - Die Filterseite übernimmt ihren sichtbaren Stand beim Verlassen über
    Zurück; „Abbruch“ stellt den Öffnungsstand und „Standard herstellen“ die
    Produktvorgaben wieder her, ohne die Seite zu schließen.
- Der Spezifikationskern für Version 1.0 ist erstellt und fachlich
  konsolidiert:
  - Produktvision und Scope,
  - funktionale und nicht-funktionale Anforderungen,
  - Systemarchitektur,
  - Domänenmodell und Glossar.
- Die Projektdokumentation ist unter `docs/` geordnet:
  - verbindliche Kapitel unter `docs/specification/`,
  - Architekturentscheidungen unter `docs/adr/`,
  - historische Übergaben und Arbeitsvorschläge unter `docs/archive/`,
  - korrigierter Implementierungsstand für Importer, Clustering und Tests.
- Datenpipeline ist für einen ersten Prototyp spezifiziert:
  - Datenquellen und Lizenzgrenzen,
  - Importer und Qualitätsgates,
  - dynamische Abstandsgruppierung mit zehn Referenzfällen,
  - SQLite-Schema Version 2 mit konservativ normalisierten Öffnungszeiten und
    gekoppelten 24/7-Leistungsaggregaten sowie Manifestvertrag.
- Angenommene ADRs:
  - ADR-0001: Version 1.0 ohne dauerhaftes fachliches Backend,
  - ADR-0002: stabile interne Identitäten,
  - ADR-0003: lizenzsichere Trennung von BNetzA- und OSM-Daten,
  - ADR-0004: dynamische Abstandsgruppen und später bestätigte Ladeparks,
  - ADR-0005: Python-3.12-Toolchain mit uv, pytest, Ruff und Mypy,
  - ADR-0006: Flutter-App mit Apple MapKit für die iPhone-Version 1.0.
  - ADR-0007: modulares Monorepo und versionierter Datensatzvertrag.
  - ADR-0008: direkter SQLite-Zugriff und Riverpod-Komposition.
  - ADR-0009: native MapKit-Integration als iOS Platform View.
  - ADR-0010: git-ignoriertes Packaging und direktes Öffnen des gebündelten
    Basisdatensatzes.
  - ADR-0011: opake, animationslose Vollbildroute für Details über MapKit.
- ADR-0012: getrennter, offline gepflegter redaktioneller
    Ladepark-Informationsbestand mit eigenen Fotos und stabilen
    Stationsreferenzen.
  - ADR-0013: lokale Standortsuche, Umkreisfilter und eingehende
    Direktkoordinaten ohne behaupteten Rückübergabestandard der Kartenanbieter.
  - ADR-0014: getrennter lokaler SQLite-Favoritenspeicher mit stabilen
    Stationsankern.
- Das Lizenz- und Datenquellen-Dossier ist die fortlaufende Basis für die
  finale Lizenzprüfung. Version 1.0 vermeidet bewusst eine Architektur, deren
  Veröffentlichung eine individuelle juristische Einzelfallprüfung voraussetzt.
- Offizielle Betreiberlinks dürfen über einen manuellen Adressabgleich einer
  BNetzA-Station zugeordnet werden. Gespeichert bleibt die BNetzA-Adresse;
  abweichende oder mehrdeutige Fälle benötigen eine Betreiberbestätigung.

## Abgeschlossene App-Meilensteine

**M0 bis M5 – Gerüst, Datenzugriff, Karte, Details und Filter**

Erreicht:

- ausführbares Flutter-Gerüst und verifizierte iOS-Toolchain,
- read-only SQLite-Adapter und gemeinsamer Datensatzvertrag,
- native MapKit-Karte mit Clustern, Zoom und stabilisierter Kartenpipeline,
- scrollbare Ladeparkdetails und Übergabe an Apple Maps,
- vorbereitbarer vollständiger Deutschlandbestand,
- stabiler, manuell geprüfter Detaillebenszyklus über eine opake Vollbildroute.
- editierbare Ladeangebotsfilter einschließlich skalierbarer Betreiberwahl.
- ein Infrastrukturfilter für Restaurant, Shop, Kaffeeautomat, Snackautomat
  und Toilette; mehrere Merkmale werden per UND verknüpft und nur explizit als
  vorhanden geprüfte redaktionelle Angaben erfüllen die Auswahl.
- eine Umkreisbegrenzung von 5, 10, 25, 50 oder 100 Kilometern als Bestandteil
  des gemeinsamen Filterzustands; der aktive Radius ist auf der Karte sichtbar
  und wird mit allen übrigen Kriterien verknüpft.
- ein konservativer Filter für durchgehend zugängliche Ladeangebote; die
  erforderliche Ladepunktzahl und Mindestleistung werden ausschließlich aus
  eindeutig als 24/7 normalisierten Stationen gezählt.

## Nächster Meilenstein

Die offenen App-Meilensteine werden in dieser Reihenfolge bearbeitet:

- M8: der erste Produktbestand ist erzeugt und manuell abgenommen. Emstek,
  Hilden und Kamen enthalten
  zusammen 15 Infrastrukturzustände und sechs eigene, auf 1600 × 1200 Pixel
  optimierte Bilder ohne EXIF-/GPS-Daten. Schema-v1-Build, stabile
  Stationsreferenzen, Review-/Hashprüfung, Contract-Fixture und
  Detaildarstellung sind implementiert. Offen bleibt ein automatisierter
  Bilddarstellungstest als Härtungsaufgabe,
- M9: redaktioneller Infrastrukturfilter, konsolidierte Umkreisbegrenzung und
  strukturierter 24/7-Filter sind implementiert,
- M10 ist implementiert: Deutsch, Englisch und Systemsprache sind unabhängig
  wählbar; eine nicht unterstützte Systemsprache fällt auf Deutsch zurück.
  Sprach- und Navigationswahl liegen in einer eigenständig versionierten
  lokalen SQLite-Datenbank. Apple Maps, Google Maps (wenn installiert) und
  „jedes Mal fragen“ sind auswählbar; fehlt Google Maps später, wird Apple Maps
  als verständliche Alternative angeboten,
- M11 ist implementiert: ein deterministisches gzip-Releasepaket mit
  versioniertem Manifest, öffentliche GitHub-Release-URLs, automatische
  konfigurierbare Manifestprüfung, bestätigter Download mit Fortschritt,
  komprimierte und unkomprimierte SHA-256-Prüfung, SQLite-Integritäts- und
  Metadatenprüfung sowie atomare Aktivierung mit Rollbackbestand. Der erste
  Produktbestand `2026.07.0` ist als Release `dataset-2026.07.0` veröffentlicht;
  Manifest und 182.274.446 Byte großes Archiv wurden am 28. August 2026 über
  die öffentlichen Download-URLs vollständig zurückgelesen und gegen die
  erwartete SHA-256-Prüfsumme verifiziert,
- M12: Datenschutzentscheidung und optionale Diagnostik,
- M13: Release-Härtung und App-Store-Vorbereitung.

## Bekannte offene Entscheidungen

Vor oder während M2:

- mögliche spätere Ergänzung des dateibasierten Adapters um einen
  Bundesnetzagentur-Webservice,
- endgültige Formate der Build-seitigen Register neben der vorhandenen
  Namespace-Konfiguration,
- konkreter OSM-Bulk-Datenanbieter,
- Hosting und Bereitstellungsform des separaten ODbL-Artefakts,
- finaler Connector-Codekatalog,
- Manifest-Signatur.

Für die spätere App:

- Android-Kartenadapter und kontrollierte Kartenversorgung,
- Telemetrieanbieter und zulässige Ereignisse,
- Objektspeicher für Datensatzupdates.

## Bekannte Risiken

- OSM-ODbL-Pflichten müssen vor Veröffentlichung des separaten
  Infrastrukturartefakts anhand der Release-Checkliste praktisch nachgewiesen
  sein.
- Quellschema und neue Bundesnetzagentur-Webserviceschnittstelle können sich
  ändern.
- Fehlende EVSE-IDs schwächen die Identitätsstabilität einzelner Ladepunkte.
- Performance und Ergebnisgrößen der fünf Gruppierungsstufen müssen mit dem
  ersten Deutschlandimport geprüft werden.

## Verifizierbarer Build

Aus dem Repository-Stamm:

```text
cd importer
uv sync
uv run pytest
uv run ruff check .
uv run ruff format --check .
uv run mypy src
uv run ladepark-importer inspect tests/fixtures/bnetza_minimal.csv
uv run ladepark-importer normalize tests/fixtures/bnetza_minimal.csv
uv run ladepark-importer report tests/fixtures/bnetza_minimal.csv
uv run ladepark-importer cluster-report tests/fixtures/bnetza_minimal.csv \
  --dataset-version test-2026-07-07 --diameter 50
uv run ladepark-importer cluster-review tests/fixtures/bnetza_minimal.csv \
  --dataset-version test-2026-07-07 --diameter 50 \
  --limit-per-category 1 --output ../data/output/test-cluster-review.csv
uv run ladepark-importer build-sqlite tests/fixtures/bnetza_minimal.csv \
  --output ../data/output/test-charging.sqlite3 \
  --dataset-version 2026.07.0-test --source-version 2026-07-07-test \
  --created-at 2026-07-26T00:00:00Z \
  --operators tests/fixtures/operators_empty.json --replace
uv run ladepark-importer validate-sqlite ../data/output/test-charging.sqlite3
uv run ladepark-importer query-sqlite ../data/output/test-charging.sqlite3 --limit 10
```

Zuletzt verifiziert am 28. August 2026 mit Python 3.12.12: 72 Tests erfolgreich,
Ruff und Mypy ohne Befund; die Normalisierung erzeugte zwei Stationen, drei
EVSEs und drei Connectoren. Zusätzlich wurde die vollständige offizielle
BNetzA-CSV erfolgreich inspiziert, normalisiert und für alle fünf Durchmesser
gruppiert. Der read-only Abfrage-Prototyp wurde mit dem vollständigen
SQLite-Artefakt für Ladeleistungs-, Betreiber-, Connector-, Text-, Karten- und
Umkreisfilter geprüft; die gemessenen Kernabfragen lagen zwischen 158 und
495 ms. Das anschließend ergänzte `group_connector`-Aggregat reduziert den
zuvor 567 ms schnellen Connectorfilter auf rund 34 ms.
Der anschließend ergänzte Gruppen-R*Tree beschleunigt regionale
Kartenausschnitte und Umkreissuchen. Die hybride Auswahl zwischen R*Tree und
Direktfilter benötigte im Prototyp 154–207 ms für den Berliner Ausschnitt,
53 ms für 25 km um München und 443 ms für die Deutschlandansicht.

Die Flutter-App wurde am 28. August 2026 mit `flutter gen-l10n`, `dart format`,
`flutter analyze` und 54 Tests erfolgreich geprüft. Darin sind der
M2-SQLite-Contract, die M3-Kartenkoordination sowie die M10-Verträge für lokale
Einstellungen, Apple-/Google-Maps-Navigation und die M11-Manifest-,
Installations- und Rollbackverträge enthalten. Die automatisierte
Architekturprüfung und der native iOS-Simulator-Build mit Xcode 16.2 sind
erfolgreich. Die
App wurde mit dem 386-MB-Deutschlandbestand auf einem iPhone-16-Simulator
gestartet und visuell geprüft: Deutschlandkarte, Status `500+ Ladeparks`, reale
Marker und native Cluster werden angezeigt. Der Debug-App-Build ist rund
537 MB groß.
Der echte App-Wechsel zu Google Maps und der sprachliche Gesamteindruck bleiben
auf einem iPhone manuell abzunehmen.
