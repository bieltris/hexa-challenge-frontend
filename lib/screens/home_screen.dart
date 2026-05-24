import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/comment_model.dart';
import '../services/api_service.dart';
import '../services/duel_socket_service.dart';
import '../widgets/comment_card.dart';
import 'scoreboard_screen.dart';
import 'game_screen.dart';
import 'arrow_game_screen.dart';
import 'duel_lobby_screen.dart';
import 'duel_game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const _roomNames = {
    '6ano': '6º Ano', '7ano': '7º Ano', '8ano': '8º Ano',
    '9ano': '9º Ano', '1medio': '1º Médio', '2medio': '2º Médio',
    '3medio': '3º Médio',
  };

  // ── Login ─────────────────────────────────────────────────────────────────
  String _loginName = '';
  String _loginSala = '';

  Future<void> _loadLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _loginName = prefs.getString('hexa_name') ?? '';
      _loginSala = prefs.getString('hexa_sala') ?? '';
    });
    if (_loginName.isNotEmpty && _loginSala.isNotEmpty) {
      DuelSocketService.instance.connect(_loginName, _loginSala);
    }
  }

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
  String? _peleTopSala;
  int _peleTopCount = 0;
  String? _neymarTopSala;
  int _neymarTopCount = 0;
  String? _chicoTopSala;
  int _chicoTopCount = 0;
  IO.Socket? _socket;

  // input
  final _commentCtrl = TextEditingController();
  bool _posting = false;

  // banner gradient
  late AnimationController _bannerCtrl;

  Future<void> _loadStats() async {
    try {
      final topRooms = await ApiService.getTopRooms();
      if (mounted)
        setState(() {
          final p = topRooms['pele'] as Map?;
          final n = topRooms['neymar'] as Map?;
          final c = topRooms['chico'] as Map?;
          _peleTopSala = p?['sala'] as String?;
          _peleTopCount = (p?['count'] as num?)?.toInt() ?? 0;
          _neymarTopSala = n?['sala'] as String?;
          _neymarTopCount = (n?['count'] as num?)?.toInt() ?? 0;
          _chicoTopSala = c?['sala'] as String?;
          _chicoTopCount = (c?['count'] as num?)?.toInt() ?? 0;
        });
    } catch (_) {}
  }

  Future<void> _loadComments() async {
    setState(() => _commentsLoading = true);
    try {
      final comments = await ApiService.getComments();
      final prefs = await SharedPreferences.getInstance();
      final liked = prefs.getStringList('liked_comments') ?? [];
      if (mounted)
        setState(() {
          _comments = comments;
          _likedIds = liked.map(int.parse).toSet();
          _commentsLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _commentsLoading = false);
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
    ApiService.likeComment(id, increment: liked).catchError((_) {});
  }

  Future<void> _postComment() async {
    final text = _commentCtrl.text.trim();
    if (text.length < 2 || _posting || _loginSala.isEmpty) return;
    setState(() => _posting = true);
    try {
      await ApiService.postComment(sala: _loginSala, body: text);
      _commentCtrl.clear();
      if (mounted) setState(() => _posting = false);
    } catch (_) {
      if (mounted) setState(() => _posting = false);
    }
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _bannerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
    _loadLogin();
    _loadShots();
    _loadComments();
    _loadStats();
    _connectSocket();
    DuelSocketService.instance.inviteReceived.listen(_onDuelInvite);
    DuelSocketService.instance.duelStart.listen(_onDuelStart);
  }

  void _onDuelInvite(Map<String, dynamic> d) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF4B0082),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFBB44FF).withOpacity(0.5), width: 1.2),
        ),
        margin: const EdgeInsets.all(12),
        elevation: 8,
        duration: const Duration(seconds: 15),
        content: Row(children: [
          const Text('⚔️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${d['from']['name']} quer duelar!',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => InviteDialog(
                  d: d,
                  svc: DuelSocketService.instance,
                  roomNames: _roomNames,
                  onDone: () {},
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFDF00),
              foregroundColor: const Color(0xFF001040),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 3,
            ),
            child: Text(
              'Ver',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ]),
      ),
    );
  }

  void _onDuelStart(Map<String, dynamic> d) {
    if (!mounted) return;
    // Skip if home is not the active route (DuelLobbyScreen handles its own)
    if (ModalRoute.of(context)?.isCurrent != true) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DuelGameScreen(
          data: d,
          name: _loginName,
          sala: _loginSala,
          salaName: _roomNames[_loginSala] ?? _loginSala,
        ),
      ),
    );
  }

  void _connectSocket() {
    _socket = IO.io(
      'https://hexa-challenge-api.onrender.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .build(),
    );
    _socket!.on('new_comment', (data) {
      try {
        final c = CommentModel.fromJson(Map<String, dynamic>.from(data as Map));
        _insertComment(c);
      } catch (_) {}
    });
  }

  void _insertComment(CommentModel c) {
    if (!mounted) return;
    if (_comments.any((x) => x.id == c.id)) return;
    setState(() {
      _comments.insert(0, c);
    });
    _loadStats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadShots();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _bannerCtrl.dispose();
    _socket?.disconnect();
    _socket?.dispose();
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
                // ── Header ───────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader()),

                // ── Minigames ─────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildGameButtons()),

                // ── Compartilhar (entre Duelo e Comentários) ──────────────
                SliverToBoxAdapter(
                  child: _buildShareButton(
                    margin: const EdgeInsets.fromLTRB(28, 6, 28, 14),
                  ),
                ),

                // ── Seção de Comentários ──────────────────────────────────
                SliverToBoxAdapter(child: _buildCommentsSection()),

                // espaço para o FAB
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          ),

          // FAB Sugestões
          Positioned(
            bottom: 82,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'suggestions_fab',
              onPressed: _showSuggestionsModal,
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              label: const Text('Sugestões'),
              icon: const Icon(Icons.lightbulb_outline),
            )
                .animate()
                .fadeIn(delay: 900.ms)
                .scale(begin: const Offset(0.7, 0.7)),
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
            )
                .animate()
                .fadeIn(delay: 800.ms)
                .scale(begin: const Offset(0.7, 0.7)),
          ),
        ],
      ),
    );
  }

  // ── Modal Sugestões ───────────────────────────────────────────────────────
  Future<void> _showSuggestionsModal() async {
    final ctrl = TextEditingController();
    bool sending = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: const Color(0xFF001A4E),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Color(0xFFFFDF00), size: 20),
              const SizedBox(width: 8),
              Text('Sugestões',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('O que você quer melhorar ou ver no app?',
                  style:
                      GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Sua sugestão...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.16)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.white.withOpacity(0.16)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF1565C0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: sending
                  ? null
                  : () async {
                      final text = ctrl.text.trim();
                      if (text.length < 2) return;
                      setDialog(() => sending = true);
                      try {
                        await ApiService.postSuggestion(body: text);
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sugestão enviada! Obrigado 🙌'),
                              backgroundColor: Color(0xFF1565C0),
                            ),
                          );
                        }
                      } catch (_) {
                        setDialog(() => sending = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        // Título do jogo
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚽', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFDF00), Color(0xFF00D45B)],
                  ).createShader(b),
                  child: Text(
                    'Hexa Challenge',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Banner recompensa secreta
        _RewardBanner(ctrl: _bannerCtrl),

        const SizedBox(height: 10),

        // Saudação
        if (_loginName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'Eai, $_loginName! 👋',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ).animate().fadeIn(delay: 200.ms),
          ),

        const SizedBox(height: 12),
      ],
    );
  }

  // ── Botão Compartilhar (amarelo) ──────────────────────────────────────────
  Widget _buildShareButton({EdgeInsets margin = EdgeInsets.zero}) {
    return Padding(
      padding: margin,
      child: GestureDetector(
        onTap: () => Share.share(
          'Joga Hexa Challenge comigo! ⚽\nDuelo de pênalti entre escolas — Copa 2026\nhttps://hexa-challenge.pages.dev',
          subject: 'Hexa Challenge — entra no jogo!',
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE94A), Color(0xFFFFC400)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              const BoxShadow(
                color: Color(0xFFB58900),
                offset: Offset(0, 5),
                blurRadius: 0,
              ),
              BoxShadow(
                color: const Color(0xFFFFDF00).withOpacity(0.4),
                offset: const Offset(0, 8),
                blurRadius: 12,
              ),
            ],
            border: Border.all(color: const Color(0xFFFFEC8B), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.share_rounded, color: Color(0xFF001040), size: 20),
              const SizedBox(width: 10),
              Text(
                'Convidar amigos',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF001040),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Minigames (blocos 3D) ──────────────────────────────────────────────────
  Widget _buildGameButtons() {
    final salaName = _roomNames[_loginSala] ?? _loginSala;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _GameBlock(
                  label: 'Pênalti',
                  emoji: '⚽',
                  sublabel: salaName,
                  color: const Color(0xFF006B29),
                  shadowColor: const Color(0xFF003D17),
                  shotsLeft: _shotsLeft,
                  onTap: _loginSala.isEmpty
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => GameScreen(
                                sala: _loginSala,
                                salaName: salaName,
                                playerName: _loginName,
                              ),
                            ),
                          );
                          if (mounted) _loadShots();
                        },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _GameBlock(
                  label: 'Chute Preciso',
                  emoji: '🎯',
                  sublabel: salaName,
                  color: const Color(0xFF6B1E00),
                  shadowColor: const Color(0xFF3D1000),
                  onTap: _loginSala.isEmpty
                      ? null
                      : () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArrowGameScreen(
                                sala: _loginSala,
                                salaName: salaName,
                                playerName: _loginName,
                              ),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _loginSala.isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DuelLobbyScreen(
                          name: _loginName,
                          sala: _loginSala,
                          salaName: salaName,
                        ),
                      ),
                    ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _loginSala.isEmpty
                      ? [const Color(0xFF2A0050), const Color(0xFF0D0030)]
                      : [const Color(0xFF4B0082), const Color(0xFF1A0060)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _loginSala.isEmpty
                    ? []
                    : [
                        const BoxShadow(
                          color: Color(0xFF1A0060),
                          offset: Offset(0, 6),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: const Color(0xFF1A0060).withOpacity(0.4),
                          offset: const Offset(0, 10),
                          blurRadius: 8,
                        ),
                      ],
                border: Border.all(
                  color: _loginSala.isEmpty
                      ? Colors.white10
                      : const Color(0xFFBB44FF).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Duelo 1v1',
                    style: GoogleFonts.poppins(
                      color: _loginSala.isEmpty ? Colors.white24 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

        // ── Top salas ─────────────────────────────────────────────────────────
        if (_peleTopSala != null ||
            _neymarTopSala != null ||
            _chicoTopSala != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Sala que mais tirou:',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (_peleTopSala != null)
                      Expanded(
                          child: _TopRoomChip(
                        label: '👑 Rei',
                        sala: CommentModel.roomNames[_peleTopSala!] ??
                            _peleTopSala!,
                        count: _peleTopCount,
                        borderColor: const Color(0xFFFFDF00),
                        bg: const Color(0xFF2A1F00),
                        isChromatic: false,
                      )),
                    if (_peleTopSala != null && _neymarTopSala != null)
                      const SizedBox(width: 6),
                    if (_neymarTopSala != null)
                      Expanded(
                          child: _TopRoomChip(
                        label: '⚡ Príncipe',
                        sala: CommentModel.roomNames[_neymarTopSala!] ??
                            _neymarTopSala!,
                        count: _neymarTopCount,
                        borderColor: const Color(0xFFFFEE58),
                        bg: const Color(0xFF29270A),
                        isChromatic: false,
                      )),
                    if (_neymarTopSala != null && _chicoTopSala != null)
                      const SizedBox(width: 6),
                    if (_chicoTopSala != null)
                      Expanded(
                          child: _TopRoomChip(
                        label: '🏆 O Goat',
                        sala: CommentModel.roomNames[_chicoTopSala!] ??
                            _chicoTopSala!,
                        count: _chicoTopCount,
                        borderColor: const Color(0xFF009C3B),
                        bg: const Color(0xFF0A1A0A),
                        isChromatic: true,
                      )),
                  ],
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
                    color: Color(0xFFFFDF00), strokeWidth: 2)),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: Text('Seja o primeiro a comentar! ⚽',
                    style: TextStyle(color: Colors.white38, fontSize: 13))),
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
          border: Border.all(color: Colors.white.withOpacity(0.16)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Campo de texto
            Expanded(
              child: Focus(
                onKeyEvent: (_, event) {
                  // Enter sem Shift → envia; Shift+Enter → nova linha
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    _postComment();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _commentCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _loginSala.isEmpty
                        ? 'Faça login para comentar...'
                        : 'Comentar como ${_roomNames[_loginSala] ?? _loginSala}...',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  enabled: _loginSala.isNotEmpty,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),

            // Botão enviar
            _posting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF009C3B)))
                : IconButton(
                    onPressed: _loginSala.isNotEmpty ? _postComment : null,
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

// ── Gradient Transform para banner ────────────────────────────────────────────

class _HomeGradSlide extends GradientTransform {
  final double t;
  const _HomeGradSlide(this.t);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Rolamento diagonal: desloca nos dois eixos para criar movimento 45°
    return Matrix4.translationValues(
      bounds.width * 2 * t,
      bounds.height * 2 * t,
      0,
    );
  }
}

// ── Banner de recompensa secreta ──────────────────────────────────────────────

class _RewardBanner extends StatelessWidget {
  final AnimationController ctrl;
  const _RewardBanner({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF001A4E), Color(0xFF002776)],
          ),
          border: Border.all(
              color: const Color(0xFFFFDF00).withOpacity(0.25), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFDF00).withOpacity(0.08),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Linha principal: "🎁 Recompensa secreta"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎁 ', style: TextStyle(fontSize: 22)),
                Text(
                  'Recompensa ',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // "secreta" com gradiente cromático diagonal rolante
                RepaintBoundary(
                 child: AnimatedBuilder(
                  animation: ctrl,
                  builder: (_, __) => ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: const Alignment(-2, -2),
                      end: const Alignment(2, 2),
                      tileMode: TileMode.repeated,
                      transform: _HomeGradSlide(ctrl.value),
                      colors: const [
                        Color(0xFFFF0040), // vermelho
                        Color(0xFFFF6600), // laranja
                        Color(0xFFFFDF00), // amarelo
                        Color(0xFF00D45B), // verde
                        Color(0xFF00CFFF), // ciano
                        Color(0xFF4488FF), // azul
                        Color(0xFFBB44FF), // roxo
                        Color(0xFFFF44CC), // rosa
                        Color(0xFFFF0040), // vermelho (fecha o loop)
                      ],
                    ).createShader(bounds),
                    child: Text(
                      'secreta',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                 )),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'para a sala com mais gols',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'até o início da copa',
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bloco de minigame 3D ──────────────────────────────────────────────────────

class _GameBlock extends StatefulWidget {
  final String label;
  final String emoji;
  final String sublabel;
  final Color color;
  final Color shadowColor;
  final VoidCallback? onTap;
  final int? shotsLeft;
  final int maxShots;

  const _GameBlock({
    required this.label,
    required this.emoji,
    required this.sublabel,
    required this.color,
    required this.shadowColor,
    required this.onTap,
    this.shotsLeft,
    this.maxShots = 3,
  });

  @override
  State<_GameBlock> createState() => _GameBlockState();
}

class _GameBlockState extends State<_GameBlock> {
  bool _pressed = false;
  static const _depth = 6.0;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final effectiveColor = disabled ? widget.color.withOpacity(0.5) : widget.color;
    final effectiveShadow = disabled ? widget.shadowColor.withOpacity(0.5) : widget.shadowColor;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        transform: Matrix4.translationValues(0, _pressed ? _depth : 0, 0),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: effectiveShadow,
                  offset: Offset(0, _pressed ? 0 : _depth),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: effectiveShadow.withOpacity(0.4),
                  offset: Offset(0, _pressed ? 0 : _depth + 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.poppins(
                    color: disabled ? Colors.white38 : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                if (widget.sublabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.sublabel,
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (widget.shotsLeft != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.maxShots, (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.sports_soccer,
                        size: 15,
                        color: widget.shotsLeft! > i
                            ? const Color(0xFFFFDF00)
                            : Colors.white24,
                      ),
                    )),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip de sala campeã ───────────────────────────────────────────────────────

class _TopRoomChip extends StatelessWidget {
  final String label;
  final String sala;
  final int count;
  final Color borderColor;
  final Color bg;
  final bool isChromatic;

  const _TopRoomChip({
    required this.label,
    required this.sala,
    required this.count,
    required this.borderColor,
    required this.bg,
    required this.isChromatic,
  });

  @override
  Widget build(BuildContext context) {
    final border = isChromatic
        ? null
        : Border.all(color: borderColor.withOpacity(0.55), width: 1);

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isChromatic ? Colors.white : borderColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sala,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$count ${count == 1 ? 'vez' : 'vezes'}',
            style: TextStyle(
              color:
                  isChromatic ? Colors.white60 : borderColor.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (!isChromatic) return content;

    // Borda cromática para o Chico
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF002776), Color(0xFF009C3B), Color(0xFFFFDF00)],
        ),
      ),
      child: content,
    );
  }
}
