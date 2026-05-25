// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:js_util' as js_util;
import 'dart:typed_data';

class MicRecorder {
  html.MediaRecorder? _recorder;
  html.MediaStream? _stream;
  final _chunks = <html.Blob>[];
  String _mime = '';

  Future<void> start() async {
    _mime = _pickMime();

    final devices = html.window.navigator.mediaDevices;
    if (devices == null) {
      throw Exception(
          'MediaDevices indisponível — a página precisa ser servida via HTTPS.');
    }

    // getUserMedia chamado diretamente dentro do gesto do usuário.
    // O browser mostra o popup de permissão aqui; qualquer negação
    // lança DomException com name == "NotAllowedError".
    _stream = await devices.getUserMedia({'audio': true, 'video': false});
    _chunks.clear();

    final opts =
        _mime.isNotEmpty ? {'mimeType': _mime} : <String, dynamic>{};
    _recorder = html.MediaRecorder(_stream!, opts);

    _recorder!.addEventListener('dataavailable', (e) {
      final blob = (e as html.BlobEvent).data;
      if (blob != null && blob.size > 0) _chunks.add(blob);
    });

    // timeslice 250ms → chunks frequentes, sem risco de perder dados
    _recorder!.start(250);
  }

  Future<({Uint8List bytes, String mime})> stop() async {
    if (_recorder == null) throw Exception('Não está gravando');

    final blobCompleter = Completer<html.Blob>();
    _recorder!.addEventListener('stop', (_) {
      blobCompleter.complete(
        html.Blob(_chunks, _mime.isNotEmpty ? _mime : 'audio/webm'),
      );
    });

    _recorder!.stop();
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
    _recorder = null;

    final blob = await blobCompleter.future;

    // Lê via FileReader → data URL (base64). Compatível com todos os browsers.
    final reader = html.FileReader();
    reader.readAsDataUrl(blob);
    await reader.onLoadEnd.first;

    final dataUrl = reader.result as String;
    final bytes = base64Decode(dataUrl.split(',').last);
    final mime = _mime.isNotEmpty ? _mime : 'audio/webm';

    return (bytes: bytes, mime: mime);
  }

  void dispose() {
    try {
      _recorder?.stop();
    } catch (_) {}
    _stream?.getTracks().forEach((t) => t.stop());
    _stream = null;
    _recorder = null;
  }

  // Escolhe o melhor MIME suportado pelo browser via MediaRecorder.isTypeSupported.
  static String _pickMime() {
    const candidates = [
      'audio/webm;codecs=opus', // Chrome, Firefox, Edge
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/mp4', // Safari (macOS/iOS)
    ];
    for (final m in candidates) {
      try {
        final ctor = js_util.getProperty<Object>(html.window, 'MediaRecorder');
        if (js_util.callMethod<bool>(ctor, 'isTypeSupported', [m])) return m;
      } catch (_) {}
    }
    return ''; // deixa o browser escolher
  }
}
