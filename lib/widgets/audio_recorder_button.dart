import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../platform/mic_recorder.dart';

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

  final _mic = MicRecorder();
  DateTime? _startedAt;
  Timer? _autoStopTimer;
  Timer? _tickTimer;
  bool _recording = false;
  int _elapsedMs = 0;

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _tickTimer?.cancel();
    _mic.dispose();
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
    try {
      await _mic.start();
    } catch (e) {
      if (!mounted) return;
      final err = e.toString().toLowerCase();
      final isPermission = err.contains('notallowed') ||
          err.contains('permission') ||
          err.contains('denied');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isPermission
              ? 'Sem acesso ao microfone. Autorize nas configurações do navegador e recarregue a página.'
              : 'Erro ao iniciar gravação: $e',
        ),
        duration: const Duration(seconds: 5),
      ));
      return;
    }

    if (!mounted) return;
    setState(() {
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
    final durMs = DateTime.now().difference(_startedAt!).inMilliseconds;

    ({Uint8List bytes, String mime}) result;
    try {
      result = await _mic.stop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _recording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar áudio: $e')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _recording = false);

    if (durMs < _minMs) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Áudio muito curto (mínimo 0.3s)'),
      ));
      return;
    }

    widget.onRecorded(result.bytes, durMs.clamp(_minMs, _maxMs), result.mime);
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
                  value: 1.0 - progress,
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
            // Contador de segundos restantes
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
