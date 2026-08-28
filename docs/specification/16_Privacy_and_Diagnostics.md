# Datenschutz und Diagnostik

Status: Version-1.0-Entscheidung implementiert

## Grundsatz

Version 1.0 verwendet gemäß ADR-0018 keine Telemetrie, keine automatische
Fehlerübermittlung, keine Werbung und kein Tracking. Die App besitzt kein
Benutzerkonto und erstellt kein personenbezogenes Nutzungsprofil.

## Lokal gespeicherte Daten

- Einstellungen einschließlich Sprache, Navigationswahl und automatischer
  Datensatzprüfung,
- Favoriten mit stabilen Stationsreferenzen,
- heruntergeladene, geprüfte Ladebestände und ein Rollbackbestand,
- mit der App ausgelieferte redaktionelle Informationen und Fotos.

Diese Daten werden nicht an den Entwickler übertragen und bei Deinstallation
der App durch iOS aus dem App-Container entfernt.

## Externe Netzwerkzugriffe

| Auslöser | Empfänger | Übertragener fachlicher Inhalt |
| --- | --- | --- |
| Kartendarstellung und Online-Ortssuche | Apple MapKit/Apple | Kartenanfragen beziehungsweise eingegebener Ort oder Adresse nach den Bedingungen von Apple |
| automatische oder manuelle Updateprüfung | GitHub | Abruf des öffentlichen Manifests; der Datensatz folgt erst nach Bestätigung |
| Apple-Maps-Navigation | Apple Maps | gewählte Zielkoordinate und Bezeichnung |
| Google-Maps-Navigation | Google Maps | gewählte Zielkoordinate und Fahrmodus |

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

## Geplante Erweiterung: Routenplanung (Version 1.1)

Version 1.1 ergänzt eine Routenplanung
([`17_Route_Planning.md`](17_Route_Planning.md), `NFR-ROUTE-PRIV-001`). Vor
ihrer Auslieferung wird dieses Kapitel wie folgt fortgeschrieben:

- Die Routen- und Teilstreckenberechnung erfolgt online über Apple
  `MKDirections`. An Apple gehen dabei ausschließlich Start, Ziel und die
  Wegpunkte der Route, darunter ausgewählte Ladestopps. Dieser Zugriff ist
  derselben Klasse zuzuordnen wie die bereits vorhandene Online-Ortssuche.
- Das lokale Fahrzeugprofil und der berechnete Plan verlassen das Gerät nicht.
  Sie werden im schema-versionierten Einstellungsspeicher abgelegt und bei
  Deinstallation durch iOS entfernt.
- Korridorsuche, Reichweitenvorhersage und Neuplanung arbeiten auf der bereits
  bezogenen Route ohne weitere Netzverbindung.
- Es entsteht weiterhin keine Telemetrie, kein Crash-Reporting und kein
  personenbezogenes Nutzungsprofil.

Die Tabelle der externen Netzwerkzugriffe und die lokale Datenaufstellung
werden im Zuge von Meilenstein M19 entsprechend ergänzt.

## Spätere Änderungen

Eine spätere Telemetrie- oder Crash-Reporting-Funktion ist eine neue
Produkt- und Architekturentscheidung. Vor ihrer Einführung müssen mindestens
Ereignisse, Zweck, Rechtsgrundlage, Empfänger, Anonymisierung,
Aufbewahrungsfrist, Löschung und Widerruf dokumentiert werden. Die Einwilligung
muss freiwillig, ausdrücklich und standardmäßig deaktiviert sein.
