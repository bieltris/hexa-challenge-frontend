class MissionModel {
  final int id;
  final DateTime? date;
  final String sala;
  final String salaName;
  final String goalType;
  final int target;
  final String reward;
  final int progress;
  final bool completed;
  final DateTime? completedAt;
  final bool delivered;

  const MissionModel({
    required this.id,
    required this.date,
    required this.sala,
    required this.salaName,
    required this.goalType,
    required this.target,
    required this.reward,
    required this.progress,
    required this.completed,
    required this.completedAt,
    required this.delivered,
  });

  factory MissionModel.fromJson(Map<String, dynamic> json) {
    return MissionModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(json['date']?.toString() ?? ''),
      sala: json['sala'] as String? ?? '',
      salaName: json['salaName'] as String? ?? json['sala'] as String? ?? '',
      goalType: json['goalType'] as String? ?? 'goals_count',
      target: (json['target'] as num?)?.toInt() ?? 0,
      reward: json['reward'] as String? ?? 'Caixa de Bis',
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? ''),
      delivered: json['delivered'] as bool? ?? false,
    );
  }

  double get ratio {
    if (target <= 0) return 0;
    return (progress / target).clamp(0.0, 1.0);
  }

  int get remaining => (target - progress).clamp(0, target);
}
