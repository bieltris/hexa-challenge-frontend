import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rank.dart';
import '../services/api_service.dart';
import '../services/duel_socket_service.dart';
import '../widgets/goal_painter.dart';
import '../widgets/rank_badge.dart';

class DuelGameScreen extends StatefulWidget {
  final Map<String, dynamic> data; // duel_start payload
  final String name;
  final String sala;
  final String salaName;
  const DuelGameScreen({
    super.key,
    required this.data,
    required this.name,
    required this.sala,
    required this.salaName,
  });

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

enum _Phase { choosing, waiting, revealing, ended }

class _DuelGameScreenState extends State<DuelGameScreen>
    with TickerProviderStateMixin {
  final _svc = DuelSocketService.instance;
  final List<StreamSubscription> _subs = [];

  late String _duelId;
  late String _oppName;
  late String _oppSala;
  PlayerMe? _oppMe;
  late bool _sameSala;
  late Map<String, dynamic> _consecutive;

  String _kickerSid = '';
  int _round = 1;
  _Phase _phase = _Phase.choosing;
  int _timer = 5;
  Timer? _countdown;

  String? _myChoice;
  String? _revealKicker;
  String? _revealKeeper;
  bool? _scored;
  String? _roundWinner;

  Map<String, dynamic>? _endData;
  bool _oppDisconnected = false;

  // animations
  late AnimationController _ballCtrl;
  late AnimationController _keeperCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _revealTextCtrl;

  double _ballTargetX = 0; // -1 left, 1 right
  double _keeperTargetX = 0;

  static const _roomNames = {
    '6ano': '6º Ano',
    '7ano': '7º Ano',
    '8ano': '8º Ano',
    '9ano': '9º Ano',
    '1medio': '1º Médio',
    '2medio': '2º Médio',
    '3medio': '3º Médio',
  };

  String get _mySocketId => _svc.mySocketId;
  bool get _amKicker => _kickerSid == _mySocketId;
  int get _myConsec => (_consecutive[_mySocketId] as num?)?.toInt() ?? 0;
  int get _oppConsec =>
      (_consecutive.entries
              .firstWhere((e) => e.key != _mySocketId,
                  orElse: () => const MapEntry('', 0))
              .value as num?)
          ?.toInt() ??
      0;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _duelId = d['duelId'] as String;
    _kickerSid = d['kickerSid'] as String;
    _round = (d['round'] as num?)?.toInt() ?? 1;
    _sameSala = d['sameSala'] as bool? ?? false;
    final opp = d['opponent'] as Map<String, dynamic>;
    _oppName = opp['name'] as String;
    _oppSala = opp['sala'] as String;
    _consecutive = {};
    _loadOpponentRank();

    _ballCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _keeperCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850))
      ..repeat(reverse: true);
    _revealTextCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));

    _subs.add(_svc.roundStart.listen(_onRoundStart));
    _subs.add(_svc.roundResult.listen(_onRoundResult));
    _subs.add(_svc.duelEnd.listen(_onDuelEnd));
    _subs.add(_svc.oppDisconnected
        .listen((_) => setState(() => _oppDisconnected = true)));
    _subs.add(_svc.oppReconnected
        .listen((_) => setState(() => _oppDisconnected = false)));
    _subs.add(_svc.choiceLocked.listen((c) => setState(() => _myChoice = c)));

    _startCountdown();
  }

  Future<void> _loadOpponentRank() async {
    try {
      final me = await ApiService.getMe(name: _oppName, sala: _oppSala);
      if (mounted) setState(() => _oppMe = me);
    } catch (_) {}
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _ballCtrl.dispose();
    _keeperCtrl.dispose();
    _pulseCtrl.dispose();
    _revealTextCtrl.dispose();
    for (var s in _subs) s.cancel();
    super.dispose();
  }

  void _onRoundStart(Map<String, dynamic> d) {
    if (d['duelId'] != _duelId) return;
    _countdown?.cancel();
    _ballCtrl.reset();
    _keeperCtrl.reset();
    _revealTextCtrl.reset();
    setState(() {
      _kickerSid = d['kickerSid'] as String;
      _round = (d['round'] as num).toInt();
      _phase = _Phase.choosing;
      _myChoice = null;
      _revealKicker = _revealKeeper = null;
      _scored = null;
      _roundWinner = null;
      _timer = 5;
      _consecutive = Map<String, dynamic>.from(d['consecutive'] as Map);
    });
    _startCountdown();
  }

  void _onRoundResult(Map<String, dynamic> d) {
    if (d['duelId'] != _duelId) return;
    _countdown?.cancel();
    setState(() {
      _phase = _Phase.revealing;
      _revealKicker = d['kickerChoice'] as String;
      _revealKeeper = d['keeperChoice'] as String;
      _scored = d['scored'] as bool;
      _roundWinner = d['winnerId'] as String;
      _consecutive = Map<String, dynamic>.from(d['consecutive'] as Map);
      _ballTargetX = (_revealKicker == 'L') ? -1.0 : 1.0;
      _keeperTargetX = (_revealKeeper == 'L') ? -1.0 : 1.0;
    });
    _keeperCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _ballCtrl.forward(from: 0).whenComplete(() {
        if (mounted) _revealTextCtrl.forward(from: 0);
      });
    });
  }

  void _onDuelEnd(Map<String, dynamic> d) {
    if (d['duelId'] != _duelId) return;
    _countdown?.cancel();
    setState(() {
      _phase = _Phase.ended;
      _endData = d;
    });
  }

  void _startCountdown() {
    _countdown?.cancel();
    _timer = 5;
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timer--);
      if (_timer <= 0) t.cancel();
    });
  }

  void _choose(String choice) {
    if (_phase != _Phase.choosing || _myChoice != null) return;
    _svc.sendChoice(_duelId, choice);
    setState(() {
      _myChoice = choice;
      _phase = _Phase.waiting;
    });
    _countdown?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.ended && _endData != null) return _buildEndScreen();

    return Scaffold(
      backgroundColor: const Color(0xFF001040),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: _buildStage()),
          _buildFooter(),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF001A4E),
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(children: [
        _PlayerChip(
            name: widget.name,
            sala: widget.salaName,
            isKicker: _amKicker,
            consec: _myConsec,
            isMe: true),
        Expanded(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Round $_round',
                style: GoogleFonts.poppins(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
            const Text('vs',
                style: TextStyle(color: Colors.white54, fontSize: 14)),
          ]),
        ),
        _PlayerChip(
            name: _oppName,
            sala: _roomNames[_oppSala] ?? _oppSala,
            rank: _oppMe?.rank,
            isKicker: !_amKicker,
            consec: _oppConsec,
            isMe: false),
      ]),
    );
  }

  Widget _buildStage() {
    return LayoutBuilder(builder: (ctx, c) {
      final w = c.maxWidth;
      final stageH = c.maxHeight;

      // Goal area
      final goalH = (w * 0.66).clamp(180.0, stageH * 0.60);
      const goalTopOffset = 32.0; // room for "Goleiro: NAME" badge

      // Ball home position
      final ballR = 22.0;
      final ballHomeY = stageH - 70;
      final ballLandingY = goalTopOffset + goalH * 0.25;

      // Keeper screen-y (approx torso position in painter)
      final keeperY = goalTopOffset + goalH * 0.40;

      // Identify keeper name for badge
      final keeperName = _amKicker ? _oppName : widget.name;

      return AnimatedBuilder(
        animation: Listenable.merge(
            [_ballCtrl, _keeperCtrl, _pulseCtrl, _revealTextCtrl]),
        builder: (_, __) {
          final keeperPos = _keeperCtrl.value * _keeperTargetX;
          final keeperJumping =
              _phase == _Phase.revealing && _keeperCtrl.value > 0.05;

          // Ball position during reveal
          final ballCx = w / 2 + _ballCtrl.value * _ballTargetX * (w * 0.34);
          final ballCy =
              ballHomeY - _ballCtrl.value * (ballHomeY - ballLandingY);

          // Ball spin during flight
          final ballRotation = _ballCtrl.value * 6.28 * _ballTargetX;

          return Stack(children: [
            // ─── Keeper name badge above goal ──────────────────────────────
            Positioned(
              top: 6,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFDF00).withOpacity(0.5),
                        width: 1.2),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('🧤 ', style: TextStyle(fontSize: 14)),
                    Text('Goleiro: $keeperName',
                        style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),

            // ─── Goal + Keeper ────────────────────────────────────────────
            Positioned(
              top: goalTopOffset,
              left: 0,
              right: 0,
              height: goalH,
              child: CustomPaint(
                painter: GoalPainter(
                  showZones: false,
                  showKeeper: true,
                  keeperPosition: keeperPos,
                  keeperJumping: keeperJumping,
                  pulseValue: _pulseCtrl.value,
                ),
              ),
            ),

            // ─── Arrows (cone) ────────────────────────────────────────────
            if (_phase == _Phase.choosing || _phase == _Phase.waiting)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ArrowsPainter(
                      fromKicker: _amKicker,
                      ballX: w / 2,
                      ballY: ballHomeY - ballR * 0.9,
                      keeperX: w / 2,
                      keeperY: keeperY,
                      goalTopOffset: goalTopOffset,
                      goalH: goalH,
                      pulse: _pulseCtrl.value,
                      myChoice: _myChoice,
                    ),
                  ),
                ),
              ),

            // ─── Ball ────────────────────────────────────────────────────
            Positioned(
              left: ballCx - ballR,
              top: ballCy - ballR,
              child: Transform.rotate(
                angle: ballRotation,
                child: _Ball(radius: ballR),
              ),
            ),

            // ─── Tap zones (split L/R) ───────────────────────────────────
            if (_phase == _Phase.choosing && _myChoice == null)
              Positioned.fill(
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _choose('L'),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => _choose('R'),
                    ),
                  ),
                ]),
              ),

            // ─── Reveal text ─────────────────────────────────────────────
            if (_phase == _Phase.revealing && _revealTextCtrl.value > 0)
              Positioned(
                top: goalTopOffset + goalH * 0.55,
                left: 0,
                right: 0,
                child: Center(
                  child: Opacity(
                    opacity: _revealTextCtrl.value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.75 + _revealTextCtrl.value * 0.35,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.78),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: _scored == true
                                  ? const Color(0xFFFFDF00)
                                  : const Color(0xFF00D45B),
                              width: 2.5),
                        ),
                        child: Text(
                          _scored == true ? 'GOL!' : 'DEFESA!',
                          style: GoogleFonts.poppins(
                            color: _scored == true
                                ? const Color(0xFFFFDF00)
                                : const Color(0xFF00D45B),
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]);
        },
      );
    });
  }

  Widget _buildFooter() {
    if (_oppDisconnected) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.5))),
        child: Text('Oponente desconectou — aguardando 5s...',
            style: GoogleFonts.poppins(color: Colors.orange, fontSize: 12)),
      );
    }
    if (_phase == _Phase.choosing) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        color: Colors.black26,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_amKicker ? 'VOCÊ CHUTA' : 'VOCÊ DEFENDE',
              style: GoogleFonts.poppins(
                  color: _amKicker
                      ? const Color(0xFFFFDF00)
                      : const Color(0xFF00D45B),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2)),
          const SizedBox(height: 2),
          Text('Toque em um lado',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text('$_timer',
              style: GoogleFonts.poppins(
                  color:
                      _timer <= 2 ? Colors.redAccent : const Color(0xFFFFDF00),
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1)),
        ]),
      );
    }
    if (_phase == _Phase.waiting) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        color: Colors.black26,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Aguardando oponente...',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 4),
          const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Color(0xFFFFDF00))),
        ]),
      );
    }
    if (_phase == _Phase.revealing && _roundWinner != null) {
      final iWon = _roundWinner == _mySocketId;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: Colors.black26,
        child: Text(iWon ? 'Voce ganhou este round!' : 'Voce perdeu o round',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: iWon ? const Color(0xFF00D45B) : Colors.redAccent,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
      );
    }
    return const SizedBox(height: 60);
  }

  Widget _buildEndScreen() {
    final d = _endData!;
    final iWon = d['winnerSid'] == _mySocketId;
    final reason = d['reason'] as String;
    final pts = (d['pts'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF000A1E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(iWon ? '🏆' : '💀', style: const TextStyle(fontSize: 72)),
              const SizedBox(height: 8),
              Text(iWon ? 'VENCEDOR' : 'DERROTA',
                  style: TextStyle(
                      fontSize: 36,
                      color: iWon ? const Color(0xFFFFDF00) : Colors.redAccent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2)),
              const SizedBox(height: 4),
              Text(iWon ? 'Voce venceu o duelo!' : 'Voce perdeu o duelo',
                  style: GoogleFonts.poppins(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
              if (reason == 'disconnect') ...[
                const SizedBox(height: 4),
                Text('(Oponente desconectou)',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 11)),
              ],
              if (pts > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: iWon
                        ? const Color(0xFF009C3B).withOpacity(0.2)
                        : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: iWon
                            ? const Color(0xFF009C3B).withOpacity(0.5)
                            : Colors.red.withOpacity(0.4)),
                  ),
                  child: Text(
                      iWon
                          ? '+$pts gols para ${widget.salaName}!'
                          : '-$pts gols para ${widget.salaName}!',
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Text('Duelo amistoso — sem pontos',
                    style: GoogleFonts.poppins(
                        color: Colors.white38, fontSize: 12)),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002776),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: Text('Voltar',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── PlayerChip ──────────────────────────────────────────────────────────────

class _PlayerChip extends StatelessWidget {
  final String name, sala;
  final Rank? rank;
  final bool isKicker, isMe;
  final int consec;
  const _PlayerChip(
      {required this.name,
      required this.sala,
      this.rank,
      required this.isKicker,
      required this.consec,
      required this.isMe});

  @override
  Widget build(BuildContext context) {
    final shownRank = rank;
    final roleIcon = isKicker ? '⚽' : '🧤';
    final roleColor =
        isKicker ? const Color(0xFFFFDF00) : const Color(0xFF00D45B);
    return Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            if (isMe) ...[
              Text(roleIcon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
            ],
            Text(name,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis),
            if (!isMe) ...[
              const SizedBox(width: 4),
              Text(roleIcon, style: const TextStyle(fontSize: 14)),
            ],
          ]),
          if (shownRank != null) ...[
            const SizedBox(height: 3),
            RankBadge(rank: shownRank, compact: true),
          ],
          Text(sala,
              style: const TextStyle(color: Colors.white38, fontSize: 10)),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(isKicker ? 'Chutador' : 'Goleiro',
                style: TextStyle(
                    color: roleColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            ...List.generate(
              2,
              (i) => Container(
                margin: const EdgeInsets.only(left: 2),
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < consec ? const Color(0xFFFFDF00) : Colors.white12,
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
              ),
            ),
          ]),
        ]);
  }
}

// ─── Ball ────────────────────────────────────────────────────────────────────

class _Ball extends StatelessWidget {
  final double radius;
  const _Ball({required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
        gradient: RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [Colors.white, Color(0xFFCFCFCF)],
        ),
      ),
      child: CustomPaint(painter: _BallPainter()),
    );
  }
}

