import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question_model.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  // ── Estado ────────────────────────────────────────────────────────────────
  List<QuestionModel> _questions = [];
  bool _loading = true;
  String? _error;

  int _current = 0;          // índice da pergunta atual
  String? _chosen;           // opção escolhida pelo usuário
  int _correct = 0;          // acertos

  bool _finished = false;    // mostrar resultado final
  bool _rewarded = false;    // ganhou chutes?

  late ConfettiController _confetti;

  // ── Init ──────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _loadQuestions();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() { _loading = true; _error = null; });
    try {
      final qs = await ApiService.getQuestions(count: 5);
      if (mounted) setState(() { _questions = qs; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Resposta ──────────────────────────────────────────────────────────────
  Future<void> _onAnswer(String letter) async {
    if (_chosen != null) return; // já respondeu
    final q = _questions[_current];
    final hit = q.isCorrect(letter);
    if (hit) _correct++;

    setState(() => _chosen = letter);

    // aguarda animação visual de feedback
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _chosen = null;
      });
    } else {
      await _showResult();
    }
  }

  Future<void> _showResult() async {
    final passed = _correct >= 3;
    if (passed) {
      final prefs = await SharedPreferences.getInstance();
      final cur = prefs.getInt('hexa_shots') ?? 0;
      await prefs.setInt('hexa_shots', cur + 3);
      _confetti.play();
    }
    if (mounted) setState(() { _finished = true; _rewarded = passed; });
  }

  void _retry() {
    setState(() {
      _current = 0;
      _chosen  = null;
      _correct = 0;
      _finished= false;
      _rewarded= false;
      _questions = [];
      _loading = true;
    });
    _loadQuestions();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _gradient(),
          SafeArea(
            child: _loading
                ? _buildLoading()
                : _error != null
                    ? _buildError()
                    : _finished
                        ? _buildResult()
                        : _buildQuestion(),
          ),
          // confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
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

  Widget _gradient() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF002776), Color(0xFF001040)],
          ),
        ),
      );

  Widget _buildLoading() => const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFDF00)),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('❌', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Erro ao carregar perguntas',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadQuestions, child: const Text('Tentar novamente')),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Voltar', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      );

  // ── Pergunta ──────────────────────────────────────────────────────────────
  Widget _buildQuestion() {
    final q = _questions[_current];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context, false),
              ),
              Expanded(
                child: Text(
                  'Quiz de Renovação  ⚽',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // ── Progresso ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pergunta ${_current + 1} de ${_questions.length}',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_current + 1) / _questions.length,
                  backgroundColor: Colors.white12,
                  color: const Color(0xFFFFDF00),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF009C3B), size: 14),
                  const SizedBox(width: 4),
                  Text('$_correct acerto${_correct != 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const Spacer(),
                  Text('Acerte 3 de 5 para ganhar +3 chutes',
                      style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Pergunta texto ───────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    q.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.45),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Opções ────────────────────────────────────────────────────
                for (final letter in ['A', 'B', 'C']) ...[
                  _OptionButton(
                    letter: letter,
                    text: q.optionText(letter),
                    chosen: _chosen,
                    correct: q.correct,
                    onTap: _chosen == null ? () => _onAnswer(letter) : null,
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Resultado ─────────────────────────────────────────────────────────────
  Widget _buildResult() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _rewarded ? '🏆' : '😔',
              style: const TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            Text(
              _rewarded ? 'Arrasou!' : 'Quase lá!',
              style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: _rewarded ? const Color(0xFFFFDF00) : Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Você acertou $_correct de ${_questions.length}',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 4),
            if (_rewarded)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF009C3B).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF009C3B)),
                ),
                child: Text(
                  '⚽ +3 chutes desbloqueados!',
                  style: GoogleFonts.poppins(
                      color: const Color(0xFF00FF6A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
              )
            else
              Text(
                'Precisa de ao menos 3 acertos',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
            const SizedBox(height: 36),
            if (_rewarded)
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                icon: const Icon(Icons.sports_soccer),
                label: const Text('Jogar agora!'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009C3B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14)),
              )
            else ...[
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Voltar ao jogo',
                    style: TextStyle(color: Colors.white54)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Widget de opção ───────────────────────────────────────────────────────────

class _OptionButton extends StatelessWidget {
  final String letter;
  final String text;
  final String? chosen;
  final String correct;
  final VoidCallback? onTap;

  const _OptionButton({
    required this.letter,
    required this.text,
    required this.chosen,
    required this.correct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg    = Colors.white.withOpacity(0.08);
    Color border= Colors.white24;
    Color txtCol= Colors.white;

    if (chosen != null) {
      if (letter == correct) {
        bg     = const Color(0xFF009C3B).withOpacity(0.35);
        border = const Color(0xFF009C3B);
        txtCol = const Color(0xFF00FF6A);
      } else if (letter == chosen) {
        bg     = Colors.red.withOpacity(0.25);
        border = Colors.red;
        txtCol = Colors.red.shade200;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28, height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: border.withOpacity(0.25),
                border: Border.all(color: border),
              ),
              child: Text(letter,
                  style: TextStyle(
                      color: txtCol,
                      fontWeight: FontWeight.w800,
                      fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      color: txtCol,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
            if (chosen != null && letter == correct)
              const Icon(Icons.check_circle, color: Color(0xFF00FF6A), size: 20),
            if (chosen != null && letter == chosen && letter != correct)
              const Icon(Icons.cancel, color: Colors.red, size: 20),
          ],
        ),
      ),
    );
  }
}
