import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/presentation/map_screen.dart';
import 'package:ladepark_explorer/features/favorites/application/favorite_providers.dart';
import 'package:ladepark_explorer/features/park_info/application/park_information_providers.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/features/park_info/domain/repositories/park_information_repository.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../../support/fake_charging_repository.dart';
import '../../../support/fake_favorite_repository.dart';

// Detail layout regression for FR-DETAIL-001 and NFR-PERF-001.
void main() {
  testWidgets('details scroll without overflowing a constrained sheet', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                height: 373,
                child: GroupDetailSheet(
                  detail: _detail,
                  scrollController: scrollController,
                  enableFavoriteAction: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(scrollController.position.maxScrollExtent, greaterThan(0));
    expect(find.text('Betreiber Eins mit sehr langem Namen'), findsOneWidget);
    expect(find.text('0–50 kW'), findsOneWidget);
    expect(find.text('CCS: 2\nCHAdeMO: 3'), findsOneWidget);
    expect(find.text('CCS: 4'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Route starten'),
      300,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );

    expect(find.text('Route starten'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opaque detail page can be pushed and popped repeatedly', (
    tester,
  ) async {
    await tester.pumpWidget(const _DetailPageHarness());

    for (var iteration = 0; iteration < 4; iteration++) {
      await tester.tap(find.byKey(const ValueKey('open-detail')));
      await tester.pumpAndSettle();

      expect(find.byType(GroupDetailPage), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(GroupDetailPage), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('adds and removes a favorite from the detail view', (
    tester,
  ) async {
    final repository = FakeFavoriteRepository();
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteRepositoryProvider.overrideWith((ref) async => repository),
          chargingRepositoryProvider.overrideWith(
            (ref) async => FakeChargingRepository(detail: _detail),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GroupDetailSheet(
              detail: _detail,
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Als Favorit speichern'));
    await tester.pumpAndSettle();
    expect(await repository.getAll(), hasLength(1));
    expect(find.byTooltip('Favorit entfernen'), findsOneWidget);

    await tester.tap(find.byTooltip('Favorit entfernen'));
    await tester.pumpAndSettle();
    expect(await repository.getAll(), isEmpty);
  });

  testWidgets('shows reviewed amenities and their observation date', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          parkInformationRepositoryProvider.overrideWith(
            (ref) async => const _FakeParkInformationRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: GroupDetailSheet(
              detail: _detail,
              scrollController: scrollController,
              enableFavoriteAction: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vor Ort geprüft'), findsOneWidget);
    expect(find.text('Restaurant'), findsOneWidget);
    expect(find.text('Toilette'), findsOneWidget);
    expect(find.text('Erhoben am 2026-08-20'), findsOneWidget);
  });
}

class _FakeParkInformationRepository implements ParkInformationRepository {
  const _FakeParkInformationRepository();

  @override
  Future<List<String>> findStationIdsWithAmenities(
    List<AmenityType> requiredAmenities,
  ) async => const <String>[];

  @override
  Future<ParkInformation?> findForStations(
    List<String> stationIds, {
    required bool german,
  }) async => const ParkInformation(
    id: 'park-info-test',
    title: null,
    observedOn: '2026-08-20',
    notes: null,
    amenities: {
      AmenityType.restaurant: AmenityState.present,
      AmenityType.shop: AmenityState.absent,
      AmenityType.coffeeMachine: AmenityState.unknown,
      AmenityType.snackMachine: AmenityState.unknown,
      AmenityType.toilet: AmenityState.present,
    },
    photos: [],
  );
}

class _DetailPageHarness extends StatelessWidget {
  const _DetailPageHarness();

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open-detail'),
                onPressed: () => Navigator.of(context).push<void>(
                  PageRouteBuilder<void>(
                    opaque: true,
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        GroupDetailPage(
                          future: Future<ChargingGroupDetail?>.value(_detail),
                          enableFavoriteAction: false,
                        ),
                  ),
                ),
                child: const Text('Details öffnen'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _detail = ChargingGroupDetail(
  groupId: 'group-1',
  anchorStationId: 'station-1',
  stationIds: <String>['station-1'],
  name: 'Ausführlicher Ladeparkname für den Layouttest',
  street: 'Beispielstraße',
  houseNumber: '123',
  postalCode: '10115',
  city: 'Berlin',
  latitude: 52.5,
  longitude: 13.4,
  stationCount: 4,
  evseCount: 24,
  maxPowerKw: 400,
  actualDiameterM: 49.5,
  operators: <ChargingOperatorDetail>[
    ChargingOperatorDetail(
      name: 'Betreiber Eins mit sehr langem Namen',
      connectorCountsByPowerBand: <int, Map<String, int>>{
        0: <String, int>{'chademo': 3, 'ccs': 2},
        3: <String, int>{'ccs': 15},
      },
    ),
    ChargingOperatorDetail(
      name: 'Betreiber Zwei',
      connectorCountsByPowerBand: <int, Map<String, int>>{
        5: <String, int>{'ccs': 4},
      },
    ),
  ],
  connectorTypes: <String>['CCS', 'Typ 2'],
  powerBandCounts: <int, int>{50: 2, 100: 4, 150: 8, 300: 10},
  openingHours: 'Montag bis Sonntag rund um die Uhr geöffnet',
  datasetVersion: '2026.07.0-test',
  datasetCreatedAt: '2026-08-23T00:00:00Z',
  sourceName: 'Bundesnetzagentur Ladesäulenregister',
  sourceVersion: '2026-07-07',
);
