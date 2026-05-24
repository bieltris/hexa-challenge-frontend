import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/goal_painter.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Arrow Game – pendulo com alvo aleatório dentro do gol
//
// Mecânica:
//  • Seta oscila como pêndulo da bola (não alcança o gol visualmente)
//  • Alvo: círculo vermelho em posição aleatória dentro do gol
//  • Sem feedback visual de alinhamento — acerto é por olho
//  • Fases: +2 → +6 → +10 → +14 → +18 (total ao sacar)
//  • Velocidade +30% por fase; errar na fase 1 → -2 da sala
// ─────────────────────────────────────────────────────────────────────────────

class ArrowGameScreen extends StatefulWidget {
  final String sala;
  final String salaName;
  final String playerName;

  const ArrowGameScreen({
    super.key,
    required this.sala,
    required this.salaName,
    this.playerName = '',
  });

  @override
  State<ArrowGameScreen> createState() => _ArrowGameScreenState();
}

enum _St { playing, choice, miss, cashout }

// ── Geometria calculada em build() e reutilizada nos handlers ────────────────
class _Geo {
  final Offset ballCenter;
  final Offset targetScreen; // posição do alvo na tela (px)
  final double arrowLen;
  final double targetAngleDeg; // ângulo da bola ao alvo (graus)
  final double toleranceDeg;   // metade da zona de acerto (graus)
  final double maxAngleDeg;    // amplitude máxima do pêndulo
  final double goalPainterH;
  final double topOffset;      // deslocamento vertical do gol na tela
  final double targetRadius;   // raio do alvo nesta fase

  const _Geo({
    required this.ballCenter,
    required this.targetScreen,
    required this.arrowLen,
    required this.targetAngleDeg,
    required this.toleranceDeg,
    required this.maxAngleDeg,
    required this.goalPainterH,
    required this.topOffset,
    required this.targetRadius,
  });
}

