// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Retorna true se o browser for Safari (e não Chrome/Chromium em cima do WebKit).
/// Em iOS, todos os browsers usam WebKit, portanto aacLc é necessário.
bool isSafari() {
  try {
    final ua = html.window.navigator.userAgent;
    // Chrome/Edge em desktop contêm "Chrome" ou "Chromium".
    // Chrome em iOS contém "CriOS". Firefox em iOS contém "FxiOS".
    // Safari puro não contém nenhum desses.
    final isChrome = ua.contains('Chrome') ||
        ua.contains('Chromium') ||
        ua.contains('CriOS');
    final isFirefox = ua.contains('Firefox') || ua.contains('FxiOS');
    return !isChrome && !isFirefox;
  } catch (_) {
    return false;
  }
}
