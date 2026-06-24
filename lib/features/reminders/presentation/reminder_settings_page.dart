import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_settings.dart';
import '../models/voice_language.dart';
import '../providers.dart';

class ReminderSettingsPage extends ConsumerStatefulWidget {
  const ReminderSettingsPage({super.key});

  static const String route = '/reminder-settings';

  @override
  ConsumerState<ReminderSettingsPage> createState() =>
      _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends ConsumerState<ReminderSettingsPage> {
  late final TextEditingController _url;
  late final TextEditingController _token;
  late ModelType _type;
  bool _downloading = false;
  int _progress = 0;

  /// A few small models that don't require a HuggingFace token.
  static const _suggestions = [
    ModelType.qwen,
    ModelType.qwen3,
    ModelType.phi,
    ModelType.deepSeek,
    ModelType.gemmaIt,
    ModelType.functionGemma,
  ];

  @override
  void initState() {
    super.initState();
    final svc = ref.read(gemmaModelServiceProvider);
    _url = TextEditingController(text: svc.modelUrl);
    _token = TextEditingController(text: svc.token);
    _type = svc.modelType;
  }

  @override
  void dispose() {
    _url.dispose();
    _token.dispose();
    super.dispose();
  }

  Future<void> _download() async {
    final svc = ref.read(gemmaModelServiceProvider);
    await svc.saveConfig(url: _url.text, token: _token.text, type: _type);
    setState(() {
      _downloading = true;
      _progress = 0;
    });
    try {
      await svc.install(onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Model installed. On-device AI is on.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(reminderSettingsProvider);
    final settingsCtrl = ref.read(reminderSettingsProvider.notifier);
    final ai = ref.watch(gemmaModelServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reminder settings')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Default confirmation interval'),
            subtitle: const Text(
                'Applied to new reminders. Each reminder can still override it.'),
            trailing: DropdownButton<int>(
              value: settings.defaultConfirmationMinutes,
              items: [
                for (final m in ReminderSettings.intervalChoices)
                  DropdownMenuItem(
                    value: m,
                    child: Text(m == 60 ? '1 hour' : '$m min'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) settingsCtrl.setDefaultMinutes(v);
              },
            ),
          ),
          ListTile(
            title: const Text('Voice language'),
            subtitle: const Text(
                'Language for the spoken reminder, speech input and call text.'),
            trailing: DropdownButton<String>(
              value: settings.languageCode,
              items: [
                for (final lang in VoiceLanguage.supported)
                  DropdownMenuItem(value: lang.code, child: Text(lang.label)),
              ],
              onChanged: (v) {
                if (v != null) settingsCtrl.setLanguage(v);
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Ring until accepted'),
            subtitle: const Text(
                'Ring a tone and keep the task hidden until you accept the '
                'call — so nothing private is shown or spoken if you’re away.'),
            value: settings.ringtoneEnabled,
            onChanged: settingsCtrl.setRingtoneEnabled,
          ),
          SwitchListTile(
            title: const Text('Speak & listen on the call'),
            subtitle:
                const Text('Read the task aloud and accept spoken replies.'),
            value: settings.voiceEnabled,
            onChanged: settingsCtrl.setVoiceEnabled,
          ),
          ListTile(
            title: const Text('Stop calling after'),
            subtitle: const Text(
                "How many 'did you do it?' check-ins before giving up."),
            trailing: DropdownButton<int>(
              value: settings.maxConfirmations,
              items: [
                for (final n in ReminderSettings.maxConfirmationChoices)
                  DropdownMenuItem(
                    value: n,
                    child: Text(n == 1 ? '1 check-in' : '$n check-ins'),
                  ),
              ],
              onChanged: (v) {
                if (v != null) settingsCtrl.setMaxConfirmations(v);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('On-device AI (optional)'),
            subtitle: Text(ai.isReady
                ? 'Active — spoken replies are understood by the on-device model.'
                : 'Not installed — using the built-in word matcher. Install a '
                    'model below to understand free-form replies.'),
            trailing: Icon(
              ai.isReady ? Icons.smart_toy : Icons.smart_toy_outlined,
              color: ai.isReady ? Colors.green : null,
            ),
          ),
          SwitchListTile(
            title: const Text('Use on-device AI when available'),
            value: ai.enabled,
            onChanged: (v) => setState(() => ai.setEnabled(v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'Model URL (.task / .litertlm)',
                    helperText: 'A small instruction model. Public models '
                        '(Qwen, Phi, DeepSeek) need no token; Gemma needs one.',
                    helperMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _token,
                  decoration: const InputDecoration(
                    labelText: 'HuggingFace token (only for gated models)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ModelType>(
                  initialValue:
                      _suggestions.contains(_type) ? _type : ModelType.gemmaIt,
                  decoration: const InputDecoration(labelText: 'Model family'),
                  items: [
                    for (final t in _suggestions)
                      DropdownMenuItem(value: t, child: Text(t.name)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 16),
                if (_downloading) ...[
                  LinearProgressIndicator(value: _progress / 100),
                  const SizedBox(height: 8),
                  Text('Downloading… $_progress%'),
                ] else
                  FilledButton.icon(
                    onPressed: _url.text.trim().isEmpty ? null : _download,
                    icon: const Icon(Icons.download),
                    label: Text(ai.isReady ? 'Replace model' : 'Download model'),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
