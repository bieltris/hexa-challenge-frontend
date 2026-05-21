import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/comment_model.dart';
import '../services/api_service.dart';
import '../widgets/room_card.dart';
import '../widgets/comment_card.dart';
import 'scoreboard_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _rooms = [
    ('6ano',   '6º Ano'),
    ('7ano',   '7º Ano'),
    ('8ano',   '8º Ano'),
    ('9ano',   '9º Ano'),
    ('1medio', '1º Médio'),
    ('2medio', '2º Médio'),
    ('3medio', '3º Médio'),
  ];

  // ── Chutes ────────────────────────────────────────────────────────────────
  int _shotsLeft = 3;

  Future<void> _loadShots() async {
    final prefs = await SharedPreferences.getInstance();
    final shots = prefs.getInt('hexa_shots') ?? 3;
    if (mounted) setState(() => _shotsLeft = shots.clamp(0, 99));
  }

  // ── Comentários ───────────────────────────────────────────────────────────
  List<CommentModel> _comments = [];
  bool _commentsLoading = true;
  Set<int> _likedIds = {};

  // input
  final _commentCtrl = TextEditingController();
  String _selectedSala = '6ano';
  bool _posting = false;

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    try {
      final comments = await ApiService.getComments();
      final prefs    = await SharedPreferences.getInstance();
      final liked    = prefs.getStringList('liked_comments') ?? [];
      if (mounted) {
        setState(() {
          _comments = comments;
          _likedIds = liked.map(int.parse).toSet();
          _commentsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.length < 2 || _posting) return;
    setState(() => _posting = true);
    try {
      final c = await ApiService.postComment(sala: _selectedSala, body: text);
      _commentCtrl.clear();
      // Pelé vai pro topo; outros vão logo após Pelé
      if (mounted) {
        setState(() {
          if (c.isPele) {
            _comments.insert(0, c);
          } else {
            // insere após o último Pelé
            final afterPele = _comments.indexWhere((x) => !x.isPele);
            _comments.insert(afterPele < 0 ? 0 : afterPele, c);
          }
          _posting = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _persistLike(int id, bool liked) async {
    final prefs = await SharedPreferences.getInstance();
    if (liked) {
      _likedIds.add(id);
    } else {
      _likedIds.remove(id);
    }
    await prefs.setStringList(
        'liked_comments', _likedIds.map((e) => e.toString()).toList());
    // fire-and-forget para o backend
    ApiService.likeComment(id, increment: liked).catchError((_) {});
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadShots();
    _loadComments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadShots();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF002776), Color(0xFF001040)],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header fixo ───────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader()),

                // ── Grid de salas ─────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => RoomCard(
                        salaKey:  _rooms[i].$1,
                        salaName: _rooms[i].$2,
                        index:    i,
                        shotsLeft: _shotsLeft,
                      ),
                      childCount: _rooms.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                  ),
                ),

                // ── Botão quiz quando sem chutes ──────────────────────────
                if (_shotsLeft == 0)
                  SliverToBoxAdapter(child: _buildQuizBanner()),

                // ── Seção de Comentários ──────────────────────────────────
                SliverToBoxAdapter(child: _buildCommentsSection()),

                // espaço para o FAB
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // FAB Placar
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'home_fab',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScoreboardScreen()),
              ),
              label: const Text('Ver Placar'),
              icon: const Icon(Icons.emoji_events),
            ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.7, 0.7)),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 28),
        const Text('⚽', style: TextStyle(fontSize: 64))
            .animate()
            .scale(
              begin: const Offset(0.3, 0.3),
              duration: 700.ms,
              curve: Curves.elasticOut,
            ),
        const SizedBox(height: 10),
        Text(
          'HEXA CHALLENGE',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFFFDF00),
            letterSpacing: 2.5,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
        Text(
          '🇧🇷  Copa do Mundo 2026',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 20),
        // Contador de chutes
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.sports_soccer,
              size: 28,
              color: _shotsLeft > i ? const Color(0xFFFFDF00) : Colors.white24,
            ),
          )),
        ).animate().fadeIn(delay: 450.ms),
        const SizedBox(height: 4),
        Text(
          _shotsLeft > 0
              ? '$_shotsLeft chute${_shotsLeft > 1 ? 's' : ''} restante${_shotsLeft > 1 ? 's' : ''}'
              : 'Sem chutes — renove com o quiz! ⬇',
          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        Text(
          _shotsLeft > 0 ? 'Escolha sua sala:' : 'Refaça o quiz para jogar de novo',
          style: GoogleFonts.poppins(
              fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 550.ms),
        const SizedBox(height: 14),
      ],
    );
  }

  // ── Banner Quiz ───────────────────────────────────────────────────────────
  Widget _buildQuizBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: ElevatedButton.icon(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const QuizScreen()),
          );
          if (ok == true && mounted) _loadShots();
        },
        icon: const Icon(Icons.quiz),
        label: const Text('Responder Quiz → +3 chutes'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFDF00),
          foregroundColor: const Color(0xFF001040),
          minimumSize: const Size(double.infinity, 48),
          textStyle: GoogleFonts.poppins(
              fontSize: 14, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  // ── Seção Comentários ─────────────────────────────────────────────────────
  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho seção
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Expanded(
                child: Divider(color: Colors.white12, thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '💬 Comentários',
                  style: GoogleFonts.poppins(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: Colors.white12, thickness: 1),
              ),
            ],
          ),
        ),

        // Input de comentário
        _buildCommentInput(),

        const SizedBox(height: 12),

        // Lista de comentários
        if (_commentsLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFFDF00), strokeWidth: 2),
            ),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Seja o primeiro a comentar! ⚽',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (ctx, i) {
              final c = _comments[i];
              return CommentCard(
                comment: c,
                liked: _likedIds.contains(c.id),
                onLikeChanged: (liked) => _persistLike(c.id, liked),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCommentInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white16),
        ),
        padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Dropdown sala
            Container(
              margin: const EdgeInsets.only(right: 4, bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF009C3B).withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF009C3B).withOpacity(0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSala,
                  dropdownColor: const Color(0xFF002776),
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Colors.white54, size: 18),
                  items: _rooms.map((r) => DropdownMenuItem(
                    value: r.$1,
                    child: Text(r.$2),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedSala = v);
                  },
                ),
              ),
            ),

            // Campo de texto
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Escreva um comentário...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                ),
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),

            // Botão enviar
            _posting
                ? const SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF009C3B)))
                : IconButton(
                    onPressed: _postComment,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFF009C3B),
                    iconSize: 22,
                  ),
          ],
        ),
      ),
    );
  }
}
