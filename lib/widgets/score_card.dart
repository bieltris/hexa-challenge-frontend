import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/score_model.dart';

class ScoreCard extends StatelessWidget {
  final ScoreModel score;
  final int position;

  const ScoreCard({
    super.key,
    required this.score,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = position <= 3;
    const medals = ['🥇', '🥈', '🥉'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isTop3
              ? [
                  const Color(0xFF009C3B).withOpacity(0.75),
                  const Color(0xFF002776).withOpacity(0.9),
                ]
              : [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.04),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: position == 1
              ? const Color(0xFFFFD700)
              : Colors.white.withOpacity(0.18),
          width: position == 1 ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ── Posição ───────────────────────────────────────────────────────
            SizedBox(
              width: 44,
              child: Text(
                isTop3 ? medals[position - 1] : '#$position',
                style: GoogleFonts.poppins(
                  fontSize: isTop3 ? 26 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),

            // ── Nome da sala ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    score.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${score.attempts} tentativa${score.attempts != 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Gols e % ─────────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.goals} ⚽',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFFDF00),
                  ),
                ),
                Text(
                  '${score.percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
