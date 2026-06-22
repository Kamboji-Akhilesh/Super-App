/// Wraps a piece of data together with provenance metadata so the UI can tell
/// the user whether they are looking at fresh or stale (offline) data.
class Cached<T> {
  const Cached({
    required this.data,
    required this.fetchedAt,
    required this.isStale,
  });

  /// The actual payload.
  final T data;

  /// When the underlying data was last fetched from the network.
  final DateTime? fetchedAt;

  /// `true` when the data was served from device storage instead of a fresh
  /// network response (offline, or the request failed).
  final bool isStale;

  Cached<R> map<R>(R Function(T value) convert) => Cached<R>(
        data: convert(data),
        fetchedAt: fetchedAt,
        isStale: isStale,
      );
}
