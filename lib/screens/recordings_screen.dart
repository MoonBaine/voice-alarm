import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:share_plus/share_plus.dart';

import '../audio_preview.dart';
import '../models.dart';
import '../storage.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> {
  final _preview = AudioPreview();
  String? _playing;

  @override
  void initState() {
    super.initState();
    _preview.player.processingStateStream.listen((s) {
      if (s == ProcessingState.completed && mounted) setState(() => _playing = null);
    });
  }

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _toggle(RecordingItem r) async {
    if (_playing == r.path) {
      await _preview.stop();
      setState(() => _playing = null);
      return;
    }
    try {
      await _preview.play(r.path);
      setState(() => _playing = r.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nie mozna odtworzyc nagrania: $e')));
    }
  }

  Future<void> _share(RecordingItem r) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(Storage.instance.absolute(r.path), mimeType: 'audio/mp4')],
      text: 'Nagranie z budzika ${_fmt(r.createdAt)}',
    ));
  }

  Future<void> _delete(RecordingItem r) async {
    if (_playing == r.path) await _preview.stop();
    await Storage.instance.deleteRecording(r);
    setState(() => _playing = null);
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final items = Storage.instance.loadRecordings();
    return Scaffold(
      appBar: AppBar(title: const Text('Moje nagrania')),
      body: items.isEmpty
          ? const Center(child: Text('Nagrania pojawia sie tu po wylaczeniu budzika.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final r = items[i];
                final secs = (r.durationMs / 1000).toStringAsFixed(1);
                return ListTile(
                  leading: IconButton(
                    icon: Icon(_playing == r.path ? Icons.stop_circle : Icons.play_circle),
                    onPressed: () => _toggle(r),
                  ),
                  title: Text(_fmt(r.createdAt)),
                  subtitle: Text(r.alarmLabel.isEmpty ? '$secs s' : '${r.alarmLabel} • $secs s'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Udostepnij / zapisz',
                        icon: const Icon(Icons.share),
                        onPressed: () => _share(r),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(r),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
