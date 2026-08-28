import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/explorer_filters_repository.dart';

class FakeExplorerFiltersRepository implements ExplorerFiltersRepository {
  FakeExplorerFiltersRepository([this._stored]);

  ExplorerFilters? _stored;
  int saveCount = 0;

  ExplorerFilters? get stored => _stored;

  @override
  Future<ExplorerFilters?> loadFilters() async => _stored;

  @override
  Future<void> saveFilters(ExplorerFilters filters) async {
    _stored = filters;
    saveCount++;
  }
}
