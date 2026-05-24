import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rank.dart';

class RankBadge extends StatelessWidget {
  final Rank rank;
  final bool compact;

  const RankBadge({
    super.key,
    required this.rank,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tooltip = '${rank.label} · ${rank.goals} gols';
    final textColor =
        ThemeData.estimateBrightnessForColor(rank.color) == Brightness.dark
            ? Colors.white
            : const Color(0xFF001040);

    return Tooltip(
      message: tooltip,
      child: Container(
        constraints: BoxConstraints(
          minWidth: compact ? 0 : 92,
          maxWidth: compact ? 104 : 190,
        ),
        padding: EdgeInsets.fromLTRB(8, compact ? 3 : 5, 8, compact ? 3 : 6),
        decoration: BoxDecoration(
          color: rank.color.withValues(alpha: compact ? 0.24 : 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: rank.color.withValues(alpha: 0.62)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, color: rank.color, size: 12),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    rank.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: compact ? rank.color : textColor,
                      fontSize: compact ? 9 : 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: rank.progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  valueColor: AlwaysStoppedAnimation(rank.color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
