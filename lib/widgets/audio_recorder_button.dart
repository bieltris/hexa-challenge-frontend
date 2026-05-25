import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

/// Botão de microfone com gravação tap-once até 5s.
/// Visual: anel de progresso 360° conforme tempo passa.
/// Tap durante gravação = stop imediato.
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
  static const int _minMs = 300;

  final _rec = AudioRecorder();
  String? _path;
  DateTime? _startedAt;
  Timer? _autoStopTimer;
  Timer? _tickTimer;
  bool _recording = false;
  int _elapsedMs = 0;

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _tickTimer?.cancel();
    _rec.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_recording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    if (_recording) return;
    final config = const RecordConfig(
      encoder: AudioEncoder.aacLc,
      bitRate: 64000,
      sampleRate: 44100,
      numChannels: 1,
    );
    final path = kIsWeb
        ? ''
        : '/tmp/cartolina_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Chama start direto dentro do gesto do usuário — browser dispara
    // popup nativo de permissão se estado = 'prompt'. iOS Safari só pede
    // permissão durante gesto direto, sem awaits intermediários.
    try {
      await _rec.start(config, path: path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Sem acesso ao microfone. Toque novamente para tentar ou autorize nas configurações do navegador.',
        ),
        duration: const Duration(seconds: 4),
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
    _tickTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
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
        content: Text('Áudio muito curto (mínimo 0.3s)'),
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
    final progress = _recording ? (_elapsedMs / _maxMs).clamp(0.0, 1.0) : 0.0;
    final remainingSec = _recording
        ? (((_maxMs - _elapsedMs) / 1000).ceil()).clamp(0, 5)
        : null;

    return GestureDetector(
      onTap: _onTap,
      child: SizedBox(
        width: widget.size + 12,
        height: widget.size + 12,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anel de progresso (countdown visual)
            if (_recording)
              SizedBox(
                width: widget.size + 8,
                height: widget.size + 8,
                child: CircularProgressIndicator(
                  value: 1.0 - progress, // diminui conforme tempo passa
                  strokeWidth: 3,
                  backgroundColor: Colors.red.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation(
                    progress < 0.6
                        ? const Color(0xFF00D45B)
                        : progress < 0.85
                            ? const Color(0xFFFFDF00)
                            : Colors.redAccent,
                  ),
                ),
              ),
            // Círculo do botão
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recording
                    ? Colors.red.withOpacity(0.88)
                    : Colors.transparent,
                boxShadow: _recording
                    ? [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.45),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _recording ? Icons.stop_rounded : Icons.mic,
                color: _recording ? Colors.white : widget.idleColor,
                size: widget.size * 0.55,
              ),
            ),
            // Contador de segundos
            if (_recording && remainingSec != null)
              Positioned(
                bottom: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${remainingSec}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
