import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/score_model.dart';
import '../models/player_score_model.dart';
import '../services/api_service.dart';
import '../widgets/score_card.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  int _tab = 0; // 0 = Salas, 1 = Jogadores

  // ── Salas ─────────────────────────────────────────────────────────────────
  List<ScoreModel> _scores = [];
  bool _scoresLoading = true;
  bool _scoresError = false;

  // ── Jogadores ─────────────────────────────────────────────────────────────
  List<PlayerScoreModel> _players = [];
  bool _playersLoading = false;
  bool _playersLoaded = false;
  bool _playersError = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchScores();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (_tab == 0) {
        _fetchScores(silent: true);
      } else {
        _fetchPlayers(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchScores({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _scoresLoading = true;
        _scoresError = false;
      });
    }
    try {
      final scores = await ApiService.getScores();
      if (mounted) {
        setState(() {
          _scores = scores;
          _scoresLoading = false;
          _scoresError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _scoresLoading = false;
          _scoresError = _scores.isEmpty;
        });
      }
    }
  }

  Future<void> _fetchPlayers({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _playersLoading = true;
        _playersError = false;
      });
    }
    try {
      final players = await ApiService.getPlayerScores();
      if (mounted) {
        setState(() {
          _players = players;
          _playersLoading = false;
          _playersLoaded = true;
          _playersError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _playersLoading = false;
          _playersError = _players.isEmpty;
        });
      }
    }
  }

  void _switchTab(int tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (tab == 1 && !_playersLoaded) _fetchPlayers();
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆  Placar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _tab == 0 ? _fetchScores : _fetchPlayers,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Pill segmented control ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _PillControl(
              tab: _tab,
              onChanged: _switchTab,
            ),
          ),

          // ── Conteúdo ──────────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: _tab == 0
                  ? _buildSalasContent()
                  : _buildPlayersContent(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Salas ─────────────────────────────────────────────────────────────
  Widget _buildSalasContent() {
    if (_scoresLoading && _scores.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF009C3B)),
      );
    }

    if (_scoresError) {
      return _errorWidget(_fetchScores);
    }

    if (_scores.isEmpty) {
      return _emptyWidget('Nenhum chute registrado ainda.\nSeja o primeiro! ⚽');
    }

    return RefreshIndicator(
      onRefresh: _fetchScores,
      color: const Color(0xFF009C3B),
      child: ListView(
        key: const ValueKey('salas'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        children: [
          _autoUpdateHint(),
          const SizedBox(height: 12),
          ..._scores.asMap().entries.map((e) {
            final i = e.key;
            final score = e.value;
            return ScoreCard(score: score, position: i + 1)
                .animate(key: ValueKey(score.sala))
                .fadeIn(delay: (i * 60).ms, duration: 300.ms)
                .slideX(begin: -0.15, curve: Curves.easeOut);
          }),
          const SizedBox(height: 16),
          _buildSalasFooter(),
        ],
      ),
    );
  }

  // ── Tab Jogadores ─────────────────────────────────────────────────────────
  Widget _buildPlayersContent() {
    if (_playersLoading) {
      return const Center(
        key: ValueKey('players-loading'),
        child: CircularProgressIndicator(color: Color(0xFF009C3B)),
      );
    }

    if (_playersError) {
      return _errorWidget(_fetchPlayers);
    }

    if (_players.isEmpty) {
      return _emptyWidget(
          'Nenhum ponto individual ainda.\nJogue para aparecer aqui! 🏹');
    }

    return RefreshIndicator(
      onRefresh: _fetchPlayers,
      color: const Color(0xFF009C3B),
      child: ListView.builder(
        key: const ValueKey('players'),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
        itemCount: _players.length + 2, // hint + items
        itemBuilder: (ctx, i) {
          if (i == 0) return _autoUpdateHint();
          if (i == 1) return const SizedBox(height: 12);
          final idx = i - 2;
          return _PlayerCard(
            player: _players[idx],
            position: idx + 1,
          )
              .animate(key: ValueKey(_players[idx].name + _players[idx].sala))
              .fadeIn(delay: (idx * 60).ms, duration: 300.ms)
              .slideX(begin: -0.15, curve: Curves.easeOut);
        },
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _autoUpdateHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.autorenew, size: 13, color: Colors.white38),
        const SizedBox(width: 4),
        Text(
          'Atualiza automaticamente a cada 5s',
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38),
        ),
      ],
    );
  }

  Widget _errorWidget(VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
          const SizedBox(height: 12),
          const Text('Sem conexão com o servidor',
              style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: retry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _emptyWidget(String msg) {
    return Center(
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 15),
      ),
    );
  }

  Widget _buildSalasFooter() {
    final total = _scores.fold<int>(0, (s, x) => s + x.goals);
    final totalAtt = _scores.fold<int>(0, (s, x) => s + x.attempts);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('⚽ Gols', '$total'),
          _stat('🎯 Chutes', '$totalAtt'),
          _stat(
            '📊 Aproveit.',
            totalAtt > 0
                ? '${(total / totalAtt * 100).toStringAsFixed(1)}%'
                : '—',
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFFFFDF00),
          ),
        ),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pill segmented control com sliding indicator animado
// ─────────────────────────────────────────────────────────────────────────────

class _PillControl extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onChanged;

  const _PillControl({required this.tab, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.09),
        borderRadius: BorderRadius.circular(100),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // ── Pill deslizante ─────────────────────────────────────────────
          AnimatedAlign(
            duration: const Duration(milliseconds: 230),
            curve: Curves.easeInOut,
            alignment:
                tab == 0 ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Labels (por cima do pill) ───────────────────────────────────
          Row(
            children: [
              Expanded(child: _label('🏫  Salas', 0)),
              Expanded(child: _label('👤  Jogadores', 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text, int idx) {
    final selected = tab == idx;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(idx),
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 230),
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : Colors.white38,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de jogador individual
// ─────────────────────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final PlayerScoreModel player;
  final int position;

  const _PlayerCard({required this.player, required this.position});

  @override
  Widget build(BuildContext context) {
    final isTop3 = position <= 3;
    const medals = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isTop3
              ? [
                  const Color(0xFF006B29).withOpacity(0.80),
                  const Color(0xFF002776).withOpacity(0.90),
                ]
              : [
                  Colors.white.withOpacity(0.07),
                  Colors.white.withOpacity(0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: position == 1
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.14),
          width: position == 1 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Posição
            SizedBox(
              width: 40,
              child: Text(
                isTop3 ? medals[position - 1] : '#$position',
                style: GoogleFonts.poppins(
                  fontSize: isTop3 ? 24 : 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),

            // Avatar inicial + nome
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF009C3B).withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF009C3B).withOpacity(0.45)),
              ),
              child: Center(
                child: Text(
                  player.name.isNotEmpty
                      ? player.name[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nome e sala
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    player.salaDisplayName,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Pontuação
            Text(
              '${player.goals} ⚽',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFFDF00),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
