/// Base type for all errors surfaced by the data layer.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// The network request failed (non-200, timeout, socket error, …).
class ApiException extends AppException {
  const ApiException(super.message, [this.statusCode]);
  final int? statusCode;
}

/// We are offline (or the request failed) and there is no cached copy to
/// fall back to.
class CacheMissException extends AppException {
  const CacheMissException(super.message);
}
