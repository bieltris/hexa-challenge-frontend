import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _steps = [
    _Step(
      emoji: '🎮',
      title: 'Minigames',
      subtitle: '',
      accent: Color(0xFF002776),
      accentLight: Color(0xFF006B29),
    ),
    _Step(
      emoji: '💬',
      title: 'Comentários\nLendários',
      subtitle: '',
      accent: Color(0xFF001A4E),
      accentLight: Color(0xFF009C3B),
    ),
  ];

  void _goNext() {
    if (_page < _steps.length - 1) {
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _toHome();
    }
  }

  void _toHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_page];

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              step.accent,
              step.accentLight.withOpacity(0.7),
              const Color(0xFF000D2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Logo
                    Text(
                      '⚽ Hexa Challenge',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    // Skip
                    TextButton(
                      onPressed: _toHome,
                      child: const Text(
                        'Pular',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pages ─────────────────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _steps.length,
                  itemBuilder: (ctx, i) => i == 0
                      ? const _MinigamesPageContent()
                      : const _CommentsPageContent(),
                ),
              ),

              // ── Dots ──────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (i) => _Dot(active: i == _page)),
              ),

              const SizedBox(height: 28),

              // ── Button ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton(
                      key: ValueKey(_page),
                      onPressed: _goNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: step.accent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _page < _steps.length - 1 ? 'Próximo  →' : 'Vamos jogar!  ⚽',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Página individual ─────────────────────────────────────────────────────────

class _PageContent extends StatelessWidget {
  final _Step step;
  const _PageContent({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji com plano de fundo circular
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            ),
            child: Center(
              child: Text(
                step.emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .fadeIn(duration: 300.ms),

          const SizedBox(height: 40),

          // Título
          Text(
            step.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          const SizedBox(height: 16),

          // Subtítulo
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white.withOpacity(0.72),
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(delay: 350.ms, duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          const SizedBox(height: 48),

          // Linha decorativa
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 450.ms),
        ],
      ),
    );
  }
}

// ── Tela 1 — Minigames ────────────────────────────────────────────────────────

class _MinigamesPageContent extends StatelessWidget {
  const _MinigamesPageContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '🎮 Minigames',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

          const SizedBox(height: 6),
          Text(
            'Dois jogos para marcar pontos\npara a sua sala na Copa 2026!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white60,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 32),

          // Card Pênalti
          _GameCard(
            emoji: '⚽',
            label: 'Pênalti',
            description: 'Toque nos 9 alvos do gol.\nO goleiro vai tentar te defender!',
            color: const Color(0xFF006B29),
            shadowColor: const Color(0xFF003D17),
            delayMs: 250,
          ),

          const SizedBox(height: 14),

          // Card Chute Preciso
          _GameCard(
            emoji: '🎯',
            label: 'Chute Preciso',
            description: 'Pare o pêndulo no alvo certo.\nAcumule pontos fase a fase — sem errar!',
            color: const Color(0xFF6B1E00),
            shadowColor: const Color(0xFF3D1000),
            delayMs: 400,
          ),

          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.13)),
            ),
            child: Row(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Acabou os chutes? Faça o quiz\ne ganhe +3 de volta!',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 550.ms),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final Color color;
  final Color shadowColor;
  final int delayMs;

  const _GameCard({
    required this.emoji,
    required this.label,
    required this.description,
    required this.color,
    required this.shadowColor,
    required this.delayMs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs), duration: 400.ms)
        .slideX(begin: -0.15, curve: Curves.easeOut);
  }
}

// ── Tela 2 — Comentários Lendários ────────────────────────────────────────────

class _CommentsPageContent extends StatefulWidget {
  const _CommentsPageContent();

  @override
  State<_CommentsPageContent> createState() => _CommentsPageContentState();
}

