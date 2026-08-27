import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/data/favorites/sqlite/sqlite_favorite_repository.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';
import 'package:ladepark_explorer/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:path_provider/path_provider.dart';

final favoriteRepositoryProvider = FutureProvider<FavoriteRepository>((
  ref,
) async {
  final directory = await getApplicationSupportDirectory();
  final repository = await SqliteFavoriteRepository.open(
    '${directory.path}/user.sqlite3',
  );
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final favoritesControllerProvider =
    AsyncNotifierProvider<FavoritesController, List<Favorite>>(
      FavoritesController.new,
    );

final class FavoritesController extends AsyncNotifier<List<Favorite>> {
  @override
  Future<List<Favorite>> build() async {
    final repository = await ref.watch(favoriteRepositoryProvider.future);
    return repository.getAll();
  }

  bool contains(String anchorStationId) =>
      state.value?.any(
        (favorite) => favorite.anchorStationId == anchorStationId,
      ) ??
      false;

  Future<void> toggle(ChargingGroupDetail detail, int diameterM) async {
    final repository = await ref.read(favoriteRepositoryProvider.future);
    if (contains(detail.anchorStationId)) {
      await repository.remove(detail.anchorStationId);
    } else {
      await repository.save(
        Favorite(
          anchorStationId: detail.anchorStationId,
          savedDiameterM: diameterM,
          savedAt: DateTime.now().toUtc(),
          displayName: detail.name,
          street: detail.street,
          houseNumber: detail.houseNumber,
          postalCode: detail.postalCode,
          city: detail.city,
          latitude: detail.latitude,
          longitude: detail.longitude,
        ),
      );
    }
    state = AsyncData(await repository.getAll());
  }

  Future<void> remove(String anchorStationId) async {
    final repository = await ref.read(favoriteRepositoryProvider.future);
    await repository.remove(anchorStationId);
    state = AsyncData(await repository.getAll());
  }
}
