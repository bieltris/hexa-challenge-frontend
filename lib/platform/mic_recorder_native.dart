import 'dart:io';
import 'dart:typed_data';
import 'package:record/record.dart';

class MicRecorder {
  final _rec = AudioRecorder();

  Future<void> start() async {
    await _rec.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path:
          '/tmp/cartolina_audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );
  }

  Future<({Uint8List bytes, String mime})> stop() async {
    final path = await _rec.stop();
    if (path == null) throw Exception('Gravação sem path');
    final bytes = await File(path).readAsBytes();
    try {
      await File(path).delete();
    } catch (_) {}
    return (bytes: bytes, mime: 'audio/mp4');
  }

  void dispose() => _rec.dispose();
}