class _CommentsPageContentState extends State<_CommentsPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradCtrl;

  @override
  void initState() {
    super.initState();
    _gradCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _gradCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Título cromático ───────────────────────────────────────────────
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFF4FC3F7), Color(0xFF009C3B), Color(0xFFFFDF00)],
            ).createShader(b),
            child: Text(
              'Tire um Comentário\nLendário!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.15,
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: 0.2, curve: Curves.easeOut),

          const SizedBox(height: 8),

          Text(
            'Cada comentário sorteia um lendário\npara aparecer do seu lado! 🎲',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withOpacity(0.65),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),

          // ── Card Pelé ──────────────────────────────────────────────────────
          _LendaryCard(
            delayMs: 300,
            borderColor: const Color(0xFFFFDF00),
            badgeColor: const Color(0xFFFFDF00),
            badgeTextColor: const Color(0xFF1A1200),
            badgeLabel: '👑 Rei',
            name: 'Pelé',
            subtitle: 'O maior de todos os tempos',
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFDF00),
            bgGradient: const [Color(0xFF2A1F00), Color(0xFF3D2E00)],
          ),

          const SizedBox(height: 10),

          // ── Card Neymar ────────────────────────────────────────────────────
          _LendaryCard(
            delayMs: 450,
            borderColor: const Color(0xFFFFEE58),
            badgeColor: const Color(0xFFFFEE58),
            badgeTextColor: const Color(0xFF1A1800),
            badgeLabel: '⚡ Príncipe',
            name: 'Neymar',
            subtitle: 'Dribles, gols e polêmica',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFFFFEE58),
            bgGradient: const [Color(0xFF29270A), Color(0xFF3A3610)],
          ),

          const SizedBox(height: 10),

          // ── Card Chico (cromático animado) ─────────────────────────────────
          AnimatedBuilder(
            animation: _gradCtrl,
            builder: (_, __) => _ChicoPreviewCard(gradT: _gradCtrl.value),
          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.15),

          const SizedBox(height: 22),

          // ── Dica ───────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.13)),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Role a tela até o final para\ncolocar seu comentário!',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 750.ms),
        ],
      ),
    );
  }
}

// ── Card lendário genérico ─────────────────────────────────────────────────────

class _LendaryCard extends StatelessWidget {
  final int delayMs;
  final Color borderColor;
  final Color badgeColor;
  final Color badgeTextColor;
  final String badgeLabel;
  final String name;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final List<Color> bgGradient;

  const _LendaryCard({
    required this.delayMs,
    required this.borderColor,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.badgeLabel,
    required this.name,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: bgGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borderColor.withOpacity(0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.18),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone circular
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: borderColor.withOpacity(0.15),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: TextStyle(
                        color: borderColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delayMs))
        .slideX(begin: -0.15, curve: Curves.easeOut);
  }
}

// ── Card Chico com gradiente animado ──────────────────────────────────────────

class _ChicoPreviewCard extends StatelessWidget {
  final double gradT;
  const _ChicoPreviewCard({required this.gradT});

  @override
  Widget build(BuildContext context) {
    // Borda cromática animada via gradiente com transform
    return Container(
      padding: const EdgeInsets.all(1.8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: const Alignment(-2, -2),
          end: const Alignment(0, 0),
          colors: const [
            Color(0xFF001A4E),
            Color(0xFF002776),
            Color(0xFF009C3B),
            Color(0xFFFFDF00),
            Color(0xFF009C3B),
            Color(0xFF002776),
            Color(0xFF001A4E),
          ],
          tileMode: TileMode.repeated,
          transform: _GradSlideSimple(gradT),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF0A1A0A),
        ),
        child: Row(
          children: [
            // Ícone
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFDF00), width: 2),
                gradient: const LinearGradient(
                  colors: [Color(0xFF002776), Color(0xFF009C3B), Color(0xFFFFDF00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(Icons.emoji_events_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF002776),
                              Color(0xFF009C3B),
                              Color(0xFFFFDF00),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('🏆 O Goat',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(width: 6),
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [
                            Color(0xFF4FC3F7),
                            Color(0xFF009C3B),
                            Color(0xFFFFDF00),
                          ],
                        ).createShader(b),
                        child: const Text('Chico',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Criador dos Esportes',
                      style:
                          TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradSlideSimple extends GradientTransform {
  final double t;
  const _GradSlideSimple(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * 2 * t,
      bounds.height * 2 * t,
      0,
    );
  }
}

// ── Dot de progresso ──────────────────────────────────────────────────────────

class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: active ? Colors.white : Colors.white.withOpacity(0.3),
      ),
    );
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────

class _Step {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  final Color accentLight;

  const _Step({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentLight,
  });
}
