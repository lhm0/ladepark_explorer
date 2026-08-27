import 'package:flutter/material.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

typedef FavoriteResolver =
    Future<ChargingGroupDetail?> Function(String anchorStationId);

typedef FavoriteOpener = Future<bool> Function(ChargingGroupDetail detail);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    required this.favorites,
    required this.resolve,
    required this.open,
    required this.remove,
    super.key,
  });

  final List<Favorite> favorites;
  final FavoriteResolver resolve;
  final FavoriteOpener open;
  final Future<void> Function(String anchorStationId) remove;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late List<Favorite> _favorites = widget.favorites;
  late Future<List<_ResolvedFavorite>> _resolved = _resolveAll();

  Future<List<_ResolvedFavorite>> _resolveAll() => Future.wait(
    _favorites.map(
      (favorite) async => _ResolvedFavorite(
        favorite,
        await widget.resolve(favorite.anchorStationId),
      ),
    ),
  );

  Future<void> _remove(Favorite favorite) async {
    await widget.remove(favorite.anchorStationId);
    if (!mounted) return;
    setState(() {
      _favorites = _favorites
          .where((item) => item.anchorStationId != favorite.anchorStationId)
          .toList(growable: false);
      _resolved = _resolveAll();
    });
  }

  Future<void> _open(_ResolvedFavorite resolved) async {
    final detail = resolved.detail;
    if (detail == null) return;
    final stillFavorite = await widget.open(detail);
    if (!mounted || stillFavorite) return;
    setState(() {
      _favorites = _favorites
          .where(
            (item) => item.anchorStationId != resolved.favorite.anchorStationId,
          )
          .toList(growable: false);
      _resolved = _resolveAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.favorites)),
      body: _favorites.isEmpty
          ? Center(child: Text(strings.noFavorites))
          : FutureBuilder<List<_ResolvedFavorite>>(
              future: _resolved,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.separated(
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final resolved = snapshot.data![index];
                    final detail = resolved.detail;
                    final favorite = resolved.favorite;
                    final name =
                        detail?.name ??
                        favorite.displayName ??
                        favorite.city ??
                        strings.chargingParkDetails;
                    final place =
                        <String?>[
                              detail?.city ?? favorite.city,
                              detail == null
                                  ? null
                                  : strings.evseCount(detail.evseCount),
                            ]
                            .whereType<String>()
                            .where((value) => value.isNotEmpty)
                            .join(' · ');
                    return ListTile(
                      leading: Icon(
                        detail == null
                            ? Icons.heart_broken_outlined
                            : Icons.favorite,
                        color: detail == null
                            ? Theme.of(context).colorScheme.outline
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        detail == null ? strings.favoriteUnavailable : place,
                      ),
                      trailing: IconButton(
                        tooltip: strings.removeFavorite,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _remove(favorite),
                      ),
                      onTap: detail == null ? null : () => _open(resolved),
                    );
                  },
                );
              },
            ),
    );
  }
}

final class _ResolvedFavorite {
  const _ResolvedFavorite(this.favorite, this.detail);

  final Favorite favorite;
  final ChargingGroupDetail? detail;
}
