# ADR-0009 – Native MapKit-Integration als iOS Platform View

Status: Angenommen

Datum: 23. August 2026

## Kontext

ADR-0006 entscheidet Apple MapKit für die iPhone-Version 1.0 und verlangt eine
plattformneutrale Kartengrenze. Die App benötigt sichtbare Kartenbounds,
mehrere hundert kompakte Gruppenmarker, Auswahlereignisse und die Darstellung
des eigenen Standorts. Kartendaten dürfen nicht in den fachlichen Ladebestand
übernommen werden.

Flutter 3.44 verwendet auf iOS den `UIScene`-Lifecycle und unterstützt native
UIKit-Views über Platform Views. Eine zusätzliche Kartenbibliothek würde eine
zweite Abstraktion und einen weiteren Release-Lifecycle einführen.

## Entscheidung

- Die iOS-Karte wird als eigener UIKit Platform View mit `MKMapView` in Swift
  implementiert.
- Die Registrierung erfolgt über `FlutterImplicitEngineDelegate`, passend zum
  vorhandenen `UIScene`-Projekt.
- Dart kennt nur den plattformneutralen Kartenvertrag unter `platform/maps/`.
- Bounds, Markerzustand und Auswahl werden über einen kleinen versionierten
  Nachrichtenvertrag zwischen Dart und Swift übertragen.
- Der Flutter Platform View übernimmt Zeigersequenzen mit einem
  `EagerGestureRecognizer`, damit MapKits native Scroll-, Pinch-, Rotations-
  und Neigungsgesten nicht an der Flutter-Gesture-Arena verloren gehen.
- Eine plattformneutrale Kartenoperation stellt die definierte
  Deutschland-Ausgangsansicht wieder her.
- Die erste Implementierung liegt app-lokal im iOS-Runner. Sie wird erst dann
  in ein eigenes Flutter-Plugin ausgelagert, wenn ein zweiter Konsument oder
  unabhängig testbarer nativer Umfang dies rechtfertigt.
- MapKit stellt ausschließlich die Karte dar. Suche, Filter, Identitäten und
  Ladeinformationen stammen aus dem lokalen Datensatz.
- Ein späterer Android-Adapter implementiert denselben fachlichen Vertrag mit
  einer separat entschiedenen Kartentechnologie.

## Folgen

Positiv:

- keine fremde Karten-SDK- oder Plugin-Abhängigkeit,
- unmittelbarer Zugriff auf MapKit-Clustering, Annotation-Reuse und
  Standortdarstellung,
- klare Lizenz- und Datenflussgrenze,
- Swift-Code bleibt klein und auf Darstellung beschränkt.

Negativ:

- Platform Views besitzen bekannte Kompositions- und Performancegrenzen,
- Dart-/Swift-Nachrichtenvertrag und Lifecycle müssen selbst getestet werden,
- Android benötigt eine eigene native Kartenimplementierung.

## Qualitätsbedingung

Vor dem Ausbau des Markerdesigns werden Scroll-/Zoom-Verhalten, Bounds-Events
und mindestens 500 Annotationen auf Simulator und einem unterstützten iPhone
gemessen. Bei nachgewiesenen Platform-View-Problemen wird die Renderstrategie
neu bewertet, ohne den fachlichen Kartenvertrag zu ändern.
