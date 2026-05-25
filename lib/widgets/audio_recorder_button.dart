import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Botão de microfone com gravação long-press até 5s.
/// Solta = chama [onRecorded] com bytes do áudio + duração em ms + mime.
class AudioRecorderButton extends StatefulWidget {
  final void Function(Uint8List bytes, int durMs, String mime) onRecorded;
  final double size;
  final Color idleColor;

  const AudioRecorderButton({
    super.key,
    required this.onRecorded,
    this.size = 44,
    this.idleColor = Colors.white70,
  });

  @override
  State<AudioRecorderButton> createState() => _AudioRecorderButtonState();
}

class _AudioRecorderButtonState extends State<AudioRecorderButton>
    with SingleTickerProviderStateMixin {
  static const int _maxMs = 5000;
  static const int _minMs = 500;

  final _rec = AudioRecorder();
  String? _path;
  DateTime? _startedAt;
  Timer? _autoStopTimer;
  Timer? _tickTimer;
  bool _recording = false;
  int _elapsedMs = 0;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _autoStopTimer?.cancel();
    _tickTimer?.cancel();
    _rec.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (_recording) return;
    // Encoder: web suporta opus melhor; mobile aac. AAC funciona em ambos via record.
    final config = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 64000,
      sampleRate: 44100,
      numChannels: 1,
    );
    // Web: path é ignorado (blob URL gerado internamente). Mobile: precisa path.
    final path = kIsWeb
        ? ''
        : '/tmp/cartolina_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    // Chama start direto — browser exibe popup nativo se permissão = prompt.
    // hasPermission() retorna false em estado 'prompt' sem perguntar, por isso pulamos.
    try {
      await _rec.start(config, path: path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Sem acesso ao microfone. Autorize nas configurações do navegador.',
        ),
        duration: const Duration(seconds: 3),
      ));
      return;
    }
    if (!mounted) return;
    setState(() {
      _path = path;
      _recording = true;
      _startedAt = DateTime.now();
      _elapsedMs = 0;
    });
    _autoStopTimer = Timer(const Duration(milliseconds: _maxMs), _stop);
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedMs = DateTime.now().difference(_startedAt!).inMilliseconds;
      });
    });
  }

  Future<void> _stop() async {
    if (!_recording) return;
    _autoStopTimer?.cancel();
    _tickTimer?.cancel();
    final finalPath = await _rec.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    if (finalPath == null) return;
    final durMs = DateTime.now().difference(_startedAt!).inMilliseconds;
    if (durMs < _minMs) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Segure para gravar (mínimo 0.5s)'),
      ));
      if (!kIsWeb) {
        try {
          await File(finalPath).delete();
        } catch (_) {}
      }
      return;
    }

    try {
      Uint8List bytes;
      String mime;
      if (kIsWeb) {
        // finalPath é blob URL — fetch via http
        final res = await http.get(Uri.parse(finalPath));
        bytes = res.bodyBytes;
        mime = res.headers['content-type'] ?? 'audio/webm';
      } else {
        bytes = await File(finalPath).readAsBytes();
        mime = 'audio/mp4';
        try {
          await File(finalPath).delete();
        } catch (_) {}
      }
      widget.onRecorded(bytes, durMs.clamp(_minMs, _maxMs), mime);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar áudio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = _recording
        ? (((_maxMs - _elapsedMs) / 1000).ceil()).clamp(0, 5)
        : null;

    return GestureDetector(
      onLongPressStart: (_) => _start(),
      onLongPressEnd: (_) => _stop(),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Segure o botão para gravar (até 5s)'),
          duration: Duration(seconds: 1),
        ));
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _recording
                  ? Colors.red.withOpacity(0.85)
                  : Colors.transparent,
              boxShadow: _recording
                  ? [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.45 + _pulseCtrl.value * 0.3),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _recording ? Icons.fiber_manual_record : Icons.mic,
              color: _recording ? Colors.white : widget.idleColor,
              size: widget.size * 0.55,
            ),
          ),
          if (_recording)
            Positioned(
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${remaining}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
