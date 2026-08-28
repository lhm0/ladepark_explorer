import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Ladepark Explorer'**
  String get appTitle;

  /// No description provided for @filters.
  ///
  /// In de, this message translates to:
  /// **'Filter'**
  String get filters;

  /// No description provided for @search.
  ///
  /// In de, this message translates to:
  /// **'Suchen'**
  String get search;

  /// No description provided for @locationSearch.
  ///
  /// In de, this message translates to:
  /// **'Ort oder Koordinate suchen'**
  String get locationSearch;

  /// No description provided for @locationSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Ort, Adresse oder Ladepark'**
  String get locationSearchHint;

  /// No description provided for @coordinateSearchHint.
  ///
  /// In de, this message translates to:
  /// **'Ortsnamen werden mit Apple Maps online aufgelöst. Koordinaten und direkte Maps-URLs funktionieren ebenfalls.'**
  String get coordinateSearchHint;

  /// No description provided for @noSearchResults.
  ///
  /// In de, this message translates to:
  /// **'Der Ort oder ein passender Ladepark in seiner Umgebung wurde nicht gefunden.'**
  String get noSearchResults;

  /// No description provided for @searchFailed.
  ///
  /// In de, this message translates to:
  /// **'Die lokale Suche konnte nicht ausgeführt werden.'**
  String get searchFailed;

  /// No description provided for @searchResultChargingPoints.
  ///
  /// In de, this message translates to:
  /// **'{count} Ladepunkte'**
  String searchResultChargingPoints(int count);

  /// No description provided for @nearbySearch.
  ///
  /// In de, this message translates to:
  /// **'Ladeparks in meiner Nähe'**
  String get nearbySearch;

  /// No description provided for @nearbyRadiusExplanation.
  ///
  /// In de, this message translates to:
  /// **'In welchem Umkreis sollen Ladeparks angezeigt werden?'**
  String get nearbyRadiusExplanation;

  /// No description provided for @distanceFromCurrentLocation.
  ///
  /// In de, this message translates to:
  /// **'Entfernung zum aktuellen Standort'**
  String get distanceFromCurrentLocation;

  /// No description provided for @noDistanceLimit.
  ///
  /// In de, this message translates to:
  /// **'Nicht begrenzen'**
  String get noDistanceLimit;

  /// No description provided for @activeNearbyRadius.
  ///
  /// In de, this message translates to:
  /// **'Umkreis {radius} km'**
  String activeNearbyRadius(int radius);

  /// No description provided for @alwaysOpenOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur durchgehend zugängliche Ladeangebote'**
  String get alwaysOpenOnly;

  /// No description provided for @alwaysOpenOnlyExplanation.
  ///
  /// In de, this message translates to:
  /// **'Die erforderlichen Ladepunkte müssen laut Datenquelle rund um die Uhr zugänglich sein.'**
  String get alwaysOpenOnlyExplanation;

  /// No description provided for @radiusKm.
  ///
  /// In de, this message translates to:
  /// **'{radius} km'**
  String radiusKm(int radius);

  /// No description provided for @locationPermissionDenied.
  ///
  /// In de, this message translates to:
  /// **'Der Standortzugriff ist nicht erlaubt. Du kannst ihn in den iOS-Einstellungen aktivieren.'**
  String get locationPermissionDenied;

  /// No description provided for @locationUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Der aktuelle Standort konnte nicht bestimmt werden.'**
  String get locationUnavailable;

  /// No description provided for @groupDiameter.
  ///
  /// In de, this message translates to:
  /// **'Maximaler Gruppendurchmesser'**
  String get groupDiameter;

  /// No description provided for @minimumChargingPoints.
  ///
  /// In de, this message translates to:
  /// **'Erforderliche Ladepunkte'**
  String get minimumChargingPoints;

  /// No description provided for @minimumPower.
  ///
  /// In de, this message translates to:
  /// **'Mindestleistung je Ladepunkt'**
  String get minimumPower;

  /// No description provided for @minimumChargingOffer.
  ///
  /// In de, this message translates to:
  /// **'Mindestens {count} Ladepunkte mit jeweils mindestens {power} kW'**
  String minimumChargingOffer(int count, int power);

  /// No description provided for @resetFilters.
  ///
  /// In de, this message translates to:
  /// **'Standard herstellen'**
  String get resetFilters;

  /// No description provided for @cancelFilterChanges.
  ///
  /// In de, this message translates to:
  /// **'Abbruch'**
  String get cancelFilterChanges;

  /// No description provided for @favoritesOnly.
  ///
  /// In de, this message translates to:
  /// **'Nur Favoriten anzeigen'**
  String get favoritesOnly;

  /// No description provided for @infrastructureFilter.
  ///
  /// In de, this message translates to:
  /// **'Ausstattung'**
  String get infrastructureFilter;

  /// No description provided for @infrastructureFilterExplanation.
  ///
  /// In de, this message translates to:
  /// **'Alle ausgewählten Merkmale müssen als vorhanden geprüft sein. Fehlende Angaben gelten als unbekannt.'**
  String get infrastructureFilterExplanation;

  /// No description provided for @anyValue.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get anyValue;

  /// No description provided for @filterSearch.
  ///
  /// In de, this message translates to:
  /// **'Auswahl durchsuchen'**
  String get filterSearch;

  /// No description provided for @operatorCountExplanation.
  ///
  /// In de, this message translates to:
  /// **'Zahl in Klammern: Ladepunkte im Datensatz'**
  String get operatorCountExplanation;

  /// No description provided for @clearSelection.
  ///
  /// In de, this message translates to:
  /// **'Auswahl löschen'**
  String get clearSelection;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @mapSemantics.
  ///
  /// In de, this message translates to:
  /// **'Karte mit Ladeparks'**
  String get mapSemantics;

  /// No description provided for @mapUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Apple-Karte ist nur auf iOS verfügbar.'**
  String get mapUnavailable;

  /// No description provided for @myLocation.
  ///
  /// In de, this message translates to:
  /// **'Mein Standort'**
  String get myLocation;

  /// No description provided for @germanyOverview.
  ///
  /// In de, this message translates to:
  /// **'Deutschland anzeigen'**
  String get germanyOverview;

  /// No description provided for @loadingParks.
  ///
  /// In de, this message translates to:
  /// **'Ladeparks werden geladen …'**
  String get loadingParks;

  /// No description provided for @visibleParks.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Ladeparks} =1{Ein Ladepark} other{{count} Ladeparks}}'**
  String visibleParks(int count);

  /// No description provided for @visibleParksLimitReached.
  ///
  /// In de, this message translates to:
  /// **'{count}+ Ladeparks'**
  String visibleParksLimitReached(int count);

  /// No description provided for @datasetMissing.
  ///
  /// In de, this message translates to:
  /// **'Der Ladepark-Datensatz fehlt.'**
  String get datasetMissing;

  /// No description provided for @datasetUnsupported.
  ///
  /// In de, this message translates to:
  /// **'Der Ladepark-Datensatz hat eine nicht unterstützte Version.'**
  String get datasetUnsupported;

  /// No description provided for @invalidFilterQuery.
  ///
  /// In de, this message translates to:
  /// **'Die gewählten Filter konnten nicht verarbeitet werden.'**
  String get invalidFilterQuery;

  /// No description provided for @chargingParksLoadFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Ladeparks konnten nicht geladen werden.'**
  String get chargingParksLoadFailed;

  /// No description provided for @detailsUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Details konnten nicht geladen werden.'**
  String get detailsUnavailable;

  /// No description provided for @chargingParkDetails.
  ///
  /// In de, this message translates to:
  /// **'Ladeparkdetails'**
  String get chargingParkDetails;

  /// No description provided for @stationCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Eine Station} other{{count} Stationen}}'**
  String stationCount(int count);

  /// No description provided for @evseCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{Ein Ladepunkt} other{{count} Ladepunkte}}'**
  String evseCount(int count);

  /// No description provided for @operators.
  ///
  /// In de, this message translates to:
  /// **'Betreiber'**
  String get operators;

  /// No description provided for @chargingPointsByOperator.
  ///
  /// In de, this message translates to:
  /// **'Ladepunkte nach Betreiber und Leistung'**
  String get chargingPointsByOperator;

  /// No description provided for @power.
  ///
  /// In de, this message translates to:
  /// **'Leistung'**
  String get power;

  /// No description provided for @connectors.
  ///
  /// In de, this message translates to:
  /// **'Anschlüsse'**
  String get connectors;

  /// No description provided for @unknown.
  ///
  /// In de, this message translates to:
  /// **'Unbekannt'**
  String get unknown;

  /// No description provided for @openingHours.
  ///
  /// In de, this message translates to:
  /// **'Öffnungszeiten'**
  String get openingHours;

  /// No description provided for @powerClasses.
  ///
  /// In de, this message translates to:
  /// **'Leistungsklassen'**
  String get powerClasses;

  /// No description provided for @maximumPower.
  ///
  /// In de, this message translates to:
  /// **'Maximal {power} kW'**
  String maximumPower(double power);

  /// No description provided for @maximumPowerUnknown.
  ///
  /// In de, this message translates to:
  /// **'Maximale Leistung unbekannt'**
  String get maximumPowerUnknown;

  /// No description provided for @proximityApproximation.
  ///
  /// In de, this message translates to:
  /// **'Räumliche Näherung; tatsächlicher Gruppendurchmesser: {diameter} m. Zufahrten, Straßen und Grundstücksgrenzen sind nicht geprüft.'**
  String proximityApproximation(int diameter);

  /// No description provided for @datasetVersion.
  ///
  /// In de, this message translates to:
  /// **'Datensatz {version}'**
  String datasetVersion(String version);

  /// No description provided for @dataSource.
  ///
  /// In de, this message translates to:
  /// **'Quelle: {source}, Stand {version}'**
  String dataSource(String source, String version);

  /// No description provided for @datasetCreatedAt.
  ///
  /// In de, this message translates to:
  /// **'Datensatz erstellt: {createdAt}'**
  String datasetCreatedAt(String createdAt);

  /// No description provided for @navigationUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Navigations-App konnte nicht geöffnet werden.'**
  String get navigationUnavailable;

  /// No description provided for @openNavigation.
  ///
  /// In de, this message translates to:
  /// **'Route starten'**
  String get openNavigation;

  /// No description provided for @settings.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// No description provided for @settingsUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Die Einstellungen konnten nicht geladen werden.'**
  String get settingsUnavailable;

  /// No description provided for @language.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get language;

  /// No description provided for @systemLanguage.
  ///
  /// In de, this message translates to:
  /// **'Systemsprache'**
  String get systemLanguage;

  /// No description provided for @german.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @english.
  ///
  /// In de, this message translates to:
  /// **'Englisch'**
  String get english;

  /// No description provided for @navigationApp.
  ///
  /// In de, this message translates to:
  /// **'Navigations-App'**
  String get navigationApp;

  /// No description provided for @askEveryTime.
  ///
  /// In de, this message translates to:
  /// **'Jedes Mal fragen'**
  String get askEveryTime;

  /// No description provided for @notInstalled.
  ///
  /// In de, this message translates to:
  /// **'Nicht installiert'**
  String get notInstalled;

  /// No description provided for @googleMapsUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Google Maps ist nicht verfügbar'**
  String get googleMapsUnavailable;

  /// No description provided for @googleMapsFallbackExplanation.
  ///
  /// In de, this message translates to:
  /// **'Google Maps ist nicht installiert. Soll die Route stattdessen in Apple Maps geöffnet werden?'**
  String get googleMapsFallbackExplanation;

  /// No description provided for @useAppleMaps.
  ///
  /// In de, this message translates to:
  /// **'Apple Maps verwenden'**
  String get useAppleMaps;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @datasetUpdates.
  ///
  /// In de, this message translates to:
  /// **'Datensatzupdates'**
  String get datasetUpdates;

  /// No description provided for @automaticUpdateChecks.
  ///
  /// In de, this message translates to:
  /// **'Automatisch nach Updates suchen'**
  String get automaticUpdateChecks;

  /// No description provided for @automaticUpdateChecksExplanation.
  ///
  /// In de, this message translates to:
  /// **'Beim App-Start wird nur das kleine Manifest abgerufen. Der Datensatz wird erst nach Bestätigung heruntergeladen.'**
  String get automaticUpdateChecksExplanation;

  /// No description provided for @chargingDataset.
  ///
  /// In de, this message translates to:
  /// **'Ladepark-Datensatz'**
  String get chargingDataset;

  /// No description provided for @updateNotChecked.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht geprüft'**
  String get updateNotChecked;

  /// No description provided for @checkingForUpdates.
  ///
  /// In de, this message translates to:
  /// **'Suche nach Updates …'**
  String get checkingForUpdates;

  /// No description provided for @datasetUpToDate.
  ///
  /// In de, this message translates to:
  /// **'Der installierte Datensatz ist aktuell.'**
  String get datasetUpToDate;

  /// No description provided for @updateAvailable.
  ///
  /// In de, this message translates to:
  /// **'Version {version} ist verfügbar ({sizeMb} MB).'**
  String updateAvailable(String version, String sizeMb);

  /// No description provided for @downloadingUpdate.
  ///
  /// In de, this message translates to:
  /// **'Update wird geladen: {percent} %'**
  String downloadingUpdate(int percent);

  /// No description provided for @updateInstalled.
  ///
  /// In de, this message translates to:
  /// **'Version {version} wurde installiert.'**
  String updateInstalled(String version);

  /// No description provided for @updateCheckFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Updateprüfung ist fehlgeschlagen.'**
  String get updateCheckFailed;

  /// No description provided for @installedDatasetRemainsActive.
  ///
  /// In de, this message translates to:
  /// **'Der bisherige Datensatz bleibt unverändert aktiv.'**
  String get installedDatasetRemainsActive;

  /// No description provided for @tryAgain.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get tryAgain;

  /// No description provided for @checkNow.
  ///
  /// In de, this message translates to:
  /// **'Jetzt prüfen'**
  String get checkNow;

  /// No description provided for @downloadUpdate.
  ///
  /// In de, this message translates to:
  /// **'Herunterladen'**
  String get downloadUpdate;

  /// No description provided for @updateDownloadConfirmation.
  ///
  /// In de, this message translates to:
  /// **'Version {version} benötigt {sizeMb} MB. Der Download darf WLAN oder Mobilfunk verwenden. Jetzt herunterladen?'**
  String updateDownloadConfirmation(String version, String sizeMb);

  /// No description provided for @favorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get favorites;

  /// No description provided for @noFavorites.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Ladeparks als Favoriten gespeichert.'**
  String get noFavorites;

  /// No description provided for @addFavorite.
  ///
  /// In de, this message translates to:
  /// **'Als Favorit speichern'**
  String get addFavorite;

  /// No description provided for @removeFavorite.
  ///
  /// In de, this message translates to:
  /// **'Favorit entfernen'**
  String get removeFavorite;

  /// No description provided for @favoriteUnavailable.
  ///
  /// In de, this message translates to:
  /// **'Im aktuellen Datensatz nicht verfügbar'**
  String get favoriteUnavailable;

  /// No description provided for @onSiteInformation.
  ///
  /// In de, this message translates to:
  /// **'Vor Ort geprüft'**
  String get onSiteInformation;

  /// No description provided for @observedOn.
  ///
  /// In de, this message translates to:
  /// **'Erhoben am {date}'**
  String observedOn(String date);

  /// No description provided for @photoCredit.
  ///
  /// In de, this message translates to:
  /// **'Foto: {author}, aufgenommen am {date}'**
  String photoCredit(String author, String date);

  /// No description provided for @restaurant.
  ///
  /// In de, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @shop.
  ///
  /// In de, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @coffeeMachine.
  ///
  /// In de, this message translates to:
  /// **'Kaffeeautomat'**
  String get coffeeMachine;

  /// No description provided for @snackMachine.
  ///
  /// In de, this message translates to:
  /// **'Snackautomat'**
  String get snackMachine;

  /// No description provided for @toilet.
  ///
  /// In de, this message translates to:
  /// **'Toilette'**
  String get toilet;

  /// No description provided for @amenityPresent.
  ///
  /// In de, this message translates to:
  /// **'Vorhanden'**
  String get amenityPresent;

  /// No description provided for @amenityAbsent.
  ///
  /// In de, this message translates to:
  /// **'Nicht vorhanden'**
  String get amenityAbsent;

  /// No description provided for @privacy.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz'**
  String get privacy;

  /// No description provided for @privacyAndDiagnostics.
  ///
  /// In de, this message translates to:
  /// **'Datenschutz und Diagnose'**
  String get privacyAndDiagnostics;

  /// No description provided for @privacySummary.
  ///
  /// In de, this message translates to:
  /// **'Keine Telemetrie, keine Absturzberichte und kein Werbetracking'**
  String get privacySummary;

  /// No description provided for @noTelemetry.
  ///
  /// In de, this message translates to:
  /// **'Keine automatische Übertragung'**
  String get noTelemetry;

  /// No description provided for @noTelemetryExplanation.
  ///
  /// In de, this message translates to:
  /// **'Die App übermittelt keine Nutzungsereignisse oder Absturzberichte an den Entwickler. Es gibt kein Analyse-, Werbe- oder Tracking-SDK.'**
  String get noTelemetryExplanation;

  /// No description provided for @localData.
  ///
  /// In de, this message translates to:
  /// **'Daten auf diesem Gerät'**
  String get localData;

  /// No description provided for @localDataExplanation.
  ///
  /// In de, this message translates to:
  /// **'Favoriten, Einstellungen und heruntergeladene Ladepark-Datensätze bleiben lokal. Sie werden bei einer Deinstallation der App entfernt.'**
  String get localDataExplanation;

  /// No description provided for @externalServices.
  ///
  /// In de, this message translates to:
  /// **'Bewusste Netzwerkzugriffe'**
  String get externalServices;

  /// No description provided for @externalServicesExplanation.
  ///
  /// In de, this message translates to:
  /// **'Apple stellt Karte und Online-Ortssuche bereit. Updateprüfungen rufen ein Manifest von GitHub ab. Beim Start einer Navigation werden Zielkoordinaten an Apple Maps oder Google Maps übergeben.'**
  String get externalServicesExplanation;

  /// No description provided for @localDiagnostics.
  ///
  /// In de, this message translates to:
  /// **'Lokaler Diagnosestatus'**
  String get localDiagnostics;

  /// No description provided for @telemetryStatus.
  ///
  /// In de, this message translates to:
  /// **'Telemetrie: deaktiviert'**
  String get telemetryStatus;

  /// No description provided for @crashReportingStatus.
  ///
  /// In de, this message translates to:
  /// **'Automatische Absturzberichte: deaktiviert'**
  String get crashReportingStatus;

  /// No description provided for @adTrackingStatus.
  ///
  /// In de, this message translates to:
  /// **'Werbung und Tracking: nicht enthalten'**
  String get adTrackingStatus;

  /// No description provided for @datasetChecksEnabled.
  ///
  /// In de, this message translates to:
  /// **'Automatische Datensatzprüfung: aktiviert'**
  String get datasetChecksEnabled;

  /// No description provided for @datasetChecksDisabled.
  ///
  /// In de, this message translates to:
  /// **'Automatische Datensatzprüfung: deaktiviert'**
  String get datasetChecksDisabled;

  /// No description provided for @copyDiagnostics.
  ///
  /// In de, this message translates to:
  /// **'Diagnosestatus kopieren'**
  String get copyDiagnostics;

  /// No description provided for @diagnosticsCopied.
  ///
  /// In de, this message translates to:
  /// **'Diagnosestatus wurde kopiert.'**
  String get diagnosticsCopied;

  /// No description provided for @diagnosticsPrivacyExplanation.
  ///
  /// In de, this message translates to:
  /// **'Der Text enthält keine Koordinaten, Suchbegriffe, Favoriten oder Gerätekennung. Er wird nur durch diese Schaltfläche in die Zwischenablage kopiert und nicht automatisch versendet.'**
  String get diagnosticsPrivacyExplanation;

  /// No description provided for @routePlanning.
  ///
  /// In de, this message translates to:
  /// **'Route planen'**
  String get routePlanning;

  /// No description provided for @routePlanningTitle.
  ///
  /// In de, this message translates to:
  /// **'Routenplanung'**
  String get routePlanningTitle;

  /// No description provided for @routeOnlineHint.
  ///
  /// In de, this message translates to:
  /// **'Die Route wird online über Apple-Kartendienste berechnet.'**
  String get routeOnlineHint;

  /// No description provided for @routeStartLabel.
  ///
  /// In de, this message translates to:
  /// **'Start'**
  String get routeStartLabel;

  /// No description provided for @routeDestinationLabel.
  ///
  /// In de, this message translates to:
  /// **'Ziel'**
  String get routeDestinationLabel;

  /// No description provided for @routeEndpointHint.
  ///
  /// In de, this message translates to:
  /// **'Ort, Adresse oder Koordinate'**
  String get routeEndpointHint;

  /// No description provided for @routeUseCurrentLocation.
  ///
  /// In de, this message translates to:
  /// **'Aktuellen Standort als Start verwenden'**
  String get routeUseCurrentLocation;

  /// No description provided for @routeCalculate.
  ///
  /// In de, this message translates to:
  /// **'Route berechnen'**
  String get routeCalculate;

  /// No description provided for @routeCalculating.
  ///
  /// In de, this message translates to:
  /// **'Route wird berechnet …'**
  String get routeCalculating;

  /// No description provided for @routeStartNotFound.
  ///
  /// In de, this message translates to:
  /// **'Der Start wurde nicht gefunden.'**
  String get routeStartNotFound;

  /// No description provided for @routeDestinationNotFound.
  ///
  /// In de, this message translates to:
  /// **'Das Ziel wurde nicht gefunden.'**
  String get routeDestinationNotFound;

  /// No description provided for @routeDurationHoursMinutes.
  ///
  /// In de, this message translates to:
  /// **'{hours} h {minutes} min'**
  String routeDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @routeDurationMinutes.
  ///
  /// In de, this message translates to:
  /// **'{minutes} min'**
  String routeDurationMinutes(int minutes);

  /// No description provided for @routeSummary.
  ///
  /// In de, this message translates to:
  /// **'{distance} · {duration}'**
  String routeSummary(String distance, String duration);

  /// No description provided for @routeDistanceKm.
  ///
  /// In de, this message translates to:
  /// **'{km} km'**
  String routeDistanceKm(String km);

  /// No description provided for @routeOverviewTitle.
  ///
  /// In de, this message translates to:
  /// **'Route'**
  String get routeOverviewTitle;

  /// No description provided for @routeMapSemantics.
  ///
  /// In de, this message translates to:
  /// **'Karte mit der geplanten Route'**
  String get routeMapSemantics;

  /// No description provided for @routeAlternativesHeading.
  ///
  /// In de, this message translates to:
  /// **'Alternativen'**
  String get routeAlternativesHeading;

  /// No description provided for @routeOptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Route {index}'**
  String routeOptionLabel(int index);

  /// No description provided for @routeShowOnMap.
  ///
  /// In de, this message translates to:
  /// **'Auf Karte anzeigen'**
  String get routeShowOnMap;

  /// No description provided for @routeNewRoute.
  ///
  /// In de, this message translates to:
  /// **'Neue Route'**
  String get routeNewRoute;

  /// No description provided for @routeClear.
  ///
  /// In de, this message translates to:
  /// **'Route beenden'**
  String get routeClear;

  /// No description provided for @routeErrorOffline.
  ///
  /// In de, this message translates to:
  /// **'Ohne Internetverbindung kann keine Route berechnet werden.'**
  String get routeErrorOffline;

  /// No description provided for @routeErrorThrottled.
  ///
  /// In de, this message translates to:
  /// **'Der Kartendienst ist zurzeit ausgelastet. Bitte kurz warten und erneut versuchen.'**
  String get routeErrorThrottled;

  /// No description provided for @routeErrorNotFound.
  ///
  /// In de, this message translates to:
  /// **'Für Start und Ziel wurde keine Route gefunden.'**
  String get routeErrorNotFound;

  /// No description provided for @routeErrorInvalid.
  ///
  /// In de, this message translates to:
  /// **'Start und Ziel müssen angegeben sein.'**
  String get routeErrorInvalid;

  /// No description provided for @routeErrorFailed.
  ///
  /// In de, this message translates to:
  /// **'Die Route konnte nicht berechnet werden.'**
  String get routeErrorFailed;

  /// No description provided for @routeRetry.
  ///
  /// In de, this message translates to:
  /// **'Erneut versuchen'**
  String get routeRetry;

  /// No description provided for @planRouteToHere.
  ///
  /// In de, this message translates to:
  /// **'Route hierher planen'**
  String get planRouteToHere;

  /// No description provided for @routeCorridorTitle.
  ///
  /// In de, this message translates to:
  /// **'Ladeparks entlang der Route'**
  String get routeCorridorTitle;

  /// No description provided for @routeCorridorSearching.
  ///
  /// In de, this message translates to:
  /// **'{done} von {total} Abschnitten geprüft'**
  String routeCorridorSearching(int done, int total);

  /// No description provided for @routeCorridorEmpty.
  ///
  /// In de, this message translates to:
  /// **'Auf dieser Route wurde kein passender Ladepark gefunden.'**
  String get routeCorridorEmpty;

  /// No description provided for @routeCorridorLimit.
  ///
  /// In de, this message translates to:
  /// **'Es gibt mehr Treffer als angezeigt. Grenze die Route oder die Filter ein.'**
  String get routeCorridorLimit;

  /// No description provided for @routeCorridorFailed.
  ///
  /// In de, this message translates to:
  /// **'Einige Abschnitte konnten nicht geprüft werden.'**
  String get routeCorridorFailed;

  /// No description provided for @routeCorridorCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =1{1 Ladepark im Korridor} other{{count} Ladeparks im Korridor}}'**
  String routeCorridorCount(int count);

  /// No description provided for @routeInsertStop.
  ///
  /// In de, this message translates to:
  /// **'Ladestop einfügen'**
  String get routeInsertStop;

  /// No description provided for @routeRemoveStop.
  ///
  /// In de, this message translates to:
  /// **'Ladestop entfernen'**
  String get routeRemoveStop;

  /// No description provided for @routeStopsCount.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Keine Ladestopps} =1{1 Ladestopp} other{{count} Ladestopps}}'**
  String routeStopsCount(int count);

  /// No description provided for @routeStartSocLabel.
  ///
  /// In de, this message translates to:
  /// **'Start-Ladezustand'**
  String get routeStartSocLabel;

  /// No description provided for @routeChargeTargetLabel.
  ///
  /// In de, this message translates to:
  /// **'Ladeziel je Stopp'**
  String get routeChargeTargetLabel;

  /// No description provided for @routeRangeDeficit.
  ///
  /// In de, this message translates to:
  /// **'Reichweite reicht nur bis km {km}'**
  String routeRangeDeficit(int km);

  /// No description provided for @routeSocBreakdownStart.
  ///
  /// In de, this message translates to:
  /// **'Start {soc} %'**
  String routeSocBreakdownStart(int soc);

  /// No description provided for @routeSocBreakdownStop.
  ///
  /// In de, this message translates to:
  /// **'Stopp {index}: an ~{arrival} % → ab {departure} %'**
  String routeSocBreakdownStop(int index, int arrival, int departure);

  /// No description provided for @routeSocBreakdownTarget.
  ///
  /// In de, this message translates to:
  /// **'Ziel ~{soc} %'**
  String routeSocBreakdownTarget(int soc);

  /// No description provided for @routeSocAtArrival.
  ///
  /// In de, this message translates to:
  /// **'Ladezustand bei Ankunft: ~{soc} %'**
  String routeSocAtArrival(int soc);

  /// No description provided for @routeSocAfterStop.
  ///
  /// In de, this message translates to:
  /// **'Nach dem Ladestopp: {soc} %'**
  String routeSocAfterStop(int soc);

  /// No description provided for @vehicleProfileTitle.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeugprofil'**
  String get vehicleProfileTitle;

  /// No description provided for @vehicleProfileExplanation.
  ///
  /// In de, this message translates to:
  /// **'Diese Angaben bleiben nur auf diesem Gerät und dienen der Reichweiten- und Ladeplanung.'**
  String get vehicleProfileExplanation;

  /// No description provided for @vehicleProfileNotSet.
  ///
  /// In de, this message translates to:
  /// **'Noch nicht angelegt'**
  String get vehicleProfileNotSet;

  /// No description provided for @vehicleProfileSummary.
  ///
  /// In de, this message translates to:
  /// **'{battery} kWh · {consumption} kWh/100 km'**
  String vehicleProfileSummary(String battery, String consumption);

  /// No description provided for @vehicleBatteryLabel.
  ///
  /// In de, this message translates to:
  /// **'Nutzbare Batteriekapazität (kWh)'**
  String get vehicleBatteryLabel;

  /// No description provided for @vehicleConsumptionLabel.
  ///
  /// In de, this message translates to:
  /// **'Durchschnittsverbrauch (kWh/100 km)'**
  String get vehicleConsumptionLabel;

  /// No description provided for @vehicleMaxPowerLabel.
  ///
  /// In de, this message translates to:
  /// **'Maximale Ladeleistung (kW)'**
  String get vehicleMaxPowerLabel;

  /// No description provided for @vehicleReserveLabel.
  ///
  /// In de, this message translates to:
  /// **'Reserve-Ladezustand (%)'**
  String get vehicleReserveLabel;

  /// No description provided for @vehicleTargetLabel.
  ///
  /// In de, this message translates to:
  /// **'Ziel-Ladezustand bei Ankunft (%)'**
  String get vehicleTargetLabel;

  /// No description provided for @vehicleStartLabel.
  ///
  /// In de, this message translates to:
  /// **'Start-Ladezustand (%)'**
  String get vehicleStartLabel;

  /// No description provided for @vehicleConnectorsLabel.
  ///
  /// In de, this message translates to:
  /// **'Kompatible Steckertypen'**
  String get vehicleConnectorsLabel;

  /// No description provided for @vehicleProfileSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get vehicleProfileSave;

  /// No description provided for @vehicleProfileDelete.
  ///
  /// In de, this message translates to:
  /// **'Profil löschen'**
  String get vehicleProfileDelete;

  /// No description provided for @vehicleProfileSaved.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeugprofil gespeichert.'**
  String get vehicleProfileSaved;

  /// No description provided for @vehicleProfileInvalid.
  ///
  /// In de, this message translates to:
  /// **'Bitte Batteriekapazität, Verbrauch und Ladeleistung als positive Zahlen und die Ladezustände in Prozent eingeben; die Reserve muss unter dem Ziel-Ladezustand liegen.'**
  String get vehicleProfileInvalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
