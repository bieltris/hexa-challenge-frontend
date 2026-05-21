import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/score_model.dart';
import '../services/api_service.dart';
import '../widgets/score_card.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  List<ScoreModel> _scores = [];
  bool _loading = true;
  bool _error = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchScores();
    // Atualiza a cada 5 segundos
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchScores(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchScores({bool silent = false}) async {
    if (!silent && mounted) setState(() { _loading = true; _error = false; });

    try {
      final scores = await ApiService.getScores();
      if (mounted) {
        setState(() {
          _scores = scores;
          _loading = false;
          _error = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _scores.isEmpty; // Só mostra erro se não houver dados anteriores
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆  Placar Geral'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _fetchScores(),
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _scores.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF009C3B)),
      );
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Sem conexão com o servidor',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _fetchScores(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_scores.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum chute registrado ainda.\nSeja o primeiro! ⚽',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchScores,
      color: const Color(0xFF009C3B),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        children: [
          // Header de atualização automática
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.autorenew, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                'Atualiza automaticamente a cada 5s',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cards rankeados
          ..._scores.asMap().entries.map((e) {
            final index = e.key;
            final score = e.value;
            return ScoreCard(score: score, position: index + 1)
                .animate(key: ValueKey(score.sala))
                .fadeIn(delay: (index * 70).ms, duration: 350.ms)
                .slideX(begin: -0.2, curve: Curves.easeOut);
          }),

          const SizedBox(height: 16),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final total = _scores.fold<int>(0, (sum, s) => sum + s.goals);
    final totalAttempts = _scores.fold<int>(0, (sum, s) => sum + s.attempts);

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
          _stat('⚽ Total de Gols', '$total'),
          _stat('🎯 Total de Chutes', '$totalAttempts'),
          _stat(
            '📊 Aproveitamento',
            totalAttempts > 0
                ? '${(total / totalAttempts * 100).toStringAsFixed(1)}%'
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
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
