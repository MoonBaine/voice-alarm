import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

/// Laczy nasze [AlarmItem] z pluginem `alarm`.
class AlarmService {
  static Future<void> schedule(AlarmItem a) async {
    if (!a.enabled) {
      await Alarm.stop(a.id);
      return;
    }
    final settings = AlarmSettings(
      id: a.id,
      dateTime: a.nextOccurrence(),
      assetAudioPath: a.soundPath,
      loopAudio: true,
      vibrate: true,
      androidFullScreenIntent: true,
      // Alarm musi grac dopoki nie zostanie nagrana glosowka.
      androidStopAlarmOnTermination: false,
      volumeSettings: VolumeSettings.fixed(volume: 1.0, volumeEnforced: true),
      notificationSettings: NotificationSettings(
        title: a.label.isEmpty ? 'Budzik' : a.label,
        body: 'Nagraj glosowke (min. 5 s), aby wylaczyc budzik',
        // Brak przycisku "Stop" i drzemki - wylaczenie tylko przez nagranie.
        androidStopAlarmOnDismiss: false,
        keepNotificationAfterAlarmEnds: false,
      ),
    );
    await Alarm.set(alarmSettings: settings);
  }

  static Future<void> cancel(AlarmItem a) => Alarm.stop(a.id);

  /// Po starcie aplikacji ustawia ponownie wszystkie wlaczone budziki.
  static Future<void> rescheduleAll() async {
    final list = Storage.instance.loadAlarms();
    for (final a in list) {
      if (a.enabled) await schedule(a);
    }
  }

  /// Wolane po poprawnym nagraniu: wylacza dzwonienie i planuje kolejne
  /// wystapienie (albo wylacza budzik jednorazowy).
  static Future<void> dismiss(int alarmId) async {
    await Alarm.stop(alarmId);
    final list = Storage.instance.loadAlarms();
    final idx = list.indexWhere((e) => e.id == alarmId);
    if (idx < 0) return;
    final a = list[idx];
    if (a.days.isEmpty) {
      a.enabled = false;
      await Storage.instance.saveAlarms(list);
    } else {
      await schedule(a);
    }
  }

  static String formatTime(BuildContext c, AlarmItem a) =>
      TimeOfDay(hour: a.hour, minute: a.minute).format(c);
}
