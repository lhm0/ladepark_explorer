import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/platform/navigation/apple_maps_navigation_adapter.dart';
import 'package:ladepark_explorer/platform/navigation/google_maps_navigation_adapter.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

final appleMapsNavigationAdapterProvider = Provider<NavigationAdapter>(
  (ref) => const AppleMapsNavigationAdapter(),
);

final googleMapsNavigationAdapterProvider = Provider<NavigationAdapter>(
  (ref) => const GoogleMapsNavigationAdapter(),
);

final googleMapsAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(googleMapsNavigationAdapterProvider).isAvailable(),
);
