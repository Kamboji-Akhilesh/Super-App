import 'dart:async';

import 'package:http/http.dart' as http;

import '../constants.dart';
import '../exceptions.dart';

/// Minimal HTTP client that returns raw response bodies and normalises
/// failures into [ApiException]s.
class ApiClient {
  ApiClient(this._client);

  final http.Client _client;

  /// Performs a GET and returns the raw response body on success.
  /// Throws [ApiException] on non-200 responses, timeouts or transport errors.
  Future<String> getRaw(Uri uri) async {
    try {
      final response =
          await _client.get(uri).timeout(ApiConfig.networkTimeout);
      if (response.statusCode != 200) {
        throw ApiException(
          'Request failed (${response.statusCode})',
          response.statusCode,
        );
      }
      return response.body;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The request timed out.');
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }
}
