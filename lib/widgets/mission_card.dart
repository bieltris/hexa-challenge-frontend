import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/mission_model.dart';

class MissionCard extends StatefulWidget {
  final MissionModel mission;
  final VoidCallback onHistoryTap;

  const MissionCard({
    super.key,
    required this.mission,
    required this.onHistoryTap,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(milliseconds: 900));
    if (widget.mission.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confetti.play());
    }
  }

  @override
  void didUpdateWidget(covariant MissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.mission.completed && widget.mission.completed) {
      _confetti.play();
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final complete = mission.completed;
    final fg = complete ? const Color(0xFF001040) : Colors.white;
    final muted = complete ? const Color(0xFF00331A) : Colors.white60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: complete
                  ? const Color(0xFFFFDF00)
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: complete
                    ? const Color(0xFFFFF2A6)
                    : Colors.white.withValues(alpha: 0.16),
              ),
              boxShadow: complete
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFDF00).withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag_rounded,
                        size: 18,
                        color: complete
                            ? const Color(0xFF001040)
                            : const Color(0xFFFFDF00)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Missão de hoje — ${mission.salaName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: fg,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Histórico',
                      onPressed: widget.onHistoryTap,
                      icon: Icon(Icons.history_rounded, color: muted, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Marcar ${mission.target} gols juntos · Recompensa: ${mission.reward}',
                  style: GoogleFonts.poppins(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: mission.ratio,
                    minHeight: 8,
                    backgroundColor: complete
                        ? Colors.black.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(
                      complete
                          ? const Color(0xFF009C3B)
                          : const Color(0xFFFFDF00),
                    ),
                  ),
                ).animate().fadeIn(duration: 260.ms),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        complete
                            ? 'Conquistada — fala com a coordenação'
                            : 'Faltam ${mission.remaining} gols',
                        style: GoogleFonts.poppins(
                          color: complete
                              ? const Color(0xFF00331A)
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      '${mission.progress}/${mission.target}',
                      style: GoogleFonts.poppins(
                        color: muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.18,
            numberOfParticles: 16,
            gravity: 0.22,
            colors: const [
              Color(0xFF009C3B),
              Color(0xFFFFDF00),
              Color(0xFF002776),
              Colors.white,
            ],
          ),
        ],
      ),
    );
  }
}
