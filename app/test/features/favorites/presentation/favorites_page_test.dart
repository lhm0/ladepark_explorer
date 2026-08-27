import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';
import 'package:ladepark_explorer/features/favorites/presentation/favorites_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

// Favorite-list behavior for FR-FAV-001.
void main() {
  testWidgets('keeps unavailable favorites visible and removable', (
    tester,
  ) async {
    var removed = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FavoritesPage(
          favorites: [_favorite],
          resolve: (_) async => null,
          open: (_) async => true,
          remove: (_) async => removed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gespeicherter Park'), findsOneWidget);
    expect(find.text('Im aktuellen Datensatz nicht verfügbar'), findsOneWidget);
    await tester.tap(find.byTooltip('Favorit entfernen'));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
    expect(
      find.text('Noch keine Ladeparks als Favoriten gespeichert.'),
      findsOneWidget,
    );
  });

  testWidgets('opens an available favorite', (tester) async {
    ChargingGroupDetail? opened;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FavoritesPage(
          favorites: [_favorite],
          resolve: (_) async => _detail,
          open: (detail) async {
            opened = detail;
            return true;
          },
          remove: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aktueller Park'), findsOneWidget);
    expect(find.text('Berlin · 24 Ladepunkte'), findsOneWidget);
    await tester.tap(find.text('Aktueller Park'));
    expect(opened, same(_detail));
  });
}

final _favorite = Favorite(
  anchorStationId: 'station-1',
  savedDiameterM: 50,
  savedAt: DateTime.utc(2026, 8, 26),
  displayName: 'Gespeicherter Park',
  city: 'Berlin',
  latitude: 52.52,
  longitude: 13.405,
);

const _detail = ChargingGroupDetail(
  groupId: 'group-1',
  anchorStationId: 'station-1',
  stationIds: <String>['station-1'],
  name: 'Aktueller Park',
  street: 'Testweg',
  houseNumber: '1',
  postalCode: '10115',
  city: 'Berlin',
  latitude: 52.52,
  longitude: 13.405,
  stationCount: 2,
  evseCount: 24,
  maxPowerKw: 300,
  actualDiameterM: 40,
  operators: [],
  connectorTypes: [],
  powerBandCounts: {},
  openingHours: null,
  datasetVersion: 'test',
  datasetCreatedAt: '2026-08-26T00:00:00Z',
  sourceName: 'Test',
  sourceVersion: 'test',
);
