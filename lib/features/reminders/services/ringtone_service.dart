import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Plays a looping ringtone (through the alarm stream so it's audible even on
/// silent) while a reminder "call" is ringing, until it's accepted/declined.
class RingtoneService {
  final FlutterRingtonePlayer _player = FlutterRingtonePlayer();

  Future<void> start() => _player.playRingtone(looping: true, asAlarm: true);

  Future<void> stop() => _player.stop();
}
