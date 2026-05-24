import 'package:flutter/material.dart';

class RankNext {
  final String label;
  final int min;

  const RankNext({
    required this.label,
    required this.min,
  });
}

class Rank {
  final int min;
  final String label;
  final Color color;
  final RankNext? next;
  final double progress;
  final int goals;

  const Rank({
    required this.min,
    required this.label,
    required this.color,
    required this.next,
    required this.progress,
    required this.goals,
  });

  static const _table = [
    _RankDef(0, 'Peneira', Color(0xFF9CA3AF)),
    _RankDef(6, 'Base', Color(0xFF84CC16)),
    _RankDef(21, 'Juvenil', Color(0xFF22C55E)),
    _RankDef(51, 'Profissional', Color(0xFF06B6D4)),
    _RankDef(101, 'Titular', Color(0xFF3B82F6)),
    _RankDef(201, 'Convocado', Color(0xFF8B5CF6)),
    _RankDef(401, 'Camisa 10', Color(0xFFF59E0B)),
    _RankDef(701, 'Craque', Color(0xFFEF4444)),
    _RankDef(1001, 'Lenda', Color(0xFFFFD700)),
  ];

  factory Rank.of(int goals) {
    final safeGoals = goals < 0 ? 0 : goals;
    var currentIndex = 0;
    for (var i = _table.length - 1; i >= 0; i--) {
      if (safeGoals >= _table[i].min) {
        currentIndex = i;
        break;
      }
    }

    final current = _table[currentIndex];
    final nextDef =
        currentIndex + 1 < _table.length ? _table[currentIndex + 1] : null;
    final progress = nextDef == null
        ? 1.0
        : ((safeGoals - current.min) / (nextDef.min - current.min))
            .clamp(0.0, 1.0);

    return Rank(
      min: current.min,
      label: current.label,
      color: current.color,
      next: nextDef == null
          ? null
          : RankNext(label: nextDef.label, min: nextDef.min),
      progress: progress,
      goals: safeGoals,
    );
  }

  factory Rank.fromJson(Map<String, dynamic>? json, {int goals = 0}) {
    if (json == null) return Rank.of(goals);
    final label = json['label'] as String?;
    final color = _parseColor(json['color'] as String?);
    final progress = (json['progress'] as num?)?.toDouble();
    final rankGoals = (json['goals'] as num?)?.toInt() ?? goals;
    final fallback = Rank.of(rankGoals);
    final nextJson = json['next'] as Map<String, dynamic>?;

    return Rank(
      min: fallback.min,
      label: label ?? fallback.label,
      color: color ?? fallback.color,
      next: nextJson == null
          ? fallback.next
          : RankNext(
              label: nextJson['label'] as String? ?? fallback.next?.label ?? '',
              min: (nextJson['min'] as num?)?.toInt() ??
                  fallback.next?.min ??
                  fallback.min,
            ),
      progress: (progress ?? fallback.progress).clamp(0.0, 1.0),
      goals: rankGoals,
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    final value =
        int.tryParse(cleaned.length == 6 ? 'FF$cleaned' : cleaned, radix: 16);
    return value == null ? null : Color(value);
  }
}

class _RankDef {
  final int min;
  final String label;
  final Color color;

  const _RankDef(this.min, this.label, this.color);
}
