import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../alarm_service.dart';
import '../models.dart';
import '../storage.dart';
import 'alarm_edit_screen.dart';
import 'recordings_screen.dart';
import 'sounds_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlarmItem> _alarms = [];

  static const _dayNames = ['Pn', 'Wt', 'Sr', 'Cz', 'Pt', 'So', 'Nd'];

  @override
  void initState() {
    super.initState();
    _reload();
    _ensurePermissions();
  }

  void _reload() => setState(() => _alarms = Storage.instance.loadAlarms()
    ..sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute)));

  Future<void> _ensurePermissions() async {
    await Permission.notification.request();
    await Permission.microphone.request();
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  Future<void> _edit([AlarmItem? existing]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AlarmEditScreen(alarm: existing)),
    );
    if (changed == true) _reload();
  }

  Future<void> _toggle(AlarmItem a, bool on) async {
    final all = Storage.instance.loadAlarms();
    final item = all.firstWhere((e) => e.id == a.id);
    item.enabled = on;
    await Storage.instance.saveAlarms(all);
    await AlarmService.schedule(item);
    _reload();
  }

  Future<void> _delete(AlarmItem a) async {
    await AlarmService.cancel(a);
    final all = Storage.instance.loadAlarms()..removeWhere((e) => e.id == a.id);
    await Storage.instance.saveAlarms(all);
    _reload();
  }

  String _subtitle(AlarmItem a) {
    final days = a.days.isEmpty
        ? 'Jednorazowo'
        : (a.days.length == 7
            ? 'Codziennie'
            : (a.days.toList()..sort()).map((d) => _dayNames[d - 1]).join(' '));
    return a.label.isEmpty ? days : '${a.label} • $days';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Alarm'),
        actions: [
          IconButton(
            tooltip: 'Dzwieki',
            icon: const Icon(Icons.library_music),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const SoundsScreen())),
          ),
          IconButton(
            tooltip: 'Nagrania',
            icon: const Icon(Icons.mic),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute<void>(builder: (_) => const RecordingsScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        child: const Icon(Icons.add),
      ),
      body: _alarms.isEmpty
          ? const Center(child: Text('Brak budzikow. Dodaj pierwszy przyciskiem +'))
          : ListView.builder(
              itemCount: _alarms.length,
              itemBuilder: (context, i) {
                final a = _alarms[i];
                return Dismissible(
                  key: ValueKey(a.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _delete(a),
                  child: ListTile(
                    onTap: () => _edit(a),
                    title: Text(
                      AlarmService.formatTime(context, a),
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    subtitle: Text(_subtitle(a)),
                    trailing: Switch(value: a.enabled, onChanged: (v) => _toggle(a, v)),
                  ),
                );
              },
            ),
    );
  }
}
