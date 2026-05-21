import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'scoreboard_screen.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final bool scored;
  final String sala;
  final String salaName;
  final int shotsLeft;

  const ResultScreen({
    super.key,
    required this.scored,
    required this.sala,
    required this.salaName,
    required this.shotsLeft,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late ConfettiController _confetti;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Pode ser atualizado se o quiz renovar os chutes
  late int _shotsLeft;

  @override
  void initState() {
    super.initState();
    _shotsLeft = widget.shotsLeft;
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    if (widget.scored) {
      _confetti.play();
    } else {
      _shakeCtrl.forward();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _openQuiz() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
    if (ok == true && mounted) {
      // Recarrega chutes após quiz bem-sucedido
      final prefs = await SharedPreferences.getInstance();
      final shots = prefs.getInt('hexa_shots') ?? 3;
      setState(() => _shotsLeft = shots.clamp(0, 99));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.scored
                    ? [const Color(0xFF004D1A), const Color(0xFF001A5E)]
                    : [const Color(0xFF5C0000), const Color(0xFF1A0000)],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildCenterIcon(),
                    const SizedBox(height: 20),

                    // Título
                    Text(
                      widget.scored ? 'GOL!' : 'Defendeu!',
                      style: GoogleFonts.poppins(
                        fontSize: widget.scored ? 64 : 48,
                        fontWeight: FontWeight.w900,
                        color: widget.scored
                            ? const Color(0xFFFFDF00)
                            : Colors.white,
                      ),
                    ).animate().fadeIn(duration: 400.ms).scale(
                          begin: const Offset(0.6, 0.6),
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),

                    const SizedBox(height: 8),

                    Text(
                      widget.scored
                          ? '+1 ponto para ${widget.salaName}! 🎉'
                          : 'O goleiro voou na bola!',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 15),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // Contador de chutes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.sports_soccer,
                          size: 28,
                          color: _shotsLeft > i
                              ? const Color(0xFFFFDF00)
                              : Colors.white24,
                        ),
                      )),
                    ).animate().fadeIn(delay: 500.ms),

                    const SizedBox(height: 8),

                    Text(
                      _shotsLeft > 0
                          ? '$_shotsLeft chute${_shotsLeft > 1 ? 's' : ''} restante${_shotsLeft > 1 ? 's' : ''}'
                          : 'Seus chutes acabaram!',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 32),

                    _buildButtons(context),
                  ],
                ),
              ),
            ),
          ),

          if (widget.scored)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.25,
                numberOfParticles: 28,
                gravity: 0.2,
                colors: const [
                  Color(0xFF009C3B), Color(0xFFFFDF00),
                  Color(0xFF002776), Colors.white,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCenterIcon() {
    if (widget.scored) {
      return const Text('⚽', style: TextStyle(fontSize: 80))
          .animate()
          .scale(
            begin: const Offset(0, 0),
            duration: 600.ms,
            curve: Curves.elasticOut,
          );
    }
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final dx = _shakeCtrl.isAnimating
            ? sin(_shakeAnim.value * pi * 10) * 14
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: const Text('🧤', style: TextStyle(fontSize: 80)),
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        if (_shotsLeft > 0)
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.sports_soccer),
            label: const Text('Jogar Novamente'),
          ),

        // Quiz quando sem chutes
        if (_shotsLeft == 0)
          ElevatedButton.icon(
            onPressed: _openQuiz,
            icon: const Icon(Icons.quiz),
            label: const Text('Quiz → +3 chutes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFDF00),
              foregroundColor: const Color(0xFF001040),
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w800),
            ),
          ),

        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScoreboardScreen()),
            );
          },
          icon: const Icon(Icons.emoji_events),
          label: const Text('Ver Placar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFFFDF00),
            side: const BorderSide(color: Color(0xFFFFDF00)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.3);
  }
}
