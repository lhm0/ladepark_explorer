# Vorschlag zur Weiterentwicklung des Software Specification Document

Status: Vorschlag

Stand: 26. Juli 2026

## Ziel

Die Projektdokumentation soll Codex und menschlichen Mitwirkenden in wenigen
Minuten ein korrektes Arbeitsmodell des Ladepark Explorers vermitteln. Sie soll
ausreichend präzise sein, um Implementierungsentscheidungen und Tests daraus
abzuleiten, aber keine Details vorwegnehmen, die noch nicht entschieden oder
implementiert sind.

Die bestehenden Markdown-Dateien bilden gemeinsam das Software Specification
Document (SSD). Ein großes, monolithisches Dokument ist nicht erforderlich.

## Bewertung des aktuellen Stands

Die Grundidee und die strategischen Leitplanken sind klar:

- Der Ladepark ist das zentrale Domänenobjekt.
- Version 1 arbeitet offline und ohne dauerhaftes Backend.
- Eine reproduzierbare Importpipeline erzeugt SQLite-Datensätze.
- Die App basiert auf Flutter; Version 1.0 verwendet Apple MapKit hinter einer
  plattformneutralen Kartenschnittstelle.
- Live-Daten bleiben einer späteren Ausbaustufe vorbehalten.

Für die Implementierung fehlen derzeit vor allem überprüfbare Anforderungen,
präzise Begriffe, Datenverträge und dokumentierte Entscheidungen. Zudem ist
`01_ProjectVision.md` nahezu identisch mit dem Übergabedokument, während die
anderen Kapitel bislang nur Gliederungscharakter haben.

## Empfohlener Detailgrad

Jedes Kapitel beantwortet nur vier Fragen:

1. Was ist das Ziel oder die Verantwortung?
2. Welche Regeln und Schnittstellen sind verbindlich?
3. Welche Entscheidungen sind noch offen?
4. Woran erkennen wir, dass die Umsetzung korrekt ist?

Detail gehört in die Dokumentation, wenn er mindestens eines dieser Kriterien
erfüllt:

- Er beeinflusst mehrere Komponenten.
- Codex könnte ohne ihn plausibel, aber falsch implementieren.
- Er ist für einen Akzeptanztest oder Datenvertrag erforderlich.
- Eine spätere Änderung wäre teuer oder migrationsrelevant.

Lokale Implementierungsdetails, offensichtlicher Code und kurzfristige
Arbeitsnotizen gehören nicht in das SSD.

## Empfohlene Dokumentstruktur

Die vorhandenen Kapitel können beibehalten und schrittweise ausgebaut werden.

| Dokument | Minimaler verbindlicher Inhalt |
| --- | --- |
| `01_ProjectVision.md` | Problem, Zielgruppen, Nutzenversprechen, Scope 1.0, Nicht-Ziele, Produktprinzipien, Erfolgskriterien |
| `02_Requirements.md` | nummerierte funktionale und nicht-funktionale Anforderungen mit Priorität und Akzeptanzkriterien |
| `03_System_Architecture.md` | Systemkontext, Komponenten, Datenfluss, Verantwortungsgrenzen, Qualitätsziele |
| `04_Data_Model.md` | Begriffe, Entitäten, Beziehungen, IDs, Pflichtfelder, Invarianten, Versionierung |
| `05_Importer.md` | Ein-/Ausgaben, Pipeline-Schritte, Fehlerbehandlung, Reproduzierbarkeit, Qualitätsbericht |
| `06_Clustering.md` | formale Parkdefinition, Algorithmus, Schwellwerte, Sonderfälle, manuelle Overrides, Testbeispiele |
| `07_SQLite.md` | Schema, Indizes, Metadaten, Datenbankversion, Migrations- und Austauschverfahren |
| `08_Flutter_Architecture.md` | Module, Zuständigkeiten, Datenzugriff, State Management, Offline- und Updateablauf |
| `09_UI_Guidelines.md` | zentrale Nutzerflüsse, Kartenverhalten, Filtersemantik, Zustände, Barrierefreiheit |
| `10_API_Future.md` | nur Randbedingungen und Erweiterungspunkte; keine vorzeitige Detailarchitektur |
| `11_Testing.md` | Testpyramide, kritische Referenzfälle, Qualitätsgates, Testdatenstrategie |
| `12_Deployment.md` | Build und Veröffentlichung von Datensätzen/App, Rollback, Prüfsummen, Umgebungen |
| `13_Coding_Guidelines.md` | wenige projektspezifische, überprüfbare Regeln; Standardregeln an Tools delegieren |
| `14_Roadmap.md` | Meilensteine, Ergebnisse, Abhängigkeiten und Definition of Done; keine tagesaktuelle Taskliste |
| `ADR/` | eine Datei je langfristig relevanter Architekturentscheidung |

Zusätzlich werden zwei kurze operative Dokumente empfohlen:

- `PROJECT_STATUS.md`: aktueller Stand, zuletzt verifizierter Build, laufender
  Meilenstein, bekannte Blocker und nächste sinnvolle Schritte.
- `AGENTS.md` im Repository-Wurzelverzeichnis: Einstieg für Codex, relevante
  Befehle, Dokumentationsregeln und Verweise auf die maßgeblichen Kapitel.

Diese beiden Dateien sind keine zweite Spezifikation. Sie verweisen auf das SSD
und halten nur den aktuellen Arbeitskontext fest.

