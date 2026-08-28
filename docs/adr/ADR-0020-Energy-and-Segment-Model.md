# ADR-0020 – Energie- und Segmentmodell hinter austauschbaren Schnittstellen

Status: Angenommen

Datum: 28. August 2026

## Kontext

Die Routenplanung der Version 1.1 soll eine einfache Reichweiten- und
Ladeplanung enthalten
([`../specification/17_Route_Planning.md`](../specification/17_Route_Planning.md),
`FR-ROUTE-006` bis `FR-ROUTE-009`). Ausdrücklicher Produktwunsch ist, dass eine
spätere „intelligente“ Vorhersage – mit Straßenart, Steigung, Gefälle,
Temperatur, Ladekurve und Fahrergewohnheiten – nachträglich eingebaut werden
kann, ohne die frühen Versionen umzubauen (`NFR-ROUTE-EXT-001`).

Die einfache Vorhersage der Version 1.1 beruht nur auf nutzbarer
Batteriekapazität, Durchschnittsverbrauch je 100 Kilometer und
Start-Ladezustand. Das intelligente Modell braucht später deutlich mehr
Eingaben und eigene Datenquellen.

## Entscheidung

- Eine Route wird als geordnete Folge von `RouteSegment` modelliert. Ein
  Segment trägt `distanceKm`, `durationS`, Start- und Endkoordinate sowie
  **optionale** Attribute `roadClass`, `grade` und `elevationDeltaM`. Version
  1.1 befüllt die optionalen Attribute nicht.
- Ein `TripContext` bündelt fahrtbezogene Zusatzgrößen wie
  Umgebungstemperatur. Version 1.1 übergibt einen leeren Kontext. Neue Felder
  werden additiv und optional ergänzt.
- Drei reine Domänenschnittstellen kapseln die austauschbare Logik. Sie liegen
  in `app/lib/features/route_planning/domain/` und importieren nichts aus
  `data`, `platform` oder `presentation`:
  - `EnergyModel.estimate(RoutePath, VehicleProfile, TripContext)` schätzt den
    Energiebedarf je Segment.
  - `ChargingModel.estimate(parkPowerKw, VehicleProfile, arrivalSoc,
    targetSoc)` schätzt nachgeladene Energie, Ladedauer und Abfahrt-Ladezustand.
  - `StopPlanner.plan(candidates, VehicleProfile, EnergyModel, ChargingModel,
    constraints)` erzeugt einen `ChargingPlan`.
- Version 1.1 liefert die trivialen Implementierungen:
  - `ConstantRateEnergyModel`: Energie = Distanz / 100 × Profilverbrauch. Alle
    optionalen Segmentattribute und der `TripContext` werden ignoriert.
  - `LinearChargingModel`: wirksame Leistung = min(Fahrzeug-Maximalleistung,
    Ladepark-Maximalleistung) × dokumentierter Wirkungsgrad-/Pufferfaktor;
    Ladezeit linear zur nachzuladenden Energie.
  - `GreedyStopPlanner`: fahren bis der geschätzte Ladezustand die Reserve
    erreichen würde; unter den davor erreichbaren Kandidaten den besten wählen
    (höhere Leistung, geringerer Umweg, weiter entlang der Route); so weit
    laden, dass der nächste nötige Stopp oder das Ziel mit Reserve erreichbar
    ist; wiederholen.
- Ein `TripEnergySimulator` als Domänendienst wendet `EnergyModel` und
  `ChargingModel` entlang der Teilstrecken an und erzeugt den
  Ladezustandsverlauf sowie Defizithinweise. Er ist von der konkreten
  Modellimplementierung unabhängig.
- Der `ChargingPlan` bietet Operationen `replaceStop`, `addStop`, `removeStop`,
  `setChargeTarget` und `lockStop`. Eine Neuplanung beginnt beim ersten
  geänderten oder entsperrten Stopp; vorangehende und gesperrte Stopps bleiben
  fix.
- Alle Schätzungen sind in der Oberfläche als Näherung zu kennzeichnen und
  nicht als garantierte Werte zu bezeichnen.

## Gründe

- Das Segmentmodell ist die stabile Andockstelle: Ein späteres Modell reichert
  dieselben Segmente mit `roadClass`, `grade` und `elevationDeltaM` an, ohne
  dass Aufrufer, Persistenz oder Oberfläche sich ändern.
- Drei getrennte Schnittstellen trennen die unabhängig ersetzbaren Bausteine
  Verbrauch, Ladeverhalten und Stoppauswahl.
- Triviale Implementierungen halten Version 1.1 klein und deterministisch und
  liefern trotzdem einen vollständigen, korrigierbaren Plan.
- Der `GreedyStopPlanner` ist einfach nachvollziehbar und für gleiche
  Eingaben deterministisch; ein optimierender Planer kann später hinter
  derselben Schnittstelle folgen.

## Folgen

Positiv:

- klare Nachrüstbarkeit ohne Bruch der frühen Versionen,
- deterministische, erklärbare Vorschläge in Version 1.1,
- die Architekturprüfung kann die Domänengrenze automatisiert schützen.

Negativ beziehungsweise zu beachten:

- Die einfache Vorhersage ist bei Autobahntempo, Kälte, Topografie und
  realer Ladekurve ungenau; die Oberfläche muss den Näherungscharakter
  deutlich machen.
- Der `GreedyStopPlanner` findet nicht immer die zeitoptimale Stoppfolge;
  das ist in Version 1.1 akzeptiert, weil Nutzende jeden Stopp korrigieren
  können (`FR-ROUTE-009`).
- Spätere Datenquellen für Höhenprofil, Temperatur und Ladekurven sind je
  eigene Architektur- und Lizenzentscheidung und nicht Teil dieses ADR.