class _BallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final p = Paint()..color = Colors.black87;

    // outline
    canvas.drawCircle(
        c,
        r - 0.5,
        Paint()
          ..color = Colors.black12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);

    // central pentagon
    _pentagon(canvas, c, r * 0.36, p);

    // 5 surrounding pentagons (smaller)
    for (int i = 0; i < 5; i++) {
      final ang = -pi / 2 + i * 2 * pi / 5;
      final off =
          Offset(c.dx + cos(ang) * r * 0.62, c.dy + sin(ang) * r * 0.62);
      _pentagon(canvas, off, r * 0.18, p);
    }
  }

  void _pentagon(Canvas c, Offset center, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final ang = -pi / 2 + i * 2 * pi / 5;
      final x = center.dx + cos(ang) * r;
      final y = center.dy + sin(ang) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_BallPainter old) => false;
}

// ─── Arrows (cone shape, thin→thick) ──────────────────────────────────────────

class _ArrowsPainter extends CustomPainter {
  final bool fromKicker;
  final double ballX, ballY, keeperX, keeperY;
  final double goalTopOffset, goalH;
  final double pulse;
  final String? myChoice;

  _ArrowsPainter({
    required this.fromKicker,
    required this.ballX,
    required this.ballY,
    required this.keeperX,
    required this.keeperY,
    required this.goalTopOffset,
    required this.goalH,
    required this.pulse,
    required this.myChoice,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Origin & targets depend on role
    final Offset origin;
    final Offset leftTip;
    final Offset rightTip;

    if (fromKicker) {
      // Kicker: arrows from ball pointing UP toward goal corners
      origin = Offset(ballX, ballY);
      // Target = upper portion of goal interior, near corners
      final goalInsetX = size.width * 0.12;
      final goalCornerY = goalTopOffset + goalH * 0.22;
      leftTip = Offset(goalInsetX, goalCornerY);
      rightTip = Offset(size.width - goalInsetX, goalCornerY);
    } else {
      // Keeper: arrows from keeper pointing horizontally to sides
      origin = Offset(keeperX, keeperY);
      final sideInset = size.width * 0.06;
      leftTip = Offset(sideInset, keeperY);
      rightTip = Offset(size.width - sideInset, keeperY);
    }

    _drawArrow(canvas, origin, leftTip, isChosen: myChoice == 'L');
    _drawArrow(canvas, origin, rightTip, isChosen: myChoice == 'R');
  }

  void _drawArrow(Canvas canvas, Offset origin, Offset tip,
      {required bool isChosen}) {
    final dim = myChoice != null && !isChosen;
    final pulseBoost = isChosen ? 1.0 : (1.0 + pulse * 0.12);

    final baseColor = isChosen
        ? const Color(0xFFFFDF00)
        : (dim
            ? Colors.white.withOpacity(0.12)
            : Colors.white.withOpacity(0.55 + pulse * 0.25));

    final dx = tip.dx - origin.dx;
    final dy = tip.dy - origin.dy;
    final len = sqrt(dx * dx + dy * dy);
    if (len < 1) return;
    final ux = dx / len, uy = dy / len;
    final px = -uy, py = ux; // perpendicular (CCW)

    // Cone widths (start thin, grow toward tip)
    final startW = 3.0 * pulseBoost;
    final shaftEndW = 16.0 * pulseBoost;
    final headW = 28.0 * pulseBoost;
    final headLen = 30.0;
    final shaftEnd = (len - headLen).clamp(2.0, double.infinity);

    final p1 = Offset(origin.dx + px * startW, origin.dy + py * startW);
    final p2 = Offset(origin.dx - px * startW, origin.dy - py * startW);
    final p3 = Offset(origin.dx + ux * shaftEnd - px * shaftEndW,
        origin.dy + uy * shaftEnd - py * shaftEndW);
    final p4 = Offset(origin.dx + ux * shaftEnd + px * shaftEndW,
        origin.dy + uy * shaftEnd + py * shaftEndW);

    // Arrowhead
    final h1 = Offset(origin.dx + ux * shaftEnd + px * headW,
        origin.dy + uy * shaftEnd + py * headW);
    final h2 = Offset(origin.dx + ux * shaftEnd - px * headW,
        origin.dy + uy * shaftEnd - py * headW);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p4.dx, p4.dy)
      ..lineTo(h1.dx, h1.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(h2.dx, h2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();

    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = baseColor.withOpacity(isChosen ? 0.55 : 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Body
    canvas.drawPath(path, Paint()..color = baseColor);
    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(isChosen ? 0.9 : 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(_ArrowsPainter old) =>
      old.pulse != pulse ||
      old.myChoice != myChoice ||
      old.fromKicker != fromKicker ||
      old.ballX != ballX ||
      old.ballY != ballY ||
      old.keeperY != keeperY;
}
