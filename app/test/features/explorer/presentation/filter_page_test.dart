import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/presentation/filter_page.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

// Filter UI regression for FR-FILTER-001, FR-FILTER-002, FR-FILTER-003 and
// NFR-PERF-001.
void main() {
  testWidgets('edits multi-value filters and returns the selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ExplorerFilters? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              key: const ValueKey('open-filters'),
              onPressed: () async {
                result = await Navigator.push<ExplorerFilters>(
                  context,
                  MaterialPageRoute<ExplorerFilters>(
                    builder: (context) => FilterPage(
                      initialFilters: ExplorerFilters.defaults,
                      optionsFuture: Future.value(
                        const ChargingFilterOptions(
                          connectorTypes: <String>['ccs', 'type_2'],
                        ),
                      ),
                      popularOperatorsFuture:
                          Future.value(const <OperatorFilterOption>[
                            OperatorFilterOption(
                              value: 'operator-z',
                              displayName: 'Zeta Laden',
                              evseCount: 300,
                              isCanonical: true,
                            ),
                            OperatorFilterOption(
                              value: 'operator-b',
                              displayName: 'Betreiber B',
                              evseCount: 100,
                              isCanonical: true,
                            ),
                            OperatorFilterOption(
                              value: 'operator-a',
                              displayName: 'Alpha Laden',
                              evseCount: 200,
                              isCanonical: true,
                            ),
                          ]),
                      searchOperators: (text) async => const [],
                    ),
                  ),
                );
              },
              child: const Text('Filter öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('open-filters')));
    await tester.pumpAndSettle();
    final alpha = find.text('Alpha Laden (200)');
    final beta = find.text('Betreiber B (100)');
    final zeta = find.text('Zeta Laden (300)');
    expect(tester.getTopLeft(alpha).dy, lessThan(tester.getTopLeft(beta).dy));
    expect(tester.getTopLeft(beta).dy, lessThan(tester.getTopLeft(zeta).dy));
    expect(
      find.text('Zahl in Klammern: Ladepunkte im Datensatz'),
      findsOneWidget,
    );
    await tester.tap(beta);
    final connectorElement = find
        .byWidgetPredicate(
          (widget) =>
              widget is ListTile &&
              widget.key == const ValueKey('filter-Anschlüsse'),
        )
        .evaluate()
        .first;
    final connectorTile = find.byElementPredicate(
      (element) => identical(element, connectorElement),
    );
    await tester.ensureVisible(connectorTile);
    await tester.pumpAndSettle();
    await tester.tap(connectorTile);
    await tester.pumpAndSettle();
    final ccs = find.byKey(const ValueKey('selection-option-ccs'));
    final type2 = find.byKey(const ValueKey('selection-option-type_2'));
    expect(
      tester.getTopLeft(type2).dy - tester.getTopLeft(ccs).dy,
      lessThanOrEqualTo(30),
    );
    await tester.tap(ccs);
    await tester.tap(find.text('Fertig'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('favorites-only')));
    await tester.tap(find.byKey(const ValueKey('favorites-only')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('amenity-restaurant')),
    );
    await tester.tap(find.byKey(const ValueKey('amenity-restaurant')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('amenity-coffeeMachine')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('nearby-radius')));
    await tester.tap(find.byKey(const ValueKey('nearby-radius')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25 km').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('always-open-only')));
    await tester.tap(find.byKey(const ValueKey('always-open-only')));
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(result?.operatorIds, <String>['operator-b']);
    expect(result?.connectorTypes, <String>['ccs']);
    expect(result?.favoritesOnly, isTrue);
    expect(result?.requiredAmenities, <AmenityType>[
      AmenityType.restaurant,
      AmenityType.coffeeMachine,
    ]);
    expect(result?.nearbyRadiusKm, 25);
    expect(result?.alwaysOpenOnly, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reset restores the 50 m, 20 EVSE and 100 kW defaults', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ExplorerFilters? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await Navigator.push<ExplorerFilters>(
                  context,
                  MaterialPageRoute<ExplorerFilters>(
                    builder: (context) => FilterPage(
                      initialFilters: const ExplorerFilters(
                        diameterM: 200,
                        minimumEvseCount: 8,
                        minimumPowerKw: 50,
                        operatorNames: <String>['Betreiber A'],
                      ),
                      optionsFuture: Future.value(
                        const ChargingFilterOptions(),
                      ),
                      popularOperatorsFuture: Future.value(const []),
                      searchOperators: (text) async => const [],
                    ),
                  ),
                );
              },
              child: const Text('Filter öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Filter öffnen'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('reset-filters')).first);
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(result, ExplorerFilters.defaults);
    expect(result?.diameterM, 50);
    expect(result?.minimumEvseCount, 20);
    expect(result?.minimumPowerKw, 100);
    expect(result?.favoritesOnly, isFalse);
  });

  testWidgets('cancel restores the opening state and keeps the page open', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    ExplorerFilters? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                result = await Navigator.push<ExplorerFilters>(
                  context,
                  MaterialPageRoute<ExplorerFilters>(
                    builder: (context) => FilterPage(
                      initialFilters: const ExplorerFilters(
                        favoritesOnly: true,
                      ),
                      optionsFuture: Future.value(
                        const ChargingFilterOptions(),
                      ),
                      popularOperatorsFuture: Future.value(const []),
                      searchOperators: (_) async => const [],
                    ),
                  ),
                );
              },
              child: const Text('Filter öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Filter öffnen'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('favorites-only')));
    await tester.tap(find.byKey(const ValueKey('favorites-only')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('cancel-filter-changes')),
    );
    await tester.tap(find.byKey(const ValueKey('cancel-filter-changes')));
    await tester.pump();

    expect(find.byType(FilterPage), findsOneWidget);
    final toggle = tester.widget<SwitchListTile>(
      find.byKey(const ValueKey('favorites-only')),
    );
    expect(toggle.value, isTrue);
    expect(find.text('Standard herstellen'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(result?.favoritesOnly, isTrue);
  });
}
