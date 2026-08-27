# ADR-0010 – Packaging des mitgelieferten Basisdatensatzes

Status: Angenommen

Datum: 23. August 2026

## Kontext

`FR-DATA-001` verlangt einen vor dem ersten Download verwendbaren
Deutschlanddatensatz. Das derzeitige SQLite-Artefakt ist rund 386 MB groß und
wird aus einem nicht versionierten BNetzA-Snapshot reproduzierbar erzeugt. Es
ist deshalb weder als Git-Blob noch als zur Laufzeit vollständig in den
Arbeitsspeicher geladenes Flutter-Asset geeignet.

M3 verwendet für einen kleinen ausführbaren Prototyp die versionierte
Schema-v1-Contract-Fixture. M4 benötigt zusätzlich einen reproduzierbaren Weg,
lokal und im Release-Build den vollständigen Bestand einzubinden, ohne CI und
Repository von diesem großen Artefakt abhängig zu machen.

## Entscheidung

- Der produktive Basisdatensatz wird vor einem App-Build als generiertes,
  git-ignoriertes Flutter-Asset unter `app/assets/generated/` bereitgestellt.
- Ein versioniertes Tooling-Skript validiert Schemaversion und Pflichtmetadaten
  und kopiert den ausgewählten Bestand atomar an den erwarteten Assetpfad.
- Auf iOS löst ein kleiner nativer Kanal den physischen Pfad des Assets im
  App-Bundle auf. SQLite öffnet diese Datei direkt mit `OpenMode.readOnly`.
- Der Basisdatensatz wird beim Start nicht in den Arbeitsspeicher und nicht in
  einen zweiten App-Sandboxpfad kopiert.
- Ist kein generiertes Release-Asset vorhanden, verwendet der Entwicklungs-
  und CI-Build die kleine versionierte Contract-Fixture.
- Die App validiert unabhängig von der Auswahl weiterhin Schema und Metadaten
  über den in ADR-0008 entschiedenen Repository-Adapter.
- Spätere heruntergeladene Updates liegen im App-Sandboxspeicher. Auswahl,
  atomarer Austausch und Rollback werden vor Implementierung des Updateflusses
  gesondert entschieden.

## Gründe

- Große generierte Binärdateien belasten Git-Historie und Code-Review nicht.
- Direktes Öffnen vermeidet Startzeit, Spitzenarbeitsspeicher und doppelten
  Speicherbedarf einer vollständigen Assetkopie.
- Contract-Fallback hält Unit Tests, CI und einen frischen Checkout ohne
  privaten Quelldatensatz ausführbar.
- Derselbe SQLite- und Metadatenvertrag gilt für Fixture und Deutschlandbestand.

## Folgen

Positiv:

- produktionsnaher Offline-Start mit vollständigem Bestand,
- reproduzierbarer lokaler und Release-Build,
- keine Aufnahme des großen Datensatzes in Git,
- keine unnötige Laufzeitkopie auf iOS.

Negativ:

- Release-Builds benötigen einen expliziten Vorbereitungsschritt,
- ein Build ohne Release-Asset zeigt nur die synthetischen Fixture-Standorte,
- Android benötigt vor einer Veröffentlichung eine äquivalente direkte
  Assetauflösung oder einen kontrollierten Installationsschritt.
