import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'storage.dart';

/// Maksymalna liczba drzemek na jedno dzwonienie i ich dlugosc.
const maxSnoozes = 2;
const snoozeMinutes = 5;

/// Laczy nasze [AlarmItem] z pluginem `alarm`.
class AlarmService {
  /// Planuje budzik na najblizszy termin, albo na [at] (uzywane przez drzemke).
  static Future<void> schedule(AlarmItem a, {DateTime? at}) async {
    if (at == null) await Storage.instance.setSnoozeCount(a.id, 0);
    if (!a.enabled) {
      await Alarm.stop(a.id);
      return;
    }
    final settings = AlarmSettings(
      id: a.id,
      dateTime: at ?? a.nextOccurrence(),
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

  /// Po starcie aplikacji planuje wlaczone budziki, ktorych plugin jeszcze
  /// nie ma (juz zaplanowanych - w tym odlozonych drzemka - nie ruszamy).
  static Future<void> rescheduleAll() async {
    final existing = (await Alarm.getAlarms()).map((e) => e.id).toSet();
    final list = Storage.instance.loadAlarms();
    for (final a in list) {
      if (a.enabled && !existing.contains(a.id)) await schedule(a);
    }
  }

  /// Ile drzemek zostalo w biezacym dzwonieniu.
  static int snoozesLeft(int alarmId) {
    final left = maxSnoozes - Storage.instance.snoozeCount(alarmId);
    return left < 0 ? 0 : left;
  }

  /// Odklada budzik o [snoozeMinutes]. Zwraca false, gdy limit wyczerpany.
  static Future<bool> snooze(AlarmItem a) async {
    final used = Storage.instance.snoozeCount(a.id);
    if (used >= maxSnoozes) return false;
    await Alarm.stop(a.id);
    await schedule(a, at: DateTime.now().add(const Duration(minutes: snoozeMinutes)));
    await Storage.instance.setSnoozeCount(a.id, used + 1);
    return true;
  }

  /// Wolane po poprawnym nagraniu: wylacza dzwonienie i planuje kolejne
  /// wystapienie (albo wylacza budzik jednorazowy).
  static Future<void> dismiss(int alarmId) async {
    await Alarm.stop(alarmId);
    await Storage.instance.setSnoozeCount(alarmId, 0);
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
