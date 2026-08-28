import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';

/// Persists the map filter selection so it survives an app restart
/// (FR-FILTER-001). The transient "distance to current location" filter is
/// deliberately not part of this: it depends on a live location fix and is
/// reset on every start.
abstract interface class ExplorerFiltersRepository {
  /// The stored filter selection, or null if nothing has been saved yet.
  Future<ExplorerFilters?> loadFilters();

  /// Replaces the stored filter selection.
  Future<void> saveFilters(ExplorerFilters filters);
}
