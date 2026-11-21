import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../alarm_service.dart';
import '../models.dart';
import '../storage.dart';

/// Minimalny czas nagrania wymagany do wylaczenia budzika.
const minRecording = Duration(seconds: 5);

/// Ekran dzwoniacego budzika. Nie da sie z niego wyjsc przyciskiem "wstecz";
/// budzik gra dopoki nie zostanie nagrana glosowka >= [minRecording].
class RingScreen extends StatefulWidget {
  const RingScreen({super.key, required this.alarmId});
  final int alarmId;

  @override
  State<RingScreen> createState() => _RingScreenState();
}

class _RingScreenState extends State<RingScreen> {
  final _recorder = AudioRecorder();
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _recording = false;
  bool _saving = false;
  String? _currentRel;
  String? _error;
  late final AlarmItem? _alarm = Storage.instance
      .loadAlarms()
      .where((a) => a.id == widget.alarmId)
      .firstOrNull;

  Duration get _elapsed => _stopwatch.elapsed;
  bool get _longEnough => _elapsed >= minRecording;

  Future<void> _start() async {
    setState(() => _error = null);
    final status = await Permission.microphone.request();
    if (!status.isGranted || !await _recorder.hasPermission()) {
      setState(() => _error = 'Brak zgody na mikrofon. Zezwol w ustawieniach aplikacji.');
      if (status.isPermanentlyDenied) await openAppSettings();
      return;
    }
    final rel = p.join('recordings', '${DateTime.now().millisecondsSinceEpoch}.m4a');
    try {
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 96000, sampleRate: 44100),
        path: Storage.instance.absolute(rel),
      );
    } catch (e) {
      setState(() => _error = 'Nie udalo sie zaczac nagrywania: $e');
      return;
    }
    _currentRel = rel;
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) => setState(() {}));
    setState(() => _recording = true);
  }

  Future<void> _finish() async {
    if (!_longEnough || _saving) return;
    setState(() => _saving = true);
    _ticker?.cancel();
    _stopwatch.stop();
    final durationMs = _elapsed.inMilliseconds;
    try {
      await _recorder.stop();
      final list = Storage.instance.loadRecordings()
        ..insert(
          0,
          RecordingItem(
            path: _currentRel!,
            createdAt: DateTime.now(),
            durationMs: durationMs,
            alarmLabel: _alarm?.label ?? '',
          ),
        );
      await Storage.instance.saveRecordings(list);
      await AlarmService.dismiss(widget.alarmId);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _recording = false;
        _error = 'Blad zapisu nagrania: $e. Nagraj ponownie.';
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secs = _elapsed.inMilliseconds / 1000;
    final progress = (_elapsed.inMilliseconds / minRecording.inMilliseconds).clamp(0.0, 1.0);
    final remaining = (minRecording.inMilliseconds - _elapsed.inMilliseconds) / 1000;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.colorScheme.errorContainer,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm_on, size: 72),
                const SizedBox(height: 12),
                Text(
                  TimeOfDay.now().format(context),
                  style: theme.textTheme.displayLarge,
                ),
                if ((_alarm?.label ?? '').isNotEmpty)
                  Text(_alarm!.label, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 32),
                Text(
                  _recording
                      ? (_longEnough
                          ? 'Gotowe! Mozesz zakonczyc.'
                          : 'Mow dalej... jeszcze ${remaining.ceil()} s')
                      : 'Aby wylaczyc budzik, nagraj glosowke\n(minimum ${minRecording.inSeconds} sekund).',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                if (_recording) ...[
                  LinearProgressIndicator(value: progress, minHeight: 10),
                  const SizedBox(height: 8),
                  Text('${secs.toStringAsFixed(1)} s'),
                  const SizedBox(height: 24),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: !_recording
                      ? FilledButton.icon(
                          onPressed: _saving ? null : _start,
                          icon: const Icon(Icons.mic),
                          label: const Text('Zacznij nagrywac'),
                        )
                      : FilledButton.icon(
                          onPressed: _longEnough && !_saving ? _finish : null,
                          icon: const Icon(Icons.stop),
                          label: Text(_longEnough ? 'Zakoncz i wylacz budzik' : 'Nagrywam...'),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
