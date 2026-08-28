# ADR-0018 – Keine Telemetrie in Version 1.0

Status: Angenommen

Datum: 28. August 2026

## Kontext

FR-PRIV-001 verlangt Datensparsamkeit und schließt jede Übertragung von
Nutzungs- oder Fehlerdaten ohne ausdrückliche Einwilligung aus. Für Version 1.0
existieren weder ein fachliches Backend noch ein ausgewählter und geprüfter
Telemetrie- oder Crash-Reporting-Dienst. Ein solcher Dienst würde zusätzliche
Empfänger, Aufbewahrungsfristen, SDK-Risiken, Einwilligungsverwaltung und eine
erweiterte App-Store-Datenschutzerklärung verursachen.

## Entscheidung

- Version 1.0 enthält kein Analyse-, Telemetrie-, Werbe- oder automatisches
  Crash-Reporting-SDK und überträgt keine Diagnoseereignisse an den Entwickler.
- Deshalb gibt es beim ersten Start keine Einwilligungsabfrage. Eine
  Einwilligung ohne tatsächlich angebotenen Dienst wäre irreführend.
- Favoriten, Einstellungen und heruntergeladene Datensätze bleiben lokal in
  den App-Verzeichnissen.
- Eine App-Seite erklärt die Datenschutzgrenzen und die bewussten
  Netzwerkzugriffe für Apple MapKit und Ortssuche, GitHub-Datensatzupdates
  sowie externe Navigation.
- Ein kleiner Diagnosestatus kann ausschließlich durch eine ausdrückliche
  Aktion in die Zwischenablage kopiert werden. Er enthält keine Koordinaten,
  Suchbegriffe, Favoriten oder Gerätekennung und wird nicht automatisch
  versendet.
- Zeitmessungen für Karten- und Datenbankarbeit bleiben auf Debug-Builds und
  die lokale Flutter-Konsole beschränkt.
- Eine spätere Telemetrieeinführung benötigt vor der Implementierung ein neues
  ADR, einen dokumentierten Ereigniskatalog, Empfänger und Aufbewahrungsfrist,
  eine Datenschutzprüfung sowie eine freiwillige, standardmäßig deaktivierte
  Einwilligung.

## Folgen

Alle fachlichen Funktionen arbeiten ohne Diagnoseeinwilligung; es entstehen
keine Telemetrie-Kosten oder externen Nutzungsprofile. Fehler aus öffentlichen
Versionen werden zunächst nur durch bewusst übermittelte Nutzerberichte und
App-Store-Rückmeldungen sichtbar. Die Entscheidung kann später kontrolliert
neu bewertet werden, darf aber nicht stillschweigend durch Hinzufügen eines SDK
umgangen werden.