## Anforderungen so schreiben, dass Codex sie umsetzen kann

Anforderungen erhalten stabile IDs, zum Beispiel `FR-MAP-001` oder
`NFR-PERF-001`. Eine Anforderung sollte kurz bleiben und mindestens enthalten:

```markdown
### FR-FILTER-001 – Mindestanzahl HPC-Ladepunkte

- Priorität: Muss (Version 1.0)
- Beschreibung: Nutzende können Ladeparks nach einer Mindestanzahl von
  HPC-Ladepunkten filtern.
- Akzeptanz:
  - Der Wert 0 deaktiviert den Filter.
  - Ein Park mit exakt dem gewählten Wert wird angezeigt.
  - Kombinierte Filter werden mit UND verknüpft.
- Quelle: Produktvision, Abschnitt „Version 1.0“
```

Nicht jede Anforderung braucht eine lange User Story. Entscheidend sind
eindeutige Semantik, Randfälle und beobachtbare Akzeptanzkriterien.

## Fakten, Pläne und offene Fragen trennen

Jedes technische Kapitel sollte diese Kennzeichnung verwenden:

- **Entschieden:** verbindlich und gegebenenfalls durch ADR abgesichert.
- **Geplant:** Zielbild, noch nicht implementiert.
- **Offen:** benötigt eine Entscheidung; mit Verantwortlichem oder
  Entscheidungszeitpunkt.
- **Ist-Zustand:** im Repository verifiziert.

So verwechselt ein neuer Codex-Chat keine Architekturidee mit vorhandenem Code.
Veraltete Aussagen werden geändert oder entfernt, nicht durch weitere
widersprüchliche Absätze ergänzt.

## Pflegeprozess

Die Dokumentation bleibt aktuell, wenn sie Teil der Definition of Done wird:

1. Vor einer Änderung werden betroffene Requirement-IDs und Kapitel benannt.
2. Code, Tests und Dokumentation werden gemeinsam geändert.
3. Neue langfristige Architekturentscheidungen erhalten ein ADR.
4. Nach Abschluss wird `PROJECT_STATUS.md` knapp aktualisiert.
5. Ein Review prüft nicht nur Code, sondern auch widersprüchliche oder veraltete
   Dokumentation.

Für Commits und Reviews empfiehlt sich eine kleine Checkliste:

```text
[ ] Betroffene Anforderungen genannt oder ergänzt
[ ] Akzeptanzkriterien durch Tests abgedeckt
[ ] Datenmodell/Schnittstellen bei Bedarf aktualisiert
[ ] Architekturentscheidung als ADR dokumentiert
[ ] PROJECT_STATUS.md aktualisiert
```

## Einstieg eines neuen Codex-Chats

Der Standardauftrag kann später sehr kurz sein:

> Lies `AGENTS.md`, `docs/README.md`, `PROJECT_STATUS.md` und die für die Aufgabe
> verlinkten SSD-Kapitel. Prüfe den Ist-Zustand im Code, bevor du Änderungen
> vornimmst. Aktualisiere betroffene Dokumentation und Tests zusammen mit dem
> Code.

`AGENTS.md` sollte die Lesereihenfolge und ausführbare Prüfkommandos enthalten.
Es sollte keine Produktanforderungen duplizieren.

## Empfohlene Reihenfolge

### Phase 1 – Spezifikationskern

1. `01_ProjectVision.md` vom Übergabedokument trennen und auf Produktvision,
   Scope, Nicht-Ziele und Erfolgskriterien fokussieren.
2. Ein Glossar und die Definition „Ladepark“ in `04_Data_Model.md` festlegen.
3. Anforderungen für Version 1 mit IDs und Akzeptanzkriterien ausarbeiten.
4. Architektur und Datenfluss an diese Anforderungen anbinden.
5. ADR-0001 in vollständigem ADR-Format ergänzen.

### Phase 2 – Datenpipeline

1. Datenquelle und Rohdatenvertrag beschreiben.
2. Normalisierung und stabile ID-Bildung spezifizieren.
3. Clusterregeln anhand konkreter positiver und negativer Beispiele festlegen.
4. SQLite-Schema und Manifest-Vertrag definieren.
5. Referenzdatensatz und Regressionstests festlegen.

### Phase 3 – App

1. Wichtigste Nutzerflüsse und Filtersemantik beschreiben.
2. Flutter-Modulgrenzen und lokalen Datenzugriff entscheiden.
3. Download-, Update-, Fehler- und Offlinezustände definieren.
4. Performanceziele mit realistischen Messbedingungen ergänzen.

## Sofort sinnvolle nächste Arbeitseinheit

Als erster überschaubarer Schritt sollte nicht eine 20-seitige Produktvision
entstehen. Sinnvoller ist ein kompakter Spezifikationskern:

1. Produktvision auf etwa drei bis fünf Seiten konsolidieren.
2. Scope und Nicht-Ziele für Version 1 verbindlich machen.
3. Zehn bis fünfzehn zentrale Anforderungen mit Akzeptanzkriterien erfassen.
4. Glossar mit circa zehn zentralen Begriffen anlegen.
5. Offene Entscheidungen sichtbar sammeln.

Danach kann anhand der Importer- und Clustering-Spezifikation mit der ersten
Implementierung begonnen werden. Die übrigen Kapitel wachsen bedarfsgerecht mit
dem Code.
