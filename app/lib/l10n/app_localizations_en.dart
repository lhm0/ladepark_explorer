// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Charging Park Explorer';

  @override
  String get filters => 'Filters';

  @override
  String get search => 'Search';

  @override
  String get locationSearch => 'Search place or coordinate';

  @override
  String get locationSearchHint => 'Place, address, or charging park';

  @override
  String get coordinateSearchHint =>
      'Place names are resolved online with Apple Maps. Coordinates and direct Maps URLs also work.';

  @override
  String get noSearchResults =>
      'The place or a matching charging park nearby could not be found.';

  @override
  String get searchFailed => 'The local search could not be completed.';

  @override
  String searchResultChargingPoints(int count) {
    return '$count charging points';
  }

  @override
  String get nearbySearch => 'Charging parks near me';

  @override
  String get nearbyRadiusExplanation =>
      'Within which radius should charging parks be shown?';

  @override
  String get distanceFromCurrentLocation => 'Distance from current location';

  @override
  String get noDistanceLimit => 'No limit';

  @override
  String activeNearbyRadius(int radius) {
    return 'Within $radius km';
  }

  @override
  String get alwaysOpenOnly => 'Only continuously accessible charging';

  @override
  String get alwaysOpenOnlyExplanation =>
      'The required charging points must be accessible around the clock according to the data source.';

  @override
  String radiusKm(int radius) {
    return '$radius km';
  }

  @override
  String get locationPermissionDenied =>
      'Location access is not allowed. You can enable it in iOS Settings.';

  @override
  String get locationUnavailable =>
      'Your current location could not be determined.';

  @override
  String get groupDiameter => 'Maximum group diameter';

  @override
  String get minimumChargingPoints => 'Required charging points';

  @override
  String get minimumPower => 'Minimum power per charging point';

  @override
  String minimumChargingOffer(int count, int power) {
    return 'At least $count charging points, each with at least $power kW';
  }

  @override
  String get resetFilters => 'Restore defaults';

  @override
  String get cancelFilterChanges => 'Cancel';

  @override
  String get favoritesOnly => 'Show favorites only';

  @override
  String get infrastructureFilter => 'Amenities';

  @override
  String get infrastructureFilterExplanation =>
      'Every selected amenity must be verified as present. Missing information is treated as unknown.';

  @override
  String get anyValue => 'Any';

  @override
  String get filterSearch => 'Search choices';

  @override
  String get operatorCountExplanation =>
      'Number in parentheses: charging points in the dataset';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get done => 'Done';

  @override
  String get mapSemantics => 'Map with charging parks';

  @override
  String get mapUnavailable => 'Apple Maps is only available on iOS.';

  @override
  String get myLocation => 'My location';

  @override
  String get germanyOverview => 'Show Germany';

  @override
  String get loadingParks => 'Loading charging parks…';

  @override
  String visibleParks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charging parks',
      one: 'One charging park',
      zero: 'No charging parks',
    );
    return '$_temp0';
  }

  @override
  String visibleParksLimitReached(int count) {
    return '$count+ charging parks';
  }

  @override
  String get datasetMissing => 'The charging park dataset is missing.';

  @override
  String get datasetUnsupported =>
      'The charging park dataset uses an unsupported version.';

  @override
  String get invalidFilterQuery =>
      'The selected filters could not be processed.';

  @override
  String get chargingParksLoadFailed =>
      'The charging parks could not be loaded.';

  @override
  String get detailsUnavailable => 'Details could not be loaded.';

  @override
  String get chargingParkDetails => 'Charging park details';

  @override
  String stationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: 'One station',
    );
    return '$_temp0';
  }

  @override
  String evseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charging points',
      one: 'One charging point',
    );
    return '$_temp0';
  }

  @override
  String get operators => 'Operators';

  @override
  String get chargingPointsByOperator =>
      'Charging points by operator and power';

  @override
  String get power => 'Power';

  @override
  String get connectors => 'Connectors';

  @override
  String get unknown => 'Unknown';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get powerClasses => 'Power classes';

  @override
  String maximumPower(double power) {
    return 'Maximum $power kW';
  }

  @override
  String get maximumPowerUnknown => 'Maximum power unknown';

  @override
  String proximityApproximation(int diameter) {
    return 'Spatial approximation; actual group diameter: $diameter m. Access roads, streets and property boundaries have not been checked.';
  }

  @override
  String datasetVersion(String version) {
    return 'Dataset $version';
  }

  @override
  String dataSource(String source, String version) {
    return 'Source: $source, as of $version';
  }

  @override
  String datasetCreatedAt(String createdAt) {
    return 'Dataset created: $createdAt';
  }

  @override
  String get navigationUnavailable => 'The navigation app could not be opened.';

  @override
  String get openNavigation => 'Start route';

  @override
  String get settings => 'Settings';

  @override
  String get settingsUnavailable => 'Settings could not be loaded.';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get german => 'German';

  @override
  String get english => 'English';

  @override
  String get navigationApp => 'Navigation app';

  @override
  String get askEveryTime => 'Ask every time';

  @override
  String get notInstalled => 'Not installed';

  @override
  String get googleMapsUnavailable => 'Google Maps is unavailable';

  @override
  String get googleMapsFallbackExplanation =>
      'Google Maps is not installed. Open the route in Apple Maps instead?';

  @override
  String get useAppleMaps => 'Use Apple Maps';

  @override
  String get cancel => 'Cancel';

  @override
  String get datasetUpdates => 'Dataset updates';

  @override
  String get automaticUpdateChecks => 'Automatically check for updates';

  @override
  String get automaticUpdateChecksExplanation =>
      'Only the small manifest is fetched when the app starts. The dataset is downloaded after confirmation.';

  @override
  String get chargingDataset => 'Charging park dataset';

  @override
  String get updateNotChecked => 'Not checked yet';

  @override
  String get checkingForUpdates => 'Checking for updates…';

  @override
  String get datasetUpToDate => 'The installed dataset is up to date.';

  @override
  String updateAvailable(String version, String sizeMb) {
    return 'Version $version is available ($sizeMb MB).';
  }

  @override
  String downloadingUpdate(int percent) {
    return 'Downloading update: $percent%';
  }

  @override
  String updateInstalled(String version) {
    return 'Version $version was installed.';
  }

  @override
  String get updateCheckFailed => 'The update check failed.';

  @override
  String get installedDatasetRemainsActive =>
      'The previous dataset remains active and unchanged.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get checkNow => 'Check now';

  @override
  String get downloadUpdate => 'Download';

  @override
  String updateDownloadConfirmation(String version, String sizeMb) {
    return 'Version $version requires $sizeMb MB. The download may use Wi-Fi or mobile data. Download now?';
  }

  @override
  String get favorites => 'Favorites';

  @override
  String get noFavorites => 'No charging parks saved as favorites yet.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get favoriteUnavailable => 'Unavailable in the current dataset';

  @override
  String get onSiteInformation => 'Verified on site';

  @override
  String observedOn(String date) {
    return 'Observed on $date';
  }

  @override
  String photoCredit(String author, String date) {
    return 'Photo: $author, taken on $date';
  }

  @override
  String get restaurant => 'Restaurant';

  @override
  String get shop => 'Shop';

  @override
  String get coffeeMachine => 'Coffee machine';

  @override
  String get snackMachine => 'Snack machine';

  @override
  String get toilet => 'Toilet';

  @override
  String get amenityPresent => 'Present';

  @override
  String get amenityAbsent => 'Not present';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyAndDiagnostics => 'Privacy and diagnostics';

  @override
  String get privacySummary =>
      'No telemetry, crash reports, or advertising tracking';

  @override
  String get noTelemetry => 'No automatic transmission';

  @override
  String get noTelemetryExplanation =>
      'The app does not send usage events or crash reports to the developer. It contains no analytics, advertising, or tracking SDK.';

  @override
  String get localData => 'Data on this device';

  @override
  String get localDataExplanation =>
      'Favorites, settings, and downloaded charging datasets remain local. They are removed when the app is uninstalled.';

  @override
  String get externalServices => 'Deliberate network access';

  @override
  String get externalServicesExplanation =>
      'Apple provides the map and online place search. Update checks retrieve a manifest from GitHub. Starting navigation passes destination coordinates to Apple Maps or Google Maps.';

  @override
  String get localDiagnostics => 'Local diagnostic status';

  @override
  String get telemetryStatus => 'Telemetry: disabled';

  @override
  String get crashReportingStatus => 'Automatic crash reports: disabled';

  @override
  String get adTrackingStatus => 'Advertising and tracking: not included';

  @override
  String get datasetChecksEnabled => 'Automatic dataset checks: enabled';

  @override
  String get datasetChecksDisabled => 'Automatic dataset checks: disabled';

  @override
  String get copyDiagnostics => 'Copy diagnostic status';

  @override
  String get diagnosticsCopied => 'Diagnostic status copied.';

  @override
  String get diagnosticsPrivacyExplanation =>
      'The text contains no coordinates, search terms, favorites, or device identifier. It is copied to the clipboard only through this button and is never sent automatically.';

  @override
  String get routePlanning => 'Plan route';

  @override
  String get routePlanningTitle => 'Route planning';

  @override
  String get routeOnlineHint =>
      'The route is calculated online via Apple map services.';

  @override
  String get routeStartLabel => 'Start';

  @override
  String get routeDestinationLabel => 'Destination';

  @override
  String get routeEndpointHint => 'Place, address, or coordinate';

  @override
  String get routeUseCurrentLocation => 'Use current location as start';

  @override
  String get routeCalculate => 'Calculate route';

  @override
  String get routeCalculating => 'Calculating route …';

  @override
  String get routeStartNotFound => 'The start could not be found.';

  @override
  String get routeDestinationNotFound => 'The destination could not be found.';

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
  String get routeMapSemantics => 'Map showing the planned route';

  @override
  String get routeAlternativesHeading => 'Alternatives';

  @override
  String routeOptionLabel(int index) {
    return 'Route $index';
  }

  @override
  String get routeShowOnMap => 'Show on map';

  @override
  String get routeNewRoute => 'New route';

  @override
  String get routeClear => 'Clear route';

  @override
  String get routeErrorOffline =>
      'A route cannot be calculated without an internet connection.';

  @override
  String get routeErrorThrottled =>
      'The map service is busy right now. Please wait a moment and try again.';

  @override
  String get routeErrorNotFound =>
      'No route was found for the start and destination.';

  @override
  String get routeErrorInvalid => 'Start and destination are required.';

  @override
  String get routeErrorFailed => 'The route could not be calculated.';

  @override
  String get routeRetry => 'Try again';

  @override
  String get planRouteToHere => 'Plan a route here';

  @override
  String get routeCorridorTitle => 'Charging parks along the route';

  @override
  String routeCorridorSearching(int done, int total) {
    return '$done of $total sections checked';
  }

  @override
  String get routeCorridorEmpty =>
      'No matching charging park was found along this route.';

  @override
  String get routeCorridorLimit =>
      'There are more results than shown. Narrow the route or the filters.';

  @override
  String get routeCorridorFailed => 'Some sections could not be checked.';

  @override
  String routeCorridorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charging parks in the corridor',
      one: '1 charging park in the corridor',
    );
    return '$_temp0';
  }

  @override
  String get routeInsertStop => 'Insert charging stop';

  @override
  String get routeRemoveStop => 'Remove charging stop';

  @override
  String routeStopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charging stops',
      one: '1 charging stop',
      zero: 'No charging stops',
    );
    return '$_temp0';
  }

  @override
  String get routeStartSocLabel => 'Start state of charge';

  @override
  String get routeChargeTargetLabel => 'Charge target at stop';

  @override
  String get routeCorridorWidthLabel => 'Corridor width';

  @override
  String routeRangeDeficit(int km) {
    return 'Range only reaches km $km';
  }

  @override
  String routeSocBreakdownStart(int soc) {
    return 'Start $soc%';
  }

  @override
  String routeSocBreakdownStop(int index, int arrival, int departure) {
    return 'Stop $index: arrive ~$arrival% → leave $departure%';
  }

  @override
  String routeSocBreakdownTarget(int soc) {
    return 'Arrival ~$soc%';
  }

  @override
  String routeSocAtArrival(int soc) {
    return 'State of charge on arrival: ~$soc%';
  }

  @override
  String routeSocAfterStop(int soc) {
    return 'After the charging stop: $soc%';
  }

  @override
  String get vehicleProfileTitle => 'Vehicle profile';

  @override
  String get vehicleProfileExplanation =>
      'These values stay on this device only and are used for the range and charging estimation.';

  @override
  String get vehicleProfileNotSet => 'Not set up yet';

  @override
  String vehicleProfileSummary(String battery, String consumption) {
    return '$battery kWh · $consumption kWh/100 km';
  }

  @override
  String get vehicleBatteryLabel => 'Usable battery capacity (kWh)';

  @override
  String get vehicleConsumptionLabel => 'Average consumption (kWh/100 km)';

  @override
  String get vehicleMaxPowerLabel => 'Maximum charging power (kW)';

  @override
  String get vehicleReserveLabel => 'Reserve state of charge (%)';

  @override
  String get vehicleTargetLabel => 'Target state of charge on arrival (%)';

  @override
  String get vehicleStartLabel => 'Start state of charge (%)';

  @override
  String get vehicleConnectorsLabel => 'Compatible connector types';

  @override
  String get vehicleProfileSave => 'Save';

  @override
  String get vehicleProfileDelete => 'Delete profile';

  @override
  String get vehicleProfileSaved => 'Vehicle profile saved.';

  @override
  String get vehicleProfileInvalid =>
      'Enter battery capacity, consumption and charging power as positive numbers and the states of charge as percentages; the reserve must be below the target state of charge.';
}
