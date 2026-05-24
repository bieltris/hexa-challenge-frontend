import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/comment_model.dart';
import 'rank_badge.dart';

// ── Feitos lendários do Chico ─────────────────────────────────────────────────
const _chicoFeitos = [
  // Futebol
  ('⚽', 'Foi o professor particular do Pelé'),
  ('⚽', 'Inventou o drible da vaca numa tarde de quarta'),
  ('⚽', 'Marcou o gol do Penta em \'94 — ficou no banco por modéstia'),
  ('⚽', 'Ensinou o Neymar a rolar no chão com maestria'),
  ('⚽', 'Descobriu o futebol em 1863 sem querer'),
  // Ed. Física
  ('🏅', 'Único prof de Ed. Física com Doutorado em Cansaço Alheio'),
  ('🏅', 'Ganhou o Nobel da Peteca 3 anos consecutivos'),
  ('🏅', 'Correu mais rápido que o Bolt — na hora do recreio'),
  ('🏅', 'Suas aulas são patrimônio imaterial da UNESCO'),
  ('🏅', 'Detém o recorde mundial de apito mais longo da história'),
];

class CommentCard extends StatefulWidget {
  final CommentModel comment;
  final bool liked;
  final ValueChanged<bool> onLikeChanged;

  const CommentCard({
    super.key,
    required this.comment,
    required this.liked,
    required this.onLikeChanged,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard>
    with TickerProviderStateMixin {
  late bool _liked;
  late int _likes;
  bool _chicoExpanded = false;

  late AnimationController _gradientCtrl;
  late AnimationController _auraCtrl;

  @override
  void initState() {
    super.initState();
    _liked = widget.liked;
    _likes = widget.comment.likes;

    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _auraCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    if (widget.comment.isChico) {
      _gradientCtrl.repeat();
      _auraCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _gradientCtrl.dispose();
    _auraCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = !_liked;
    setState(() {
      _liked = next;
      _likes = next ? _likes + 1 : (_likes - 1).clamp(0, 999999);
    });
    widget.onLikeChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.comment;
    final isPele = c.isPele;
    final isGarrincha = c.isGarrincha;
    final isNeymar = c.isNeymar;
    final isChico = c.isChico;
    final isLegend = isPele || isGarrincha || isNeymar || isChico;

    if (isChico) return _buildChicoCard(c);
    return _buildStandardCard(c, isPele, isGarrincha, isNeymar, isLegend);
  }

  // ── Card do Chico ─────────────────────────────────────────────────────────

  Widget _buildChicoCard(CommentModel c) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gradientCtrl, _auraCtrl]),
      builder: (_, __) {
        final aura = 0.55 + _auraCtrl.value * 0.45;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF002776).withOpacity(aura),
                  blurRadius: 32,
                  spreadRadius: 10),
              BoxShadow(
                  color: const Color(0xFF009C3B).withOpacity(aura),
                  blurRadius: 48,
                  spreadRadius: 14),
              BoxShadow(
                  color: const Color(0xFFFFDF00).withOpacity(aura * 0.85),
                  blurRadius: 64,
                  spreadRadius: 18),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Fundo animado com GradientTransform — rolamento garantido
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
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
                        transform: _GradSlide(_gradientCtrl.value),
                      ),
                    ),
                  ),
                ),
                // Overlay leve para legibilidade
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.28)),
                ),
                // Conteúdo
                _buildChicoContent(c),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChicoContent(CommentModel c) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge topo
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFFDF00), size: 14),
              const SizedBox(width: 4),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [
                    Color(0xFF4FC3F7),
                    Color(0xFF009C3B),
                    Color(0xFFFFDF00)
                  ],
                ).createShader(b),
                child: Text(
                  'Comentário do Criador dos Esportes',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Spacer(),
              // Botão expandir
              GestureDetector(
                onTap: () => setState(() => _chicoExpanded = !_chicoExpanded),
                child: SizedBox(
                  width: 34,
                  height: 20,
                  child: AnimatedRotation(
                    turns: _chicoExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFFFFDF00), size: 34),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlayerAvatar(
                photoUrl: c.playerPhoto,
                name: c.playerName,
                borderColor: const Color(0xFFFFDF00),
                size: 53,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: badge "O Goat" + nome (com ellipsis)
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
                                Color(0xFFFFDF00)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('O Goat',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [
                                Color(0xFF4FC3F7),
                                Color(0xFF009C3B),
                                Color(0xFFFFDF00)
                              ],
                            ).createShader(b),
                            child: Text(c.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Linha 2: chips (rank, sala, tempo) com Wrap pra quebrar se faltar espaço
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (c.rank != null)
                          RankBadge(rank: c.rank!, compact: true),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF009C3B).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c.displaySalaName,
                              style: const TextStyle(
                                  color: Color(0xFF00FF6A),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text(c.timeAgo,
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(c.body,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13.5, height: 1.45)),

          // Lista expansível de feitos
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: _chicoExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 4),
                        Text('🏆 Feitos lendários',
                            style: GoogleFonts.poppins(
                                color: const Color(0xFFFFDF00),
                                fontSize: 11,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ..._chicoFeitos.map((f) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.$1,
                                      style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(f.$2,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                            height: 1.4)),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 10),

          // Footer: música + like
          Row(
            children: [
              // Link Spotify
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(
                      'https://open.spotify.com/intl-pt/track/1uk9L4ffJrPzrjPptBHcAJ'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.music_note,
                        size: 13, color: Color(0xFF1DB954)),
                    const SizedBox(width: 4),
                    Text(
                      'Luz da Lua - Yuri Redicopa',
                      style: TextStyle(
                        color: const Color(0xFFFFDF00),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dashed,
                        decorationColor:
                            const Color(0xFFFFDF00).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Like
              GestureDetector(
                onTap: _toggle,
                child: Row(
                  children: [
                    Icon(_liked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _liked ? Colors.redAccent : Colors.white38),
                    const SizedBox(width: 4),
                    Text('$_likes',
                        style: TextStyle(
                            color: _liked ? Colors.redAccent : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Card padrão ───────────────────────────────────────────────────────────

  Widget _buildStandardCard(CommentModel c, bool isPele, bool isGarrincha,
      bool isNeymar, bool isLegend) {
    final List<Color> gradientColors;
    final Color borderColor;
    final Color glowColor;
    final Color nameColor;
    final Color textColor;
    final Color badgeBg;
    final Color badgeText;

    if (isPele) {
      gradientColors = const [Color(0xFF2A1F00), Color(0xFF3D2E00)];
      borderColor = const Color(0xFFFFDF00);
      glowColor = const Color(0xFFFFDF00);
      nameColor = const Color(0xFFFFDF00);
      textColor = const Color(0xFFFFF5D6);
      badgeBg = const Color(0xFFFFDF00);
      badgeText = const Color(0xFF1A1200);
    } else if (isGarrincha) {
      gradientColors = const [Color(0xFF2A1200), Color(0xFF3D2000)];
      borderColor = const Color(0xFFFF8C00);
      glowColor = const Color(0xFFFF8C00);
      nameColor = const Color(0xFFFFAA33);
      textColor = const Color(0xFFFFF0D6);
      badgeBg = const Color(0xFFFF8C00);
      badgeText = const Color(0xFF1A0800);
    } else if (isNeymar) {
      gradientColors = const [Color(0xFF29270A), Color(0xFF3A3610)];
      borderColor = const Color(0xFFFFEE58);
      glowColor = const Color(0xFFFFEE58);
      nameColor = const Color(0xFFFFEE58);
      textColor = const Color(0xFFFFFDE7);
      badgeBg = const Color(0xFFFFEE58);
      badgeText = const Color(0xFF1A1800);
    } else {
      gradientColors = const [];
      borderColor = Colors.white12;
      glowColor = Colors.transparent;
      nameColor = Colors.white;
      textColor = Colors.white;
      badgeBg = Colors.transparent;
      badgeText = Colors.transparent;
    }

    final badgeLabel = isPele
        ? 'Rei'
        : isNeymar
            ? 'Príncipe'
            : 'Anjo das pernas tortas';
    final topLabel = isPele
        ? 'Comentário Lendário'
        : isNeymar
            ? 'Comentário do Príncipe'
            : 'Comentário do Anjo';
    final topIcon = isPele
        ? Icons.star
        : isNeymar
            ? Icons.star_border
            : Icons.auto_awesome;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: isLegend
            ? LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        color: isLegend ? null : Colors.white.withOpacity(0.07),
        border: Border.all(
          color: borderColor.withOpacity(isLegend ? 0.7 : 1),
          width: isLegend ? 1.5 : 1,
        ),
        boxShadow: isLegend
            ? [
                BoxShadow(
                    color: glowColor.withOpacity(0.14),
                    blurRadius: 16,
                    spreadRadius: 2)
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLegend)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(topIcon, color: borderColor, size: 14),
                  const SizedBox(width: 4),
                  Text(topLabel,
                      style: GoogleFonts.poppins(
                          color: borderColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1)),
                ]),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PlayerAvatar(
                  photoUrl: c.playerPhoto,
                  name: c.playerName,
                  borderColor: borderColor,
                  size: isLegend ? 53 : 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Linha 1: badge legend + nome (com ellipsis)
                      Row(children: [
                        if (isLegend) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(badgeLabel,
                                style: TextStyle(
                                    color: badgeText,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900)),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(c.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  color: nameColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      // Linha 2: chips (rank, sala, tempo) com Wrap
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (c.rank != null)
                            RankBadge(rank: c.rank!, compact: true),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF009C3B).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(c.displaySalaName,
                                style: const TextStyle(
                                    color: Color(0xFF00FF6A),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700)),
                          ),
                          Text(c.timeAgo,
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.body,
                style: TextStyle(
                    color:
                        isLegend ? textColor : Colors.white.withOpacity(0.85),
                    fontSize: 13.5,
                    height: 1.45)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      key: ValueKey(_liked),
                      children: [
                        Icon(_liked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: _liked ? Colors.redAccent : Colors.white38),
                        const SizedBox(width: 4),
                        Text('$_likes',
                            style: TextStyle(
                                color:
                                    _liked ? Colors.redAccent : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── GradientTransform pra rolagem infinita diagonal ──────────────────────────

class _GradSlide extends GradientTransform {
  final double t;
  const _GradSlide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Translada 2 períodos no ciclo completo (t=0..1) → loop perfeito
    return Matrix4.translationValues(
      bounds.width * 2 * t,
      bounds.height * 2 * t,
      0,
    );
  }
}

// ── Avatar do jogador ─────────────────────────────────────────────────────────

class _PlayerAvatar extends StatelessWidget {
  final String photoUrl;
  final String name;
  final Color borderColor;
  final double size;

  const _PlayerAvatar({
    required this.photoUrl,
    required this.name,
    required this.borderColor,
    this.size = 42,
  });

  bool get _isAsset => photoUrl.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    final initials = name.split(' ').take(2).map((w) => w[0]).join();
    Widget img = _isAsset
        ? Image.asset(photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(initials))
        : Image.network(photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(initials));

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ClipOval(child: img),
    );
  }

  Widget _fallback(String initials) => CircleAvatar(
        radius: size / 2,
        backgroundColor: borderColor,
        child: Text(initials,
            style: TextStyle(
                color: Colors.black,
                fontSize: size * 0.31,
                fontWeight: FontWeight.w800)),
      );
}
