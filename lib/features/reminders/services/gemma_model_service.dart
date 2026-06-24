import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the optional on-device LLM: its configuration (model URL, type,
/// token), installation/download, and readiness.
///
/// The model is opt-in. Until one is installed, reply interpretation falls back
/// to the rule-based parser, so the feature works out of the box.
class GemmaModelService {
  GemmaModelService(this._prefs);

  final SharedPreferences _prefs;

  static const _urlKey = 'ai.model.url';
  static const _tokenKey = 'ai.model.token';
  static const _typeKey = 'ai.model.type';
  static const _enabledKey = 'ai.enabled';

  String get modelUrl => _prefs.getString(_urlKey) ?? '';
  String get token => _prefs.getString(_tokenKey) ?? '';
  bool get enabled => _prefs.getBool(_enabledKey) ?? true;

  ModelType get modelType {
    final name = _prefs.getString(_typeKey);
    return ModelType.values
        .firstWhere((t) => t.name == name, orElse: () => ModelType.gemmaIt);
  }

  /// True when the user has AI enabled and a model is installed and active.
  bool get isReady => enabled && FlutterGemma.hasActiveModel();

  Future<void> setEnabled(bool value) => _prefs.setBool(_enabledKey, value);

  Future<void> saveConfig({
    required String url,
    required String token,
    required ModelType type,
  }) async {
    await _prefs.setString(_urlKey, url.trim());
    await _prefs.setString(_typeKey, type.name);
    if (token.trim().isEmpty) {
      await _prefs.remove(_tokenKey);
    } else {
      await _prefs.setString(_tokenKey, token.trim());
    }
  }

  /// Downloads + installs the configured model, reporting 0–100 progress.
  Future<void> install({required void Function(int percent) onProgress}) async {
    if (modelUrl.isEmpty) {
      throw StateError('Set a model URL before downloading.');
    }
    await FlutterGemma.installModel(modelType: modelType)
        .fromNetwork(modelUrl, token: token.isEmpty ? null : token)
        .withProgress(onProgress)
        .install();
  }
}
