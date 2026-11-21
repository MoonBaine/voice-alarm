import 'package:just_audio/just_audio.dart';

import 'storage.dart';

/// Prosty odtwarzacz do podgladu dzwiekow i odsluchu nagran.
class AudioPreview {
  final AudioPlayer player = AudioPlayer();

  /// [path]: asset (assets/...) albo sciezka wzgledna w katalogu dokumentow.
  Future<void> play(String path) async {
    if (path.startsWith('assets/')) {
      await player.setAsset(path);
    } else {
      await player.setFilePath(Storage.instance.absolute(path));
    }
    await player.seek(Duration.zero);
    // play() konczy sie dopiero po zakonczeniu odtwarzania - nie czekamy.
    player.play();
  }

  Future<void> stop() => player.stop();

  void dispose() => player.dispose();
}
