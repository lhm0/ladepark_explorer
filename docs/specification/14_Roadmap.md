# Roadmap

Status: Produktroadmap; Statusangaben verbindlich, Termine offen

Stand: 28. August 2026

## 1. Leitplanken

- Version 1.0 bleibt offline-first, iPhone-zentriert und ohne dauerhaftes
  fachliches Backend.
- Neue Vorhaben erhalten vor Implementierung Requirement-IDs; langfristige
  Architekturentscheidungen erhalten ein ADR.
- **Implementiert** bedeutet durch Code und automatisierte Tests belegt.
  **Manuell abgenommen** bezeichnet zusätzlich einen dokumentierten Lauf auf
  Simulator oder Gerät. **Geplant** ist priorisiert, aber noch nicht umgesetzt.
  **Idee** ist weder Scope- noch Architekturentscheidung.
- Community-, Konto-, Live-Daten- und Bezahlfunktionen dürfen Version 1.0 nicht
  blockieren.

## 2. Ursprünglicher Entwicklungsplan und heutiger Stand

| Meilenstein | Status | Ziel und Ergebnis |
| --- | --- | --- |
| M0 – Entwicklungsbasis | implementiert | Repository, Flutter-/Python-Struktur, lokale Toolchain und wiederholbare Prüfkommandos |
| M1 – ausführbare iPhone-App | implementiert | App-Shell, iOS-Projekt und erster Simulatorlauf |
| M2 – lokaler Datenzugriff | implementiert | gemeinsamer Schema-v2-Vertrag, read-only SQLite-Repository und typisierte Abfragen |
| M3 – Kartenfluss | implementiert | native MapKit-Karte, sichtbare Bounds, Marker, Auswahl und nachgeladene Details |
| M4 – Produktkarte und Details | implementiert und manuell abgenommen | vollständiger Deutschlandbestand, native Cluster, Zoom/Deutschlandknopf, Detailmatrix und stabilisierte opake Route |
| M5 – Ladefilter | implementiert und manuell abgenommen | Gruppendurchmesser, gekoppelte Zahl/Leistung, Betreiber- und Connectorauswahl |
| M6 – Suche und Standort | implementiert | Ort, Adresse, FTS-Fallback, Koordinaten, eigener Standort und Umkreis |
| M7 – lokale Favoriten | implementiert | getrennter Speicher, Herz, Liste, Kartenfilter und gruppenübergreifende Auflösung |
| M8 – redaktionelle Informationen | implementiert und manuell abgenommen | JSON-Pflegequelle, `park_info.sqlite`, eigene Vor-Ort-Merkmale und sechs geprüfte Fotos für Emstek, Hilden und Kamen |
| M9 – weitere Filter | implementiert | Infrastruktur, konsolidierter Umkreis und konservativ strukturierter 24/7-Filter |
| M10 – Navigation, Sprache, Einstellungen | implementiert | Apple-/Google-Maps-Übergabe, DE/EN/Systemsprache und lokale Präferenzen |
| M11 – statische Updates | implementiert | öffentlicher GitHub-Release, deterministisches Manifest, bestätigter Download, doppelte Hash-/SQLite-Prüfung und atomarer Rollback |
| M12 – Datenschutz und Diagnostik | implementiert | keine Telemetrie oder automatischen Crashreports; transparente Datenschutzseite und nur bewusst kopierte lokale Diagnose |
| M13 – Release-Härtung | geplant, als Nächstes | Performance, Offlineverhalten, Zugänglichkeit, Lizenznachweise, Signierung, TestFlight und App Store |

## 3. M13 – Definition des nächsten Meilensteins

M13 soll Version 1.0 veröffentlichungsfähig machen, ohne den fachlichen Scope
noch einmal wesentlich zu erweitern.

### 3.1 Technische Härtung

