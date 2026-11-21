/// Dzwiek budzika. [path] to sciezka assetu (assets/...) albo
/// sciezka wzgledna do katalogu dokumentow aplikacji (sounds/...).
class SoundItem {
  SoundItem({required this.name, required this.path, required this.builtIn});

  final String name;
  final String path;
  final bool builtIn;

  Map<String, dynamic> toJson() => {'name': name, 'path': path, 'builtIn': builtIn};

  factory SoundItem.fromJson(Map<String, dynamic> j) => SoundItem(
        name: j['name'] as String,
        path: j['path'] as String,
        builtIn: j['builtIn'] as bool? ?? false,
      );
}

final List<SoundItem> builtInSounds = [
  SoundItem(name: 'Klasyczny budzik', path: 'assets/sounds/classic_beep.wav', builtIn: true),
  SoundItem(name: 'Melodia polifoniczna', path: 'assets/sounds/polyphonic_melody.wav', builtIn: true),
  SoundItem(name: 'Syrena', path: 'assets/sounds/rising_siren.wav', builtIn: true),
];

class AlarmItem {
  AlarmItem({
    required this.id,
    required this.hour,
    required this.minute,
    this.days = const {},
    this.enabled = true,
    this.label = '',
    this.soundPath,
  });

  /// Id uzywane tez w pluginie `alarm`.
  final int id;
  int hour;
  int minute;

  /// Dni tygodnia (DateTime.monday..sunday = 1..7). Puste = jednorazowy.
  Set<int> days;
  bool enabled;
  String label;

  /// null = domyslny dzwiek systemowy.
  String? soundPath;

  /// Najblizszy moment dzwonienia po [from].
  DateTime nextOccurrence([DateTime? from]) {
    final now = from ?? DateTime.now();
    for (var add = 0; add <= 7; add++) {
      final d = DateTime(now.year, now.month, now.day + add, hour, minute);
      if (!d.isAfter(now)) continue;
      if (days.isEmpty || days.contains(d.weekday)) return d;
    }
    // Nieosiagalne, ale kompilator tego nie wie.
    return DateTime(now.year, now.month, now.day + 1, hour, minute);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'hour': hour,
        'minute': minute,
        'days': days.toList(),
        'enabled': enabled,
        'label': label,
        'soundPath': soundPath,
      };

  factory AlarmItem.fromJson(Map<String, dynamic> j) => AlarmItem(
        id: j['id'] as int,
        hour: j['hour'] as int,
        minute: j['minute'] as int,
        days: ((j['days'] as List?) ?? const []).cast<int>().toSet(),
        enabled: j['enabled'] as bool? ?? true,
        label: j['label'] as String? ?? '',
        soundPath: j['soundPath'] as String?,
      );
}

class RecordingItem {
  RecordingItem({
    required this.path,
    required this.createdAt,
    required this.durationMs,
    this.alarmLabel = '',
  });

  /// Sciezka wzgledna do katalogu dokumentow (recordings/xxx.m4a).
  final String path;
  final DateTime createdAt;
  final int durationMs;
  final String alarmLabel;

  Map<String, dynamic> toJson() => {
        'path': path,
        'createdAt': createdAt.toIso8601String(),
        'durationMs': durationMs,
        'alarmLabel': alarmLabel,
      };

  factory RecordingItem.fromJson(Map<String, dynamic> j) => RecordingItem(
        path: j['path'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
        durationMs: j['durationMs'] as int,
        alarmLabel: j['alarmLabel'] as String? ?? '',
      );
}
