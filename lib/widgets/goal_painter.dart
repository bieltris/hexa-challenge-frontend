import 'dart:math';
import 'package:flutter/material.dart';

// ── Layout constants ─────────────────────────────────────────────────────────
// Goal ocupa de 4% a 58% da altura do widget → proporção ~1.6:1 (retangular)
// A área abaixo (58%–100%) mostra grama + ponto de pênalti
const double _kPostWidth = 11.0;
const double _kGoalTopRatio = 0.04;
const double _kGoalBottomRatio = 0.58; // ← chave para goal retangular

// ── Keeper state ─────────────────────────────────────────────────────────────
enum KeeperState { idle, jumpLeft, jumpRight }

// ── GoalPainter ──────────────────────────────────────────────────────────────
class GoalPainter extends CustomPainter {
  final int? highlightedZone;
  final bool showZones;
  final bool showKeeper;
  final double pulseValue;       // 0.0–1.0, AnimationController repeat(reverse)
  final double keeperPosition;   // -1.0 (esq.) a 1.0 (dir.)
  final bool keeperJumping;

  const GoalPainter({
    this.highlightedZone,
    this.showZones = true,
    this.showKeeper = true,
    this.pulseValue = 0.5,
    this.keeperPosition = 0.0,
    this.keeperJumping = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final gL = _kPostWidth * 0.5;
    final gR = w - _kPostWidth * 0.5;
    final gT = h * _kGoalTopRatio;
    final gB = h * _kGoalBottomRatio;
    final gW = gR - gL;
    final gH = gB - gT;

    // Ordem de desenho: fundo → rede → alvos → goleiro → traves
    _drawGrass(canvas, w, h, gB);
    _drawNetInterior(canvas, gL, gT, gR, gB, gH);
    _drawDiagonalNet(canvas, gL, gT, gR, gB);
    if (showZones) {
      if (highlightedZone != null) _drawZoneHighlight(canvas, gL, gT, gW, gH);
      _drawZoneDividers(canvas, gL, gT, gR, gB, gW, gH);
      _drawTargetCircles(canvas, gL, gT, gW, gH);
    }
    if (showKeeper) _drawKeeper(canvas, gL, gT, gR, gB, gW, gH);
    _drawPostsAndFrame(canvas, gL, gT, gR, gB);
    _drawFieldBelow(canvas, gL, gR, gB, h);
  }

  // ── Grama ─────────────────────────────────────────────────────────────────

  void _drawGrass(Canvas canvas, double w, double h, double gB) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  // ── Interior da rede (gradiente de profundidade) ──────────────────────────

  void _drawNetInterior(Canvas canvas, double gL, double gT, double gR,
      double gB, double gH) {
    canvas.drawRect(
      Rect.fromLTRB(gL, gT, gR, gB),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.62),
            Colors.black.withOpacity(0.32),
            Colors.black.withOpacity(0.08),
          ],
        ).createShader(Rect.fromLTRB(gL, gT, gR, gB)),
    );

    // Sombras laterais (profundidade)
    for (final isLeft in [true, false]) {
      final x = isLeft ? gL : gR - (gR - gL) * 0.1;
      canvas.drawRect(
        Rect.fromLTWH(x, gT, (gR - gL) * 0.1, gB - gT),
        Paint()
          ..shader = LinearGradient(
            begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            colors: [Colors.black.withOpacity(0.28), Colors.transparent],
          ).createShader(Rect.fromLTRB(gL, gT, gR, gB)),
      );
    }
  }

  // ── Rede diagonal (losango) ───────────────────────────────────────────────

  void _drawDiagonalNet(
      Canvas canvas, double gL, double gT, double gR, double gB) {
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(gL, gT, gR, gB));

    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 0.7;

    const spacing = 18.0;
    final gH = gB - gT;

    for (double d = -gH; d <= (gR - gL); d += spacing) {
      canvas.drawLine(Offset(gL + d, gT), Offset(gL + d + gH, gB), netPaint);
      canvas.drawLine(Offset(gL + d + gH, gT), Offset(gL + d, gB), netPaint);
    }

    canvas.restore();
  }

  // ── Destaque de zona ──────────────────────────────────────────────────────

  void _drawZoneHighlight(
      Canvas canvas, double gL, double gT, double gW, double gH) {
    final col = highlightedZone! % 3;
    final row = highlightedZone! ~/ 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(gL + col * gW / 3 + 2, gT + row * gH / 3 + 2,
            gW / 3 - 4, gH / 3 - 4),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFFFDF00).withOpacity(0.36),
    );
  }

  // ── Divisórias de zona ────────────────────────────────────────────────────

  void _drawZoneDividers(Canvas canvas, double gL, double gT, double gR,
      double gB, double gW, double gH) {
    final divPaint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
          Offset(gL + gW / 3 * i, gT + 3), Offset(gL + gW / 3 * i, gB - 3), divPaint);
      canvas.drawLine(
          Offset(gL + 3, gT + gH / 3 * i), Offset(gR - 3, gT + gH / 3 * i), divPaint);
    }
  }

  // ── Círculos de alvo (pulsantes) ──────────────────────────────────────────

  void _drawTargetCircles(
      Canvas canvas, double gL, double gT, double gW, double gH) {
    final colW = gW / 3;
    final rowH = gH / 3;

    final outerOp = 0.30 + pulseValue * 0.32;
    final scale = 1.0 + pulseValue * 0.09;

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final cx = gL + colW * col + colW / 2;
        final cy = gT + rowH * row + rowH / 2;
        final r = min(colW, rowH) * 0.26 * scale;

        // Glow atrás
        canvas.drawCircle(
            Offset(cx, cy), r * 1.6,
            Paint()..color = Colors.white.withOpacity(outerOp * 0.18));

        // Anel externo
        canvas.drawCircle(
            Offset(cx, cy), r,
            Paint()
              ..color = Colors.white.withOpacity(outerOp)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0);

        // Anel médio
        canvas.drawCircle(
            Offset(cx, cy), r * 0.52,
            Paint()
              ..color = Colors.white.withOpacity(outerOp * 0.7)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0);

        // Ponto central
        canvas.drawCircle(
            Offset(cx, cy), r * 0.16,
            Paint()..color = Colors.white.withOpacity(outerOp + 0.25));

        // Mira
        final mg = r * 0.22;
        final ml = r * 0.38;
        final mp = Paint()
          ..color = Colors.white.withOpacity(outerOp * 0.75)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx, cy - mg), Offset(cx, cy - mg - ml), mp);
        canvas.drawLine(Offset(cx, cy + mg), Offset(cx, cy + mg + ml), mp);
        canvas.drawLine(Offset(cx - mg, cy), Offset(cx - mg - ml, cy), mp);
        canvas.drawLine(Offset(cx + mg, cy), Offset(cx + mg + ml, cy), mp);
      }
    }
  }

  // ── Goleiro desenhado dentro do gol ───────────────────────────────────────

  void _drawKeeper(Canvas canvas, double gL, double gT, double gR, double gB,
      double gW, double gH) {
    // Centro X baseado na posição (-1 a 1)
    final cx = gL + gW / 2 + keeperPosition * gW * 0.36;

    // Proporções relativas à altura do gol
    final figH = gH * 0.82;
    final headR = figH * 0.10;
    final torsoH = figH * 0.27;
    final torsoW = figH * 0.21;
    final armLen = figH * 0.25;
    final armThick = figH * 0.072;
    final legH = figH * 0.33;
    final legW = figH * 0.085;
    final gloveR = armThick * 0.90;
    final shoeH = legW * 0.75;

    // Posições Y (pé fica no fundo do gol)
    final feetY = gB - gH * 0.04;
    final legTopY = feetY - legH;
    final torsoTopY = legTopY - torsoH;
    final headCY = torsoTopY - headR * 1.15;

    // Ângulo de inclinação ao pular
    final jumpAngle = keeperJumping && keeperPosition.abs() > 0.12
        ? (keeperPosition < 0 ? -0.40 : 0.40)
        : 0.0;

    canvas.save();
    if (jumpAngle != 0.0) {
      // Pivô no quadril para animação de mergulho
      final pivotY = legTopY + torsoH * 0.2;
      canvas.translate(cx, pivotY);
      canvas.rotate(jumpAngle);
      canvas.translate(-cx, -pivotY);
    }

    // ── Sombra do goleiro no chão ─────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, feetY + 2), width: legW * 3.5, height: legW * 1.0),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // ── Pernas ────────────────────────────────────────────────────────────
    final legPaint = Paint()..color = const Color(0xFF001A5E);

    // Perna esquerda
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - legW * 1.35, legTopY, legW, legH),
          Radius.circular(legW / 2)),
      legPaint,
    );
    // Perna direita
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + legW * 0.35, legTopY, legW, legH),
          Radius.circular(legW / 2)),
      legPaint,
    );

    // ── Chuteiras ─────────────────────────────────────────────────────────
    final shoePaint = Paint()..color = const Color(0xFF111111);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - legW * 1.75, feetY - shoeH, legW * 1.7, shoeH),
          const Radius.circular(3)),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + legW * 0.05, feetY - shoeH, legW * 1.7, shoeH),
          const Radius.circular(3)),
      shoePaint,
    );

    // ── Camiseta (torso) ──────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - torsoW / 2, torsoTopY, torsoW, torsoH),
          const Radius.circular(7)),
      Paint()..color = const Color(0xFF009C3B),
    );

    // Faixa vertical amarela
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - torsoW * 0.12, torsoTopY + torsoH * 0.12,
              torsoW * 0.24, torsoH * 0.76),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFDF00).withOpacity(0.45),
    );

    // Número "1"
    final numTp = TextPainter(
      text: TextSpan(
        text: '1',
        style: TextStyle(
          color: const Color(0xFFFFDF00),
          fontSize: torsoH * 0.40,
          fontWeight: FontWeight.w900,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    numTp.paint(
        canvas, Offset(cx - numTp.width / 2, torsoTopY + torsoH * 0.28));

    // ── Braços ────────────────────────────────────────────────────────────
    final armPaint = Paint()..color = const Color(0xFF009C3B);
    final glovePaint = Paint()..color = const Color(0xFFFFDF00);
    final armY = torsoTopY + torsoH * 0.10;

    if (keeperJumping && keeperPosition.abs() > 0.12) {
      final dir = keeperPosition < 0 ? -1.0 : 1.0;

      // Braço estendido (lado do mergulho)
      final extStart = dir < 0 ? cx - torsoW / 2 : cx + torsoW / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                dir < 0 ? extStart - armLen * 1.4 : extStart,
                armY - armThick * 0.2,
                armLen * 1.4,
                armThick),
            Radius.circular(armThick / 2)),
        armPaint,
      );
      canvas.drawCircle(
        Offset(
            dir < 0 ? extStart - armLen * 1.4 : extStart + armLen * 1.4,
            armY + armThick * 0.3),
        gloveR * 1.15,
        glovePaint,
      );

      // Braço traseiro (mais curto)
      final trailStart = dir < 0 ? cx + torsoW / 2 : cx - torsoW / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(
                dir < 0 ? trailStart : trailStart - armLen * 0.45,
                armY + armThick * 1.8,
                armLen * 0.45,
                armThick * 0.70),
            Radius.circular(armThick / 2)),
        armPaint,
      );
      canvas.drawCircle(
        Offset(
            dir < 0 ? trailStart + armLen * 0.45 : trailStart - armLen * 0.45,
            armY + armThick * 2.15),
        gloveR * 0.75,
        glovePaint,
      );
    } else {
      // Idle: braços abertos prontos para defender
      for (final isLeft in [true, false]) {
        final startX =
            isLeft ? cx - torsoW / 2 - armLen : cx + torsoW / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(startX, armY, armLen, armThick),
              Radius.circular(armThick / 2)),
          armPaint,
        );
        canvas.drawCircle(
          Offset(isLeft ? startX : startX + armLen, armY + armThick / 2),
          gloveR,
          glovePaint,
        );
      }
    }

    // ── Cabeça ────────────────────────────────────────────────────────────
    // Gola
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - torsoW * 0.22, torsoTopY - headR * 0.5,
              torsoW * 0.44, headR * 0.7),
          const Radius.circular(4)),
      Paint()..color = const Color(0xFF009C3B),
    );

    // Cabeça (pele)
    canvas.drawCircle(
      Offset(cx, headCY),
      headR,
      Paint()..color = const Color(0xFFFFBB85),
    );

    // Boné do goleiro (amarelo)
    final capRect = Rect.fromCircle(
        center: Offset(cx, headCY), radius: headR * 1.04);
    canvas.drawArc(
      capRect,
      -pi,
      pi,
      false,
      Paint()
        ..color = const Color(0xFFFFDF00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = headR * 0.48
        ..strokeCap = StrokeCap.butt,
    );

    // Aba do boné
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - headR * 1.1, headCY - headR * 0.08,
              headR * 2.2, headR * 0.28),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFFFFDF00),
    );

    // Olhos
    final eyeY = headCY + headR * 0.08;
    canvas.drawCircle(Offset(cx - headR * 0.30, eyeY), headR * 0.11,
        Paint()..color = Colors.black87);
    canvas.drawCircle(Offset(cx + headR * 0.30, eyeY), headR * 0.11,
        Paint()..color = Colors.black87);

    // Boca (sorriso)
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(cx, headCY + headR * 0.30),
          width: headR * 0.60,
          height: headR * 0.30),
      0,
      pi,
      false,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.restore();
  }

  // ── Traves e travessão com glow ──────────────────────────────────────────

  void _drawPostsAndFrame(
      Canvas canvas, double gL, double gT, double gR, double gB) {
    // Glow
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.17)
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(gL, gT), Offset(gL, gB), glowPaint);
    canvas.drawLine(Offset(gR, gT), Offset(gR, gB), glowPaint);
    canvas.drawLine(Offset(gL, gT), Offset(gR, gT), glowPaint);

    // Traves sólidas
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = _kPostWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(gL, gT - 1), Offset(gL, gB + 1), postPaint);
    canvas.drawLine(Offset(gR, gT - 1), Offset(gR, gB + 1), postPaint);
    canvas.drawLine(Offset(gL, gT), Offset(gR, gT), postPaint);

    // Linha do chão
    canvas.drawLine(
      Offset(gL, gB),
      Offset(gR, gB),
      Paint()
        ..color = Colors.white.withOpacity(0.50)
        ..strokeWidth = 2.5,
    );
  }

  // ── Campo abaixo do gol ───────────────────────────────────────────────────

  void _drawFieldBelow(
      Canvas canvas, double gL, double gR, double gB, double h) {
    final mid = (gL + gR) / 2;

    // Linha de fundo da área
    final areaW = (gR - gL) * 0.78;
    canvas.drawLine(
      Offset(mid - areaW / 2, gB + (h - gB) * 0.30),
      Offset(mid + areaW / 2, gB + (h - gB) * 0.30),
      Paint()
        ..color = Colors.white.withOpacity(0.30)
        ..strokeWidth = 1.5,
    );

    // Linhas laterais da área
    for (final x in [mid - areaW / 2, mid + areaW / 2]) {
      canvas.drawLine(
        Offset(x, gB),
        Offset(x, gB + (h - gB) * 0.30),
        Paint()
          ..color = Colors.white.withOpacity(0.30)
          ..strokeWidth = 1.5,
      );
    }

    // Ponto de pênalti
    canvas.drawCircle(
      Offset(mid, gB + (h - gB) * 0.58),
      4.5,
      Paint()..color = Colors.white.withOpacity(0.65),
    );

    // Semicírculo da área
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(mid, gB + (h - gB) * 0.58),
          width: areaW * 0.65,
          height: areaW * 0.35),
      -pi,
      pi,
      false,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(GoalPainter old) =>
      old.highlightedZone != highlightedZone ||
      old.showZones != showZones ||
      old.showKeeper != showKeeper ||
      (old.pulseValue - pulseValue).abs() > 0.004 ||
      (old.keeperPosition - keeperPosition).abs() > 0.004 ||
      old.keeperJumping != keeperJumping;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

int getZoneFromOffset(Offset local, Size size) {
  final gL = _kPostWidth * 0.5;
  final gR = size.width - _kPostWidth * 0.5;
  final gT = size.height * _kGoalTopRatio;
  final gB = size.height * _kGoalBottomRatio;

  final col = ((local.dx - gL) / ((gR - gL) / 3)).clamp(0, 2).toInt();
  final row = ((local.dy - gT) / ((gB - gT) / 3)).clamp(0, 2).toInt();
  return row * 3 + col;
}

double defenseChance(int zone) {
  if (const {0, 2, 6, 8}.contains(zone)) return 0.35;
  if (zone == 4) return 0.55;
  return 0.45;
}
