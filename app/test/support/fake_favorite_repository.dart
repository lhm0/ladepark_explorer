import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';
import 'package:ladepark_explorer/features/favorites/domain/repositories/favorite_repository.dart';

final class FakeFavoriteRepository implements FavoriteRepository {
  FakeFavoriteRepository([Iterable<Favorite> favorites = const []])
    : _favorites = List<Favorite>.of(favorites);

  final List<Favorite> _favorites;

  @override
  Future<List<Favorite>> getAll() async => List.unmodifiable(_favorites);

  @override
  Future<void> save(Favorite favorite) async {
    _favorites.removeWhere(
      (item) => item.anchorStationId == favorite.anchorStationId,
    );
    _favorites.add(favorite);
  }

  @override
  Future<void> remove(String anchorStationId) async {
    _favorites.removeWhere((item) => item.anchorStationId == anchorStationId);
  }

  @override
  Future<void> close() async {}
}
