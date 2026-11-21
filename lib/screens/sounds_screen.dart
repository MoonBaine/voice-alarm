import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../audio_preview.dart';
import '../models.dart';
import '../storage.dart';

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  final _preview = AudioPreview();
  String? _playing;

  @override
  void dispose() {
    _preview.dispose();
    super.dispose();
  }

  Future<void> _toggle(SoundItem s) async {
    if (_playing == s.path) {
      await _preview.stop();
      setState(() => _playing = null);
      return;
    }
    try {
      await _preview.play(s.path);
      setState(() => _playing = s.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Nie mozna odtworzyc pliku: $e')));
    }
  }

  Future<void> _import() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', 'mid', 'midi', 'amr'],
    );
    if (picked.isEmpty || picked.first.path == null) return;
    final f = picked.first;
    await Storage.instance.importSound(f.path!, p.basenameWithoutExtension(f.name));
    setState(() {});
  }

  Future<void> _delete(SoundItem s) async {
    if (_playing == s.path) await _preview.stop();
    await Storage.instance.deleteSound(s);
    setState(() => _playing = null);
  }

  @override
  Widget build(BuildContext context) {
    final custom = Storage.instance.loadCustomSounds();
    return Scaffold(
      appBar: AppBar(title: const Text('Dzwieki budzika')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _import,
        icon: const Icon(Icons.upload_file),
        label: const Text('Wgraj dzwiek'),
      ),
      body: ListView(
        children: [
          const ListTile(title: Text('Wbudowane')),
          for (final s in builtInSounds) _tile(s),
          const Divider(),
          const ListTile(title: Text('Twoje (mp3, wav, ogg, m4a, mid...)')),
          if (custom.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nic jeszcze nie wgrano.'),
            ),
          for (final s in custom) _tile(s, deletable: true),
        ],
      ),
    );
  }

  Widget _tile(SoundItem s, {bool deletable = false}) => ListTile(
        leading: IconButton(
          icon: Icon(_playing == s.path ? Icons.stop_circle : Icons.play_circle),
          onPressed: () => _toggle(s),
        ),
        title: Text(s.name),
        trailing: deletable
            ? IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(s))
            : null,
      );
}
