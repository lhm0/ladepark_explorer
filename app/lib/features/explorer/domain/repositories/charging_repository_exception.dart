enum ChargingRepositoryError {
  databaseNotFound,
  unsupportedSchema,
  invalidQuery,
  queryFailed,
  repositoryClosed,
  workerTerminated,
}

class ChargingRepositoryException implements Exception {
  const ChargingRepositoryException(this.error, this.message);

  final ChargingRepositoryError error;
  final String message;

  @override
  String toString() => 'ChargingRepositoryException($error): $message';
}
