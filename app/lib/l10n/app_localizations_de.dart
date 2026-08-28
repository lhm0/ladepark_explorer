// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Ladepark Explorer';

  @override
  String get filters => 'Filter';

  @override
  String get search => 'Suchen';

  @override
  String get locationSearch => 'Ort oder Koordinate suchen';

  @override
  String get locationSearchHint => 'Ort, Adresse oder Ladepark';

  @override
  String get coordinateSearchHint =>
      'Ortsnamen werden mit Apple Maps online aufgelöst. Koordinaten und direkte Maps-URLs funktionieren ebenfalls.';

  @override
  String get noSearchResults =>
      'Der Ort oder ein passender Ladepark in seiner Umgebung wurde nicht gefunden.';

  @override
  String get searchFailed => 'Die lokale Suche konnte nicht ausgeführt werden.';

  @override
  String searchResultChargingPoints(int count) {
    return '$count Ladepunkte';
  }

  @override
  String get nearbySearch => 'Ladeparks in meiner Nähe';

  @override
  String get nearbyRadiusExplanation =>
      'In welchem Umkreis sollen Ladeparks angezeigt werden?';

  @override
  String get distanceFromCurrentLocation => 'Entfernung zum aktuellen Standort';

  @override
  String get noDistanceLimit => 'Nicht begrenzen';

  @override
  String activeNearbyRadius(int radius) {
    return 'Umkreis $radius km';
  }

  @override
  String get alwaysOpenOnly => 'Nur durchgehend zugängliche Ladeangebote';

  @override
  String get alwaysOpenOnlyExplanation =>
      'Die erforderlichen Ladepunkte müssen laut Datenquelle rund um die Uhr zugänglich sein.';

  @override
  String radiusKm(int radius) {
    return '$radius km';
  }

  @override
  String get locationPermissionDenied =>
      'Der Standortzugriff ist nicht erlaubt. Du kannst ihn in den iOS-Einstellungen aktivieren.';

  @override
  String get locationUnavailable =>
      'Der aktuelle Standort konnte nicht bestimmt werden.';

  @override
  String get groupDiameter => 'Maximaler Gruppendurchmesser';

  @override
  String get minimumChargingPoints => 'Erforderliche Ladepunkte';

  @override
  String get minimumPower => 'Mindestleistung je Ladepunkt';

  @override
  String minimumChargingOffer(int count, int power) {
    return 'Mindestens $count Ladepunkte mit jeweils mindestens $power kW';
  }

  @override
  String get resetFilters => 'Standard herstellen';

  @override
  String get cancelFilterChanges => 'Abbruch';

  @override
  String get favoritesOnly => 'Nur Favoriten anzeigen';

  @override
  String get infrastructureFilter => 'Ausstattung';

  @override
  String get infrastructureFilterExplanation =>
      'Alle ausgewählten Merkmale müssen als vorhanden geprüft sein. Fehlende Angaben gelten als unbekannt.';

  @override
  String get anyValue => 'Alle';

  @override
  String get filterSearch => 'Auswahl durchsuchen';

  @override
  String get operatorCountExplanation =>
      'Zahl in Klammern: Ladepunkte im Datensatz';

  @override
  String get clearSelection => 'Auswahl löschen';

  @override
  String get done => 'Fertig';

  @override
  String get mapSemantics => 'Karte mit Ladeparks';

  @override
  String get mapUnavailable => 'Die Apple-Karte ist nur auf iOS verfügbar.';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get germanyOverview => 'Deutschland anzeigen';

  @override
  String get loadingParks => 'Ladeparks werden geladen …';

  @override
  String visibleParks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ladeparks',
      one: 'Ein Ladepark',
      zero: 'Keine Ladeparks',
    );
    return '$_temp0';
  }

  @override
  String visibleParksLimitReached(int count) {
    return '$count+ Ladeparks';
  }

  @override
  String get datasetMissing => 'Der Ladepark-Datensatz fehlt.';

  @override
  String get datasetUnsupported =>
      'Der Ladepark-Datensatz hat eine nicht unterstützte Version.';

  @override
  String get invalidFilterQuery =>
      'Die gewählten Filter konnten nicht verarbeitet werden.';

  @override
  String get chargingParksLoadFailed =>
      'Die Ladeparks konnten nicht geladen werden.';

  @override
  String get detailsUnavailable => 'Details konnten nicht geladen werden.';

  @override
  String get chargingParkDetails => 'Ladeparkdetails';

  @override
  String stationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stationen',
      one: 'Eine Station',
    );
    return '$_temp0';
  }

  @override
  String evseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ladepunkte',
      one: 'Ein Ladepunkt',
    );
    return '$_temp0';
  }

  @override
  String get operators => 'Betreiber';

  @override
  String get chargingPointsByOperator =>
      'Ladepunkte nach Betreiber und Leistung';

  @override
  String get power => 'Leistung';

  @override
  String get connectors => 'Anschlüsse';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get openingHours => 'Öffnungszeiten';

  @override
  String get powerClasses => 'Leistungsklassen';

  @override
  String maximumPower(double power) {
    return 'Maximal $power kW';
  }

  @override
  String get maximumPowerUnknown => 'Maximale Leistung unbekannt';

  @override
  String proximityApproximation(int diameter) {
    return 'Räumliche Näherung; tatsächlicher Gruppendurchmesser: $diameter m. Zufahrten, Straßen und Grundstücksgrenzen sind nicht geprüft.';
  }

  @override
  String datasetVersion(String version) {
    return 'Datensatz $version';
  }

  @override
  String dataSource(String source, String version) {
    return 'Quelle: $source, Stand $version';
  }

  @override
  String datasetCreatedAt(String createdAt) {
    return 'Datensatz erstellt: $createdAt';
  }

  @override
  String get navigationUnavailable =>
      'Die Navigations-App konnte nicht geöffnet werden.';

  @override
  String get openNavigation => 'Route starten';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsUnavailable =>
      'Die Einstellungen konnten nicht geladen werden.';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'Englisch';

  @override
  String get navigationApp => 'Navigations-App';

  @override
  String get askEveryTime => 'Jedes Mal fragen';

  @override
  String get notInstalled => 'Nicht installiert';

  @override
  String get googleMapsUnavailable => 'Google Maps ist nicht verfügbar';

  @override
  String get googleMapsFallbackExplanation =>
      'Google Maps ist nicht installiert. Soll die Route stattdessen in Apple Maps geöffnet werden?';

  @override
  String get useAppleMaps => 'Apple Maps verwenden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get datasetUpdates => 'Datensatzupdates';

  @override
  String get automaticUpdateChecks => 'Automatisch nach Updates suchen';

  @override
  String get automaticUpdateChecksExplanation =>
      'Beim App-Start wird nur das kleine Manifest abgerufen. Der Datensatz wird erst nach Bestätigung heruntergeladen.';

  @override
  String get chargingDataset => 'Ladepark-Datensatz';

  @override
  String get updateNotChecked => 'Noch nicht geprüft';

  @override
  String get checkingForUpdates => 'Suche nach Updates …';

  @override
  String get datasetUpToDate => 'Der installierte Datensatz ist aktuell.';

  @override
  String updateAvailable(String version, String sizeMb) {
    return 'Version $version ist verfügbar ($sizeMb MB).';
  }

  @override
  String downloadingUpdate(int percent) {
    return 'Update wird geladen: $percent %';
  }

  @override
  String updateInstalled(String version) {
    return 'Version $version wurde installiert.';
  }

  @override
  String get updateCheckFailed => 'Die Updateprüfung ist fehlgeschlagen.';

  @override
  String get installedDatasetRemainsActive =>
      'Der bisherige Datensatz bleibt unverändert aktiv.';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get checkNow => 'Jetzt prüfen';

  @override
  String get downloadUpdate => 'Herunterladen';

  @override
  String updateDownloadConfirmation(String version, String sizeMb) {
    return 'Version $version benötigt $sizeMb MB. Der Download darf WLAN oder Mobilfunk verwenden. Jetzt herunterladen?';
  }

  @override
  String get favorites => 'Favoriten';

  @override
  String get noFavorites => 'Noch keine Ladeparks als Favoriten gespeichert.';

  @override
  String get addFavorite => 'Als Favorit speichern';

  @override
  String get removeFavorite => 'Favorit entfernen';

  @override
  String get favoriteUnavailable => 'Im aktuellen Datensatz nicht verfügbar';

  @override
  String get onSiteInformation => 'Vor Ort geprüft';

  @override
  String observedOn(String date) {
    return 'Erhoben am $date';
  }

  @override
  String photoCredit(String author, String date) {
    return 'Foto: $author, aufgenommen am $date';
  }

  @override
  String get restaurant => 'Restaurant';

  @override
  String get shop => 'Shop';

  @override
  String get coffeeMachine => 'Kaffeeautomat';

  @override
  String get snackMachine => 'Snackautomat';

  @override
  String get toilet => 'Toilette';

  @override
  String get amenityPresent => 'Vorhanden';

  @override
  String get amenityAbsent => 'Nicht vorhanden';

  @override
  String get privacy => 'Datenschutz';

  @override
  String get privacyAndDiagnostics => 'Datenschutz und Diagnose';

  @override
  String get privacySummary =>
      'Keine Telemetrie, keine Absturzberichte und kein Werbetracking';

  @override
  String get noTelemetry => 'Keine automatische Übertragung';

  @override
  String get noTelemetryExplanation =>
      'Die App übermittelt keine Nutzungsereignisse oder Absturzberichte an den Entwickler. Es gibt kein Analyse-, Werbe- oder Tracking-SDK.';

  @override
  String get localData => 'Daten auf diesem Gerät';

  @override
  String get localDataExplanation =>
      'Favoriten, Einstellungen und heruntergeladene Ladepark-Datensätze bleiben lokal. Sie werden bei einer Deinstallation der App entfernt.';

  @override
  String get externalServices => 'Bewusste Netzwerkzugriffe';

  @override
  String get externalServicesExplanation =>
      'Apple stellt Karte und Online-Ortssuche bereit. Updateprüfungen rufen ein Manifest von GitHub ab. Beim Start einer Navigation werden Zielkoordinaten an Apple Maps oder Google Maps übergeben.';

  @override
  String get localDiagnostics => 'Lokaler Diagnosestatus';

  @override
  String get telemetryStatus => 'Telemetrie: deaktiviert';

  @override
  String get crashReportingStatus =>
      'Automatische Absturzberichte: deaktiviert';

  @override
  String get adTrackingStatus => 'Werbung und Tracking: nicht enthalten';

  @override
  String get datasetChecksEnabled => 'Automatische Datensatzprüfung: aktiviert';

  @override
  String get datasetChecksDisabled =>
      'Automatische Datensatzprüfung: deaktiviert';

  @override
  String get copyDiagnostics => 'Diagnosestatus kopieren';

  @override
  String get diagnosticsCopied => 'Diagnosestatus wurde kopiert.';

  @override
  String get diagnosticsPrivacyExplanation =>
      'Der Text enthält keine Koordinaten, Suchbegriffe, Favoriten oder Gerätekennung. Er wird nur durch diese Schaltfläche in die Zwischenablage kopiert und nicht automatisch versendet.';

  @override
  String get routePlanning => 'Route planen';

  @override
  String get routePlanningTitle => 'Routenplanung';

  @override
  String get routeOnlineHint =>
      'Die Route wird online über Apple-Kartendienste berechnet.';

  @override
  String get routeStartLabel => 'Start';

  @override
  String get routeDestinationLabel => 'Ziel';

  @override
  String get routeEndpointHint => 'Ort, Adresse oder Koordinate';

  @override
  String get routeUseCurrentLocation =>
      'Aktuellen Standort als Start verwenden';

  @override
  String get routeCalculate => 'Route berechnen';

  @override
  String get routeCalculating => 'Route wird berechnet …';

  @override
  String get routeStartNotFound => 'Der Start wurde nicht gefunden.';

  @override
  String get routeDestinationNotFound => 'Das Ziel wurde nicht gefunden.';

  @override
  String routeDurationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String routeDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String routeSummary(String distance, String duration) {
    return '$distance · $duration';
  }

  @override
  String routeDistanceKm(String km) {
    return '$km km';
  }

  @override
  String get routeOverviewTitle => 'Route';

  @override
  String get routeMapSemantics => 'Karte mit der geplanten Route';

  @override
  String get routeAlternativesHeading => 'Alternativen';

  @override
  String routeOptionLabel(int index) {
    return 'Route $index';
  }

  @override
  String get routeShowOnMap => 'Auf Karte anzeigen';

  @override
  String get routeNewRoute => 'Neue Route';

  @override
  String get routeClear => 'Route beenden';

  @override
  String get routeErrorOffline =>
      'Ohne Internetverbindung kann keine Route berechnet werden.';

  @override
  String get routeErrorThrottled =>
      'Der Kartendienst ist zurzeit ausgelastet. Bitte kurz warten und erneut versuchen.';

  @override
  String get routeErrorNotFound =>
      'Für Start und Ziel wurde keine Route gefunden.';

  @override
  String get routeErrorInvalid => 'Start und Ziel müssen angegeben sein.';

  @override
  String get routeErrorFailed => 'Die Route konnte nicht berechnet werden.';

  @override
  String get planRouteToHere => 'Route hierher planen';

  @override
  String get routeCorridorTitle => 'Ladeparks entlang der Route';

  @override
  String routeCorridorSearching(int done, int total) {
    return '$done von $total Abschnitten geprüft';
  }

  @override
  String get routeCorridorEmpty =>
      'Auf dieser Route wurde kein passender Ladepark gefunden.';

  @override
  String get routeCorridorLimit =>
      'Es gibt mehr Treffer als angezeigt. Grenze die Route oder die Filter ein.';

  @override
  String get routeCorridorFailed =>
      'Einige Abschnitte konnten nicht geprüft werden.';

  @override
  String routeCorridorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ladeparks im Korridor',
      one: '1 Ladepark im Korridor',
    );
    return '$_temp0';
  }

  @override
  String get routeInsertStop => 'Ladestop einfügen';

  @override
  String get routeRemoveStop => 'Ladestop entfernen';

  @override
  String routeStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ladestopps',
      one: '1 Ladestopp',
      zero: 'Keine Ladestopps',
    );
    return '$_temp0';
  }
}
