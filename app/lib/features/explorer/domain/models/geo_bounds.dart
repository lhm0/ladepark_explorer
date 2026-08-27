class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  }) : assert(south >= -90 && south <= north && north <= 90),
       assert(west >= -180 && west <= 180),
       assert(east >= -180 && east <= 180);

  final double south;
  final double west;
  final double north;
  final double east;
}
