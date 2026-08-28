import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/settings/presentation/vehicle_profile_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../../support/fake_vehicle_profile_repository.dart';

// Editor regression for FR-ROUTE-005.
void main() {
  Future<FakeVehicleProfileRepository> pumpEditor(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeVehicleProfileRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleProfileRepositoryProvider.overrideWith(
            (ref) async => repository,
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                key: const ValueKey('open'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const VehicleProfilePage(),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open')));
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('saves a completed profile and returns', (tester) async {
    final repository = await pumpEditor(tester);

    await tester.enterText(find.byKey(const ValueKey('vehicle-battery')), '58');
    await tester.enterText(
      find.byKey(const ValueKey('vehicle-consumption')),
      '17,2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('vehicle-max-power')),
      '150',
    );
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final saved = await repository.loadVehicleProfile();
    expect(saved, isNotNull);
    expect(saved!.usableBatteryKwh, 58);
    expect(saved.consumptionKwhPer100Km, 17.2);
    expect(saved.maxChargePowerKw, 150);
    expect(find.byType(VehicleProfilePage), findsNothing);
  });

  testWidgets('shows an error for an incomplete profile', (tester) async {
    final repository = await pumpEditor(tester);

    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('positive Zahlen'), findsOneWidget);
    expect(await repository.loadVehicleProfile(), isNull);
    expect(find.byType(VehicleProfilePage), findsOneWidget);
  });
}
