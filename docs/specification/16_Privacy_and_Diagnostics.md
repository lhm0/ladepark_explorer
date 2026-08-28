# Datenschutz und Diagnostik

Status: Entscheidungen für Version 1.0 und Version 1.1 implementiert

## Grundsatz

Die App verwendet gemäß ADR-0018 keine Telemetrie, keine automatische
Fehlerübermittlung, keine Werbung und kein Tracking. Sie besitzt kein
Benutzerkonto und erstellt kein personenbezogenes Nutzungsprofil. Das gilt
auch für die in Version 1.1 ergänzte Routenplanung.

## Lokal gespeicherte Daten

- Einstellungen einschließlich Sprache, Navigationswahl und automatischer
  Datensatzprüfung,
- das lokale Fahrzeugprofil für die Reichweitenschätzung (nutzbare Kapazität,
  Verbrauch, Reserve- und Ziel-Ladezustand, Ladeleistung, Steckertypen),
- die zuletzt gewählte Kartenfilter-Auswahl,
- Favoriten mit stabilen Stationsreferenzen,
- heruntergeladene, geprüfte Ladebestände und ein Rollbackbestand,
- mit der App ausgelieferte redaktionelle Informationen und Fotos.

Fahrzeugprofil und Filter-Auswahl liegen im schema-versionierten
Einstellungsspeicher. Der berechnete Routenplan (Route, Ladestopps,
Start-Ladezustand für die Fahrt) besteht nur zur Laufzeit und wird nicht
gespeichert.

Diese Daten werden nicht an den Entwickler übertragen und bei Deinstallation
der App durch iOS aus dem App-Container entfernt.

## Externe Netzwerkzugriffe

| Auslöser | Empfänger | Übertragener fachlicher Inhalt |
| --- | --- | --- |
| Kartendarstellung und Online-Ortssuche | Apple MapKit/Apple | Kartenanfragen beziehungsweise eingegebener Ort oder Adresse nach den Bedingungen von Apple |
| Routen- und Teilstreckenberechnung (Version 1.1) | Apple `MKDirections`/Apple | Start, Ziel und die Wegpunkte der Route einschließlich gewählter Ladestopps als Koordinaten; Fahrmodus Auto |
| automatische oder manuelle Updateprüfung | GitHub | Abruf des öffentlichen Manifests; der Datensatz folgt erst nach Bestätigung |
| Apple-Maps-Navigation | Apple Maps | gewählte Zielkoordinate und Bezeichnung; bei einer geplanten Route die geordnete Kette aus Start, Ladestopps und Ziel |
| Google-Maps-Navigation | Google Maps | gewählte Zielkoordinate und Fahrmodus; bei einer geplanten Route Start und der nächste Ladestopp (das App-Schema nimmt keine Wegpunktkette) |

Die üblichen technischen Verbindungsdaten wie IP-Adresse können beim jeweiligen
Dienst anfallen. Lokale Suche, Filter, Details, Favoriten und die Anzeige des
installierten Datenbestands benötigen keinen eigenen App-Server.

## Lokale Diagnose

Die Einstellungsseite zeigt einen kleinen Diagnosestatus für Telemetrie,
Crash-Reporting, Werbetracking und automatische Updateprüfungen. Nur ein
bewusster Tastendruck kopiert diesen Text in die Zwischenablage. Der Text
enthält keine Koordinaten, Suchbegriffe, Favoriten oder Gerätekennung und wird
nicht automatisch versendet.

Debug-Zeitmessungen erscheinen ausschließlich in Debug-Builds lokal in der
Flutter-Konsole. Sie werden weder gespeichert noch übertragen.

## Routenplanung (Version 1.1)

Die Routenplanung ([`17_Route_Planning.md`](17_Route_Planning.md),
`NFR-ROUTE-PRIV-001`) ist implementiert und in den obigen Aufstellungen bereits
berücksichtigt:

- Die Routen- und Teilstreckenberechnung erfolgt online über Apple
  `MKDirections`. An Apple gehen dabei ausschließlich Start, Ziel und die
  Wegpunkte der Route, darunter ausgewählte Ladestopps. Dieser Zugriff ist
  derselben Klasse zuzuordnen wie die bereits vorhandene Online-Ortssuche.
- Das lokale Fahrzeugprofil verlässt das Gerät nicht; der berechnete Plan
  besteht nur zur Laufzeit. Es entsteht kein personenbezogenes Nutzungsprofil.
- Die Korridorsuche und die Reichweitenschätzung arbeiten auf der bereits
  bezogenen Route ohne weitere Netzverbindung.
- Die Übergabe einer geplanten Route an eine Navigations-App überträgt nur
  Koordinaten (siehe Tabelle), kein Konto und keine Kennung.
- Es entsteht weiterhin keine Telemetrie und kein Crash-Reporting.

## Spätere Änderungen

Eine spätere Telemetrie- oder Crash-Reporting-Funktion ist eine neue
Produkt- und Architekturentscheidung. Vor ihrer Einführung müssen mindestens
Ereignisse, Zweck, Rechtsgrundlage, Empfänger, Anonymisierung,
Aufbewahrungsfrist, Löschung und Widerruf dokumentiert werden. Die Einwilligung
muss freiwillig, ausdrücklich und standardmäßig deaktiviert sein.
