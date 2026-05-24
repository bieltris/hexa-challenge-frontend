import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _kShareUrl = 'https://hexa-challenge.pages.dev';
const _kShareText =
    'Joga Hexa Challenge comigo! ⚽\nDuelo de pênalti entre escolas — Copa 2026';
const _kShareFull = '$_kShareText\n$_kShareUrl';
const _kShareSubject = 'Hexa Challenge — entra no jogo!';

/// Tenta share nativo; se falhar, abre modal com botões de apps.
Future<void> openShare(BuildContext context) async {
  try {
    final result = await Share.share(_kShareFull, subject: _kShareSubject);
    // success ou usuário cancelou — não abre modal
    if (result.status == ShareResultStatus.unavailable) {
      if (context.mounted) _showSheet(context);
    }
  } catch (_) {
    if (context.mounted) _showSheet(context);
  }
}

void _showSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF001A4E),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(child: _ShareSheetBody()),
  );
}

class _ShareSheetBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final apps = <_App>[
      _App(
        label: 'WhatsApp',
        emoji: '💬',
        bg: const Color(0xFF25D366),
        url: 'https://wa.me/?text=${Uri.encodeComponent(_kShareFull)}',
      ),
      _App(
        label: 'Telegram',
        emoji: '✈️',
        bg: const Color(0xFF0088CC),
        url:
            'https://t.me/share/url?url=${Uri.encodeComponent(_kShareUrl)}&text=${Uri.encodeComponent(_kShareText)}',
      ),
      _App(
        label: 'X / Twitter',
        emoji: '🐦',
        bg: const Color(0xFF000000),
        url: 'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(_kShareFull)}',
      ),
      _App(
        label: 'Facebook',
        emoji: '📘',
        bg: const Color(0xFF1877F2),
        url: 'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(_kShareUrl)}',
      ),
      _App(
        label: 'Email',
        emoji: '✉️',
        bg: const Color(0xFF555555),
        url:
            'mailto:?subject=${Uri.encodeComponent(_kShareSubject)}&body=${Uri.encodeComponent(_kShareFull)}',
      ),
      _App(
        label: 'Copiar link',
        emoji: '📋',
        bg: const Color(0xFFFFDF00),
        textDark: true,
        onTap: (ctx) async {
          await Clipboard.setData(const ClipboardData(text: _kShareFull));
          if (ctx.mounted) {
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF009C3B),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(12),
              content: Text('Link copiado! 🚀',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              duration: const Duration(seconds: 3),
            ));
          }
        },
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // grab handle
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Compartilhar Hexa Challenge',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Chama a galera!',
              style: GoogleFonts.poppins(
                  color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: apps.map((a) => _AppButton(app: a)).toList(),
          ),
        ],
      ),
    );
  }
}

class _App {
  final String label, emoji;
  final Color bg;
  final bool textDark;
  final String? url;
  final Future<void> Function(BuildContext)? onTap;
  _App({
    required this.label,
    required this.emoji,
    required this.bg,
    this.textDark = false,
    this.url,
    this.onTap,
  });
}

class _AppButton extends StatelessWidget {
  final _App app;
  const _AppButton({required this.app});

  @override
  Widget build(BuildContext context) {
    final fg = app.textDark ? const Color(0xFF001040) : Colors.white;
    return SizedBox(
      width: 86,
      child: GestureDetector(
        onTap: () async {
          if (app.onTap != null) {
            await app.onTap!(context);
            return;
          }
          if (app.url != null) {
            final uri = Uri.parse(app.url!);
            try {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } catch (_) {
              try {
                await launchUrl(uri);
              } catch (_) {}
            }
            if (context.mounted) Navigator.pop(context);
          }
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: app.bg,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Center(
                  child:
                      Text(app.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(height: 6),
            Text(app.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    color: fg == const Color(0xFF001040)
                        ? Colors.white
                        : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
