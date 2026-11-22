import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Lokalne przechowywanie: metadane w SharedPreferences, pliki audio w
/// katalogu dokumentow aplikacji (sounds/, recordings/).
class Storage {
  Storage._(this._prefs, this.docsDir);

  final SharedPreferences _prefs;
  final Directory docsDir;

  static late final Storage instance;

  static Future<void> init() async {
    instance = Storage._(
      await SharedPreferences.getInstance(),
      await getApplicationDocumentsDirectory(),
    );
    await Directory(p.join(instance.docsDir.path, 'sounds')).create(recursive: true);
    await Directory(p.join(instance.docsDir.path, 'recordings')).create(recursive: true);
  }

  String absolute(String relative) => p.join(docsDir.path, relative);

  // ---- budziki ----
  List<AlarmItem> loadAlarms() => _loadList('alarms', AlarmItem.fromJson);
  Future<void> saveAlarms(List<AlarmItem> v) => _saveList('alarms', v.map((e) => e.toJson()));

  // ---- drzemki (ile razy uzyto w biezacym dzwonieniu) ----
  int snoozeCount(int alarmId) => _prefs.getInt('snooze_$alarmId') ?? 0;
  Future<void> setSnoozeCount(int alarmId, int n) =>
      n == 0 ? _prefs.remove('snooze_$alarmId') : _prefs.setInt('snooze_$alarmId', n);

  // ---- wlasne dzwieki ----
  List<SoundItem> loadCustomSounds() => _loadList('sounds', SoundItem.fromJson);
  Future<void> saveCustomSounds(List<SoundItem> v) => _saveList('sounds', v.map((e) => e.toJson()));

  // ---- nagrania ----
  List<RecordingItem> loadRecordings() => _loadList('recordings', RecordingItem.fromJson);
  Future<void> saveRecordings(List<RecordingItem> v) => _saveList('recordings', v.map((e) => e.toJson()));

  /// Kopiuje wybrany plik do katalogu aplikacji i zwraca wpis dzwieku.
  Future<SoundItem> importSound(String sourcePath, String displayName) async {
    final ext = p.extension(sourcePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}$ext';
    final rel = p.join('sounds', fileName);
    await File(sourcePath).copy(absolute(rel));
    final item = SoundItem(name: displayName, path: rel, builtIn: false);
    final all = loadCustomSounds()..add(item);
    await saveCustomSounds(all);
    return item;
  }

  Future<void> deleteSound(SoundItem s) async {
    final f = File(absolute(s.path));
    if (await f.exists()) await f.delete();
    await saveCustomSounds(loadCustomSounds()..removeWhere((e) => e.path == s.path));
  }

  Future<void> deleteRecording(RecordingItem r) async {
    final f = File(absolute(r.path));
    if (await f.exists()) await f.delete();
    await saveRecordings(loadRecordings()..removeWhere((e) => e.path == r.path));
  }

  List<T> _loadList<T>(String key, T Function(Map<String, dynamic>) from) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => from(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveList(String key, Iterable<Map<String, dynamic>> items) =>
      _prefs.setString(key, jsonEncode(items.toList()));
}
