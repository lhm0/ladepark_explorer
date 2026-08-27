import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';

abstract interface class FavoriteRepository {
  Future<List<Favorite>> getAll();

  Future<void> save(Favorite favorite);

  Future<void> remove(String anchorStationId);

  Future<void> close();
}