- Referenzgeräte und unterstützte iOS-Version endgültig festlegen,
- Start-, Karten-, Filter- und Detailperformance mit Produktbestand messen,
- Speicherbedarf, App-/Downloadgröße und freier Speicher bei Updates prüfen,
- Offline-, Abbruch-, beschädigte Downloads und Wiederanlauf manuell abnehmen,
- Manifest-Herkunftssignatur entscheiden und gegebenenfalls implementieren,
- automatisierten Bilddarstellungstest ergänzen,
- verbliebene native MapKit-Abläufe durch Integration-/XCUITests oder eine
  dokumentierte manuelle Matrix absichern.

### 3.2 Produkt- und Zugänglichkeitsabnahme

- Dynamic Type, VoiceOver, Kontrast, Bedienziele und kleine Displays prüfen,
- deutsche und englische Oberfläche vollständig redigieren,
- Google-Maps-Fallback und Standortberechtigungen auf echtem Gerät testen,
- Datenschutzseite um TestFlight-/App-Store-Verarbeitung ergänzen,
- Support- und Feedbackweg festlegen.
- Für die Soll-Anforderung `FR-LINK-001` entweder kuratierte offizielle Links
  einschließlich UI und Nachweisen umsetzen oder die Verschiebung aus Version
  1.0 ausdrücklich dokumentieren.

### 3.3 Recht und Distribution

- Lizenz-Releasecheckliste vollständig belegen,
- Foto- und Quellenreview abschließen,
- öffentliche Datenschutz- und Support-URL bereitstellen,
- Apple-Developer-Mitgliedschaft, Bundle-ID, Signierung und App-Eintrag
  konfigurieren,
- App-Icon, Screenshots, Beschreibung, Altersfreigabe, App Privacy und
  Export-Compliance vorbereiten,
- internen Gerätetest, anschließend externen TestFlight-Test durchführen,
- finale Version und Buildnummer festlegen.

M13 ist abgeschlossen, wenn die in den Anforderungen definierten Kernabläufe
auf der vereinbarten Gerätematrix stabil sind und ein freigabefähiger Build mit
vollständigen Nachweisen in App Store Connect vorliegt.

## 4. Version 1.5 – Ausbau nach erfolgreichem iPhone-Start

### 4.1 Redaktion und bestätigte Ladeparks

- breiterer eigener Foto- und Informationsbestand,
- redaktioneller Workflow für Korrekturen, Review und Veröffentlichung,
- versionierte `verified_park`-Regeln für bestätigte Zusammengehörigkeit,
- stabile Merge-/Split-Historie unabhängig von dynamischen Abstandsgruppen,
- Statistiken und redaktionelle Top-Listen, beispielsweise Top 100.

### 4.2 Community

- Feedback zu zusammengehörigen oder getrennten Ladeeinrichtungen,
- Bewertungen und Kommentare,
- Benutzerkonten, Rollen, Moderation, Missbrauchsschutz und Löschprozesse,
- nachvollziehbare Übernahme freigegebener Hinweise in redaktionelle Regeln.

Diese Funktionen benötigen ein eigenes Daten-, Rechte-, Moderations-,
Datenschutz- und Sicherheitskonzept. Die in Version 1.0 vorhandenen stabilen
Stationsanker und die Trennung zwischen `proximity_group` und `verified_park`
bereiten sie vor, ersetzen dieses Konzept aber nicht.

### 4.3 Android

Android-Veröffentlichung ist nach einem erfolgreichen iPhone-Start geplant.
Flutter-Domain- und Datenzugriffscode ist wiederverwendbar; MapKit,
Core Location, MKLocalSearch und iOS-Navigation benötigen eigene Android-
Adapter. Kartenanbieter, Kartenstil, Offlineversorgung, Lizenz und
Testgerätematrix sind vor Implementierung zu entscheiden.

## 5. Routenplanung – diskutierte Produkterweiterung

Status: Idee; noch keine Anforderungen oder Architekturentscheidung

### M14 – normale Route von A nach B

- Start und Ziel als Standort, Ort, Adresse, Koordinate oder Ladepark,
- Onlineberechnung einer Apple-Autoroute mit `MKDirections`,
- native Darstellung als Route-Overlay in `MKMapView`,
- Entfernung, erwartete Fahrzeit und gegebenenfalls Alternativrouten,
- klare Offline-, Fehler- und Drosselungszustände.

