import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/goal_painter.dart';
import '../services/api_service.dart';
import 'result_screen.dart';
import 'scoreboard_screen.dart';
import 'quiz_screen.dart';

class GameScreen extends StatefulWidget {
  final String sala;
  final String salaName;

  const GameScreen({
    super.key,
    required this.sala,
    required this.salaName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  static const _maxShots = 3;

  int _shotsLeft = _maxShots;
  bool _shotInProgress = false;
  int? _highlightedZone;

  late AnimationController _keeperMoveCtrl;
  Animation<double> _keeperPosAnim = const AlwaysStoppedAnimation(0.0);
  bool _keeperJumping = false;

  late ConfettiController _confetti;

  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
    _keeperMoveCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _pulseCtrl = AnimationController(
            vsync: this, duration: const Duration(milliseconds: 1400))
          ..repeat(reverse: true);
    _loadShots();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _shakeCtrl.dispose();
    _keeperMoveCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadShots() async {
    final prefs = await SharedPreferences.getInstance();
    final shots = prefs.getInt('hexa_shots') ?? 3;
    if (mounted) setState(() => _shotsLeft = shots.clamp(0, 99));
  }

  Future<void> _onZoneTapped(int zone) async {
    if (_shotInProgress || _shotsLeft <= 0) return;

    final targetPos = Random().nextDouble() * 2 - 1;
    _keeperMoveCtrl.reset();
    _keeperPosAnim = Tween<double>(begin: 0.0, end: targetPos).animate(
      CurvedAnimation(parent: _keeperMoveCtrl, curve: Curves.easeOutBack),
    );
    _keeperMoveCtrl.forward();

    setState(() {
      _shotInProgress = true;
      _highlightedZone = zone;
      _keeperJumping = true;
    });

    await Future.delayed(const Duration(milliseconds: 650));

    final scored = Random().nextDouble() > defenseChance(zone);

    ApiService.registerShot(sala: widget.sala, scored: scored).catchError((_) {});

    // Decrementa chutes persistidos
    final prefs = await SharedPreferences.getInstance();
    final newShots = ((prefs.getInt('hexa_shots') ?? 3) - 1).clamp(0, 99);
    await prefs.setInt('hexa_shots', newShots);
    if (mounted) setState(() => _shotsLeft = newShots);

    if (scored) {
      _confetti.play();
    } else {
      _shakeCtrl.forward(from: 0);
    }

    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          scored: scored,
          sala: widget.sala,
          salaName: widget.salaName,
          shotsLeft: newShots,
        ),
      ),
    );

    if (!mounted) return;

    _keeperMoveCtrl.reset();
    _keeperPosAnim = const AlwaysStoppedAnimation(0.0);
    setState(() {
      _shotInProgress = false;
      _keeperJumping = false;
      _highlightedZone = null;
    });

    // Recarrega (quiz pode ter renovado chutes na ResultScreen)
    _loadShots();
  }

  Future<void> _openQuiz() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
    if (ok == true && mounted) _loadShots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: Stack(
        children: [
          _body(),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.30,
              numberOfParticles: 22,
              gravity: 0.2,
              colors: const [
                Color(0xFF009C3B), Color(0xFFFFDF00),
                Color(0xFF002776), Colors.white,
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'game_fab',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScoreboardScreen())),
              label: const Text('Ver Placar'),
              icon: const Icon(Icons.emoji_events),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _appBar() => AppBar(
        title: const Text('🇧🇷  Hexa Challenge'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Chip(
              backgroundColor: const Color(0xFF009C3B),
              side: BorderSide.none,
              label: Text(
                widget.salaName,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
        ],
      );

  Widget _body() => Column(
        children: [
          const SizedBox(height: 14),
          _shotCounter(),
          const SizedBox(height: 10),
          Expanded(child: _shotsLeft > 0 ? _gameArea() : _noShotsLeft()),
        ],
      );

  Widget _shotCounter() => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_maxShots, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Icons.sports_soccer,
                size: 30,
                color: _shotsLeft > i
                    ? const Color(0xFFFFDF00)
                    : Colors.white24,
              ),
            )),
          ),
          const SizedBox(height: 3),
          Text(
            _shotsLeft > 0
                ? '$_shotsLeft chute${_shotsLeft > 1 ? 's' : ''} restante${_shotsLeft > 1 ? 's' : ''}'
                : 'Sem chutes — faça o quiz para renovar',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      );

  Widget _gameArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final size = Size(
                  constraints.maxWidth, constraints.maxWidth * 0.68);
              return SizedBox(
                width: size.width,
                height: size.height,
                child: AnimatedBuilder(
                  animation: Listenable.merge(
                      [_shakeAnim, _pulseCtrl, _keeperMoveCtrl]),
                  builder: (_, __) {
                    final dx = _shakeCtrl.isAnimating
                        ? sin(_shakeAnim.value * pi * 10) * 9
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: GestureDetector(
                        onTapUp: _shotInProgress
                            ? null
                            : (d) => _onZoneTapped(
                                getZoneFromOffset(d.localPosition, size)),
                        child: CustomPaint(
                          painter: GoalPainter(
                            highlightedZone: _highlightedZone,
                            showZones: !_keeperJumping,
                            pulseValue: _pulseCtrl.value,
                            keeperPosition: _keeperPosAnim.value,
                            keeperJumping: _keeperJumping,
                          ),
                          size: size,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        if (!_shotInProgress)
          Text(
            'Toque no gol para chutar! ⚽',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
          ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _noShotsLeft() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧠', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Seus chutes acabaram!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acerte 3 de 5 perguntas\ne ganhe +3 chutes',
              style: TextStyle(color: Colors.white54, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _openQuiz,
              icon: const Icon(Icons.quiz),
              label: const Text('Fazer Quiz → +3 chutes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFDF00),
                foregroundColor: const Color(0xFF001040),
                minimumSize: const Size(double.infinity, 48),
                textStyle: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScoreboardScreen())),
              icon: const Icon(Icons.emoji_events),
              label: const Text('Ver Placar Geral'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