class _ArrowGameScreenState extends State<ArrowGameScreen>
    with SingleTickerProviderStateMixin {

  // ── Constantes de fase ──────────────────────────────────────────────────
  static const _pts = [2, 6, 10, 14, 18];
  static const _baseSweepMs = 1100; // ms por lado na fase 1

  // ── Constantes de layout (espelham goal_painter.dart) ──────────────────
  // GoalPainter widget: altura = screenWidth * _goalHRatio
  static const _goalHRatio  = 0.52;
  static const _kGoalTopR   = 0.04;  // GoalPainter internal
  static const _kGoalBotR   = 0.58;
  static const _kPostHalf   = 5.5;
  static const _targetRadiusBase = 18.975; // 17.25 * 1.10 (+10%)
  // Raio efetivo: encolhe 3% por fase (fase 1 = base, fase 5 = base * 0.97^4)
  double get _currentRadius => _targetRadiusBase * pow(0.97, _phase - 1); // raio do círculo vermelho (px)
  // Seta ocupa apenas 42% da distância bola→centro-do-gol
  static const _arrowFactor = 0.68;

  // ── State ───────────────────────────────────────────────────────────────
  late AnimationController _ctrl;
  int _phase = 1;
  _St _st = _St.playing;

  // Alvo: frações dentro do interior do gol [0,1]
  double _tFracX = 0.5;
  double _tFracY = 0.5;
  final _rand = Random();

  // ── Derivados ────────────────────────────────────────────────────────────
  int get _thisPts    => _pts[_phase - 1];
  int get _nextPts    => _phase < 5 ? _pts[_phase] : 0;
  int get _sweepMs    => (_baseSweepMs / pow(1.3, _phase - 1)).round();
  // pontos acumulados ANTES da fase atual (o que o jogador já ganhou)
  int get _accumulated => _phase > 1 ? _pts[_phase - 2] : 0;
  // penalidade = metade do acumulado (arredondado p/ baixo); 0 na fase 1
  int get _penaltyPts  => _accumulated ~/ 2;

  double _angleAt(double v, double max) => (v * 2 - 1) * max;

  // ── Ciclo de vida ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _sweepMs),
    )
      ..addListener(() => setState(() {}))
      ..repeat(reverse: true);
    _randomizeTarget();
  }

  void _randomizeTarget() {
    // Mantém alvo com margem para não colar nas traves
    setState(() {
      _tFracX = 0.08 + _rand.nextDouble() * 0.84;
      _tFracY = 0.08 + _rand.nextDouble() * 0.84;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Geometria ─────────────────────────────────────────────────────────────
  _Geo _geo(Size size, double targetRadius) {
    final topOffset = size.height * 0.20; // gol desce 20% da tela

    final goalH  = size.width * _goalHRatio;
    final gT     = goalH * _kGoalTopR;
    final gB     = goalH * _kGoalBotR;
    final gL     = _kPostHalf;
    final gR     = size.width - _kPostHalf;
    final gW     = gR - gL;
    final gH     = gB - gT;

    // Centro do gol em coordenadas de TELA (inclui topOffset)
    final goalCY = topOffset + (gT + gB) / 2;

    final ballY  = size.height * 0.82;
    final cx     = size.width / 2;

    // Alvo em coordenadas de TELA (inclui topOffset)
    final tX = gL + _tFracX * gW;
    final tY = topOffset + gT + _tFracY * gH;

    // Seta: não alcança o gol
    final fullDist = ballY - goalCY;
    final arrowLen = fullDist * _arrowFactor;

    // Ângulo exato da bola ao alvo
    final dx    = tX - cx;
    final dy    = ballY - tY;
    final dist  = sqrt(dx * dx + dy * dy);
    final tAngle = atan2(dx, dy) * 180 / pi;
    final tol    = atan(targetRadius / dist) * 180 / pi;

    // Amplitude máxima do pêndulo (chega às traves + 20% overshoot)
    final maxA = atan((gW / 2 * 1.20) / fullDist) * 180 / pi;

    return _Geo(
      ballCenter:    Offset(cx, ballY),
      targetScreen:  Offset(tX, tY),
      arrowLen:      arrowLen,
      targetAngleDeg: tAngle,
      toleranceDeg:  tol,
      maxAngleDeg:   maxA,
      goalPainterH:  goalH,
      topOffset:     topOffset,
      targetRadius:  targetRadius,
    );
  }

  // ── Tap ──────────────────────────────────────────────────────────────────
  void _onTap(_Geo geo) {
    if (_st != _St.playing) return;
    _ctrl.stop();
    final angle = _angleAt(_ctrl.value, geo.maxAngleDeg);

    if ((angle - geo.targetAngleDeg).abs() <= geo.toleranceDeg) {
      // Acertou!
      if (_phase == 5) {
        _award();
      } else {
        setState(() => _st = _St.choice);
      }
    } else {
      // Errou — desconta metade do acumulado da sala (0 na fase 1)
      if (_penaltyPts > 0) {
        ApiService.applyPenalty(
          sala: widget.sala,
          points: _penaltyPts,
          playerName: widget.playerName.isNotEmpty ? widget.playerName : null,
        ).catchError((_) {});
      }
      setState(() => _st = _St.miss);
    }
  }

  void _restartGame() {
    setState(() {
      _phase = 1;
      _st = _St.playing;
    });
    _randomizeTarget();
    _ctrl.duration = Duration(milliseconds: _sweepMs);
    _ctrl.repeat(reverse: true);
  }

  void _award() {
    ApiService.awardPoints(
      sala: widget.sala,
      points: _thisPts,
      playerName: widget.playerName.isNotEmpty ? widget.playerName : null,
    ).catchError((_) {});
    setState(() => _st = _St.cashout);
  }

  void _continueGame() {
    setState(() {
      _phase++;
      _st = _St.playing;
    });
    _randomizeTarget();
    _ctrl.duration = Duration(milliseconds: _sweepMs);
    _ctrl.repeat(reverse: true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final geo  = _geo(size, _currentRadius);
    final currentAngle = _angleAt(_ctrl.value, geo.maxAngleDeg);

    return Scaffold(
      backgroundColor: const Color(0xFF000A1E),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _st == _St.playing ? () => _onTap(geo) : null,
        child: Stack(
          children: [
            // ── GoalPainter (sem goleiro, sem zonas) ─────────────────────
            Positioned(
              top: geo.topOffset,
              left: 0,
              right: 0,
              height: geo.goalPainterH,
              child: CustomPaint(
                painter: GoalPainter(
                  showZones:  false,
                  showKeeper: false,
                  pulseValue: 0.5,
                ),
              ),
            ),

            // ── Alvo + seta + bola ───────────────────────────────────────
            CustomPaint(
              size: size,
              painter: _ArrowPainter(
                angleDeg:     currentAngle,
                ballCenter:   geo.ballCenter,
                arrowLen:     geo.arrowLen,
                targetCenter: geo.targetScreen,
                targetRadius: geo.targetRadius,
                state:        _st,
              ),
            ),

            // ── UI ────────────────────────────────────────────────────────
            SafeArea(child: _buildUI()),
          ],
        ),
      ),
    );
  }

  // ── UI widgets ────────────────────────────────────────────────────────────
  Widget _buildUI() {
    return Column(
      children: [
        _buildTopBar(),
        const Spacer(),
        Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.70),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: _buildBottom(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white54, size: 22),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final done    = i < _phase - 1;
                final current = i == _phase - 1;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: current ? 40 : 30,
                  height: 28,
                  decoration: BoxDecoration(
                    color: done
                        ? const Color(0xFF009C3B)
                        : current
                            ? const Color(0xFFFFDF00)
                            : Colors.white10,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: current
                        ? [BoxShadow(
                            color: const Color(0xFFFFDF00).withOpacity(0.45),
                            blurRadius: 10,
                          )]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '+${_pts[i]}',
                      style: GoogleFonts.poppins(
                        color: done
                            ? Colors.white
                            : current
                                ? Colors.black
                                : Colors.white24,
                        fontSize: current ? 11 : 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(
            'Fase $_phase/5',
            style: GoogleFonts.poppins(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    switch (_st) {
      case _St.playing:
        return Column(
          children: [
            Text(
              'TAP!',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFFDF00),
                fontSize: 38,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                shadows: [Shadow(
                  color: const Color(0xFFFFDF00).withOpacity(0.55),
                  blurRadius: 20,
                )],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Acerte o alvo vermelho com a seta',
              style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12),
            ),
          ],
        );

      case _St.choice:
        return Column(
            children: [
              Text(
                '⚽ GOOOOL!',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF00D45B),
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(
                    color: const Color(0xFF009C3B).withOpacity(0.6),
                    blurRadius: 16,
                  )],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Fase $_phase concluída!',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.35)),
                ),
                child: Text(
                  'Se errar na próxima fase, perde TUDO!',
                  style: GoogleFonts.poppins(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _btn(
                    label: 'Sacar',
                    sub: '$_thisPts pts garantidos',
                    color: const Color(0xFFFFDF00),
                    textColor: Colors.black,
                    onTap: _award,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _btn(
                    label: 'Continuar',
                    sub: 'Arriscar por $_nextPts pts',
                    color: const Color(0xFF009C3B),
                    textColor: Colors.white,
                    onTap: _continueGame,
                  )),
                ],
              ),
            ],
        );

      case _St.cashout:
        return Column(
            children: [
              Text(
                '🎉 +$_thisPts pontos!',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFDF00),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Somados ao ${widget.salaName}!',
                style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Sair',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009C3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Jogar de novo',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
        );

      case _St.miss:
        final penMsg = _penaltyPts > 0
            ? 'A sala perdeu $_penaltyPts pts de penalidade'
            : _accumulated > 0
                ? '$_accumulated pts acumulados foram perdidos'
                : 'Sem penalidade — boa sorte da próxima!';
        return Column(
            children: [
              Text(
                '❌ ${_accumulated > 0 ? "Perdeu tudo!" : "Errou!"}',
                style: GoogleFonts.poppins(
                  color: Colors.redAccent,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                penMsg,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Sair',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _restartGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009C3B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Jogar de novo',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ],
        );
    }
  }

  Widget _btn({
    required String label,
    required String sub,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800, fontSize: 15)),
          Text(sub,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: textColor.withOpacity(0.65))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter: alvo vermelho + seta + bola
// Sem feedback visual de alinhamento na seta
// ─────────────────────────────────────────────────────────────────────────────

class _ArrowPainter extends CustomPainter {
  final double angleDeg;
  final Offset ballCenter;
  final double arrowLen;
  final Offset targetCenter;
  final double targetRadius;
  final _St state;

  const _ArrowPainter({
    required this.angleDeg,
    required this.ballCenter,
    required this.arrowLen,
    required this.targetCenter,
    required this.targetRadius,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final angleRad = angleDeg * pi / 180;
    final isHit  = state == _St.choice || state == _St.cashout;
    final isMiss = state == _St.miss;

    // 1. Alvo vermelho (sempre visível, sem feedback de alinhamento)
    _paintTarget(canvas, isHit, isMiss);

    // 2. Seta (cor fixa — sem mudança ao alinhar)
    _paintArrow(canvas, angleRad, isMiss, isHit);

    // 3. Bola
    _paintBall(canvas, isHit, isMiss);
  }

  // ── Alvo vermelho ─────────────────────────────────────────────────────────
  void _paintTarget(Canvas canvas, bool isHit, bool isMiss) {
    final Color fill = isMiss
        ? Colors.red.shade900
        : isHit
            ? const Color(0xFF009C3B)
            : Colors.red;
    final Color border = isMiss
        ? Colors.red.shade700
        : isHit
            ? const Color(0xFF00D45B)
            : Colors.red.shade200;

    // Glow atrás
    canvas.drawCircle(
      targetCenter,
      targetRadius * 1.8,
      Paint()
        ..color = fill.withOpacity(0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Círculo preenchido
    canvas.drawCircle(targetCenter, targetRadius, Paint()..color = fill);

    // Anel externo
    canvas.drawCircle(
      targetCenter,
      targetRadius,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Ponto branco central (mira)
    canvas.drawCircle(
      targetCenter,
      targetRadius * 0.28,
      Paint()..color = Colors.white.withOpacity(0.85),
    );
  }

  // ── Seta (cor fixa, sem feedback) ─────────────────────────────────────────
  void _paintArrow(Canvas canvas, double angleRad, bool isMiss, bool isHit) {
    // Cor: branca sempre durante o jogo, muda só no resultado
    final Color color = isMiss
        ? Colors.redAccent
        : isHit
            ? const Color(0xFF00D45B)
            : Colors.white;

    final dx = sin(angleRad);
    final dy = -cos(angleRad);
    final tip = Offset(
      ballCenter.dx + dx * arrowLen,
      ballCenter.dy + dy * arrowLen,
    );

    // Glow suave
    canvas.drawLine(
      ballCenter,
      tip,
      Paint()
        ..color = color.withOpacity(0.15)
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Haste
    canvas.drawLine(
      ballCenter,
      tip,
      Paint()
        ..color = color
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Ponta (triângulo)
    const headLen = 18.0;
    const halfW   = 8.0;
    final px = -dy;
    final py =  dx;
    final base = Offset(tip.dx - dx * headLen, tip.dy - dy * headLen);
    final w1   = Offset(base.dx + px * halfW, base.dy + py * halfW);
    final w2   = Offset(base.dx - px * halfW, base.dy - py * halfW);

    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(w1.dx, w1.dy)
        ..lineTo(w2.dx, w2.dy)
        ..close(),
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  // ── Bola ⚽ ───────────────────────────────────────────────────────────────
  void _paintBall(Canvas canvas, bool isHit, bool isMiss) {
    final glowColor = isMiss
        ? Colors.redAccent
        : isHit
            ? const Color(0xFF009C3B)
            : Colors.white;

    canvas.drawCircle(
      ballCenter,
      44,
      Paint()
        ..color = glowColor.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    final tp = TextPainter(
      text: const TextSpan(text: '⚽', style: TextStyle(fontSize: 62)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ballCenter - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_ArrowPainter old) =>
      old.angleDeg != angleDeg ||
      old.state != state ||
      old.targetCenter != targetCenter;
}