Der empfohlene Architekturansatz ist ein plattformneutraler
`RoutePlanningService` mit MapKit-Adapter. Die exakte Polyline bleibt nativ;
Flutter erhält nur fachlich erforderliche Zusammenfassungen oder eine
vereinfachte Geometrie. Datenschutz und Offlineanforderungen müssen ergänzt
werden, weil Start und Ziel an Apple übertragen werden.

### M15 – Ladeparks entlang der Route

- lokaler Korridor um die berechnete Routengeometrie,
- vorhandene Lade-, Betreiber-, Anschluss-, Infrastruktur- und 24/7-Filter,
- Position entlang der Route und geschätzter Umweg,
- manuelle Auswahl eines oder mehrerer Ladestopps,
- Neuberechnung der Teilstrecken.

### Spätere automatische E-Auto-Planung

Eine automatische Stoppauswahl wäre deutlich größer als M14/M15. Sie benötigt
Fahrzeug- und Batterieprofil, Start-/Ziel-Ladezustand, Verbrauchsmodell,
Ladekurve, Reserven, Ladezeit und einen Optimierungsalgorithmus. Wetter,
Höhenprofil und Live-Belegung wären weitere eigenständige Datenquellen. MapKit
liefert diese vollständige EV-Optimierung nicht an die App. Vor einem solchen
Vorhaben sind Produktnutzen, Haftung, Datenquellen und Build-versus-Buy neu zu
bewerten.

## 6. Version 2.0 – Live-Daten, Preise und Backend

Status: Idee

- Live-Belegungszustände,
- Tarife und Preisvergleich,
- möglicherweise Anbieter- oder Roamingintegration,
- serverseitige Aktualisierung und Aggregation,
- Kontosynchronisation und weitere Onlinefunktionen.

PostgreSQL/PostGIS, Redis und FastAPI sind bisher lediglich Kandidaten. Eine
Entscheidung muss Stammdaten, Livezustand, nutzergenerierte Inhalte,
Authentisierung, Datenschutz, Betrieb, Kosten, Ausfallsicherheit und
Quelllizenzen gemeinsam betrachten.

## 7. Weitere offene Erweiterungen

- separates OSM-Infrastrukturartefakt mit vollständig belegter ODbL-Kette,
- Share Extension für Koordinaten oder Kartenlinks,
- Wechsel der statischen Updateablage von GitHub zu R2/S3,
- offizielle Betreiberlinks nach kontrolliertem Adressabgleich,
- möglicher BNetzA-Webserviceadapter zusätzlich zum Dateiadapter,
- freiwillige Telemetrie nur nach neuem ADR und ausdrücklicher Einwilligung.

## 8. Architekturvorsorge

| Zukunftsthema | Bereits vorhandene Vorbereitung | Noch erforderlich |
| --- | --- | --- |
| bestätigte Parks | stabile Stations-IDs; getrennte `verified_park`-Semantik | Regelmodell, Redaktion, Migration und API |
| Community | klare lokale Fachmodelle und IDs | Backend, Konten, Moderation, Datenschutz |
| Android | Flutter, Repository Pattern, `MapAdapter` | Karten-, Suche-, Standort- und Navigationsadapter |
| Routenplanung | native MapKit-View und Koordinatenmodelle | Route-Domainvertrag, Overlaykanal, UI und Datenschutz |
| Live-Daten | Trennung von Stammdaten und App-Speichern | Livequelle, Aktualitätsmodell, Backend und Ausfallsemantik |
| OSM | separates Artefakt vorgesehen | Anbieter, Pipeline, ODbL-Nachweis und Hosting |
| anderer Downloadhost | Manifest- und HTTP-Abstraktion | neue Basis-URL, Betrieb und Signatur |
| Datensatzmigration | Schema-/Manifestversionen und Contract-Fixtures | Migrationsstrategie je inkompatibler Version |

Die Vorsorge ist eine Entkopplung, keine Vorentscheidung über konkrete
Technologien oder Produktdetails.
