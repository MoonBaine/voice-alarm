import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../alarm_service.dart';
import '../models.dart';
import '../storage.dart';

class AlarmEditScreen extends StatefulWidget {
  const AlarmEditScreen({super.key, this.alarm});
  final AlarmItem? alarm;

  @override
  State<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends State<AlarmEditScreen> {
  late TimeOfDay _time;
  late Set<int> _days;
  late TextEditingController _label;
  String? _soundPath;

  static const _dayNames = ['Pn', 'Wt', 'Sr', 'Cz', 'Pt', 'So', 'Nd'];

  @override
  void initState() {
    super.initState();
    final a = widget.alarm;
    final now = TimeOfDay.now();
    _time = a == null ? now : TimeOfDay(hour: a.hour, minute: a.minute);
    _days = {...?a?.days};
    _label = TextEditingController(text: a?.label ?? '');
    _soundPath = a?.soundPath ?? builtInSounds.first.path;
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    // Bez mikrofonu nie daloby sie wylaczyc budzika - wymagamy zgody od razu.
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Potrzebna zgoda na mikrofon - bez niej nie wylaczysz budzika.'),
      ));
      return;
    }
    final all = Storage.instance.loadAlarms();
    final AlarmItem item;
    if (widget.alarm == null) {
      // Id musi miescic sie w int32 (plugin alarm).
      item = AlarmItem(id: DateTime.now().millisecondsSinceEpoch ~/ 1000 % 2147483647, hour: 0, minute: 0);
      all.add(item);
    } else {
      item = all.firstWhere((e) => e.id == widget.alarm!.id);
    }
    item
      ..hour = _time.hour
      ..minute = _time.minute
      ..days = _days
      ..label = _label.text.trim()
      ..soundPath = _soundPath
      ..enabled = true;
    await Storage.instance.saveAlarms(all);
    await AlarmService.schedule(item);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sounds = [...builtInSounds, ...Storage.instance.loadCustomSounds()];
    // Gdyby wybrany dzwiek zostal usuniety, wracamy do pierwszego.
    if (!sounds.any((s) => s.path == _soundPath)) _soundPath = sounds.first.path;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm == null ? 'Nowy budzik' : 'Edytuj budzik'),
        actions: [TextButton(onPressed: _save, child: const Text('Zapisz'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          InkWell(
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: _time);
              if (t != null) setState(() => _time = t);
            },
            child: Center(
              child: Text(_time.format(context), style: Theme.of(context).textTheme.displayLarge),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 6,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(_dayNames[d - 1]),
                  selected: _days.contains(d),
                  onSelected: (s) => setState(() => s ? _days.add(d) : _days.remove(d)),
                ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Brak zaznaczonych dni = budzik jednorazowy'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            decoration: const InputDecoration(labelText: 'Nazwa', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _soundPath,
            decoration: const InputDecoration(labelText: 'Dzwiek', border: OutlineInputBorder()),
            items: [
              for (final s in sounds) DropdownMenuItem(value: s.path, child: Text(s.name)),
            ],
            onChanged: (v) => setState(() => _soundPath = v),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Wlasne dzwieki dodasz w ekranie "Dzwieki" (ikona nutki).'),
          ),
        ],
      ),
    );
  }
}
