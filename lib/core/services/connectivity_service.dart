import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper around `connectivity_plus` that answers a single question:
/// "is there a network connection right now?".
///
/// Note: connectivity only reports whether a network interface exists, not
/// whether the internet is actually reachable. The repository therefore still
/// guards network calls with try/catch and falls back to cache on failure.
class ConnectivityService {
  ConnectivityService([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isConnected(results);
  }

  /// Emits `true`/`false` as the device gains or loses connectivity.
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_isConnected);

  bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}
