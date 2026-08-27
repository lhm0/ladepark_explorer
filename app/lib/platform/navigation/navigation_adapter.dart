abstract interface class NavigationAdapter {
  Future<bool> isAvailable();

  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? name,
  });
}
