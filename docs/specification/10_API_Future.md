# Zukünftiges Backend

Status: Zukunftsskizze – Idee, nicht Bestandteil von Version 1.0

Eine spätere Version kann ein Backend für Community- und Live-Funktionen
ergänzen. PostgreSQL/PostGIS, Redis und FastAPI sind mögliche Technologien,
aber noch nicht entschieden. Stammdaten, Live-Status und nutzergenerierte
Inhalte sind fachlich getrennt zu behandeln.

Ein solches Backend darf den reproduzierbaren Importer und die offline
nutzbaren Kernfunktionen nicht unnötig ersetzen. Vor einer Implementierung sind
mindestens getrennte Verträge für Stammdaten, Livezustand und Community-Inhalte,
Authentisierung und Rollen, Moderation und Löschung, Synchronisation,
Ausfallsicherheit, Betriebskosten, Datenschutz und Quelllizenzen zu
spezifizieren.

Die stabilen Stations- und Betreiber-IDs sowie die getrennte Semantik von
berechneten `proximity_group`s und später bestätigten `verified_park`s bilden
die fachliche Anschlussstelle. Sie legen weder Transportprotokoll noch
Backendtechnologie fest. Die priorisierten Ideen stehen in
[`14_Roadmap.md`](14_Roadmap.md).
