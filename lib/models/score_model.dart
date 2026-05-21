class ScoreModel {
  final String sala;
  final int goals;
  final int attempts;

  const ScoreModel({
    required this.sala,
    required this.goals,
    required this.attempts,
  });

  factory ScoreModel.fromJson(Map<String, dynamic> json) => ScoreModel(
        sala: json['sala'] as String,
        goals: (json['goals'] as num).toInt(),
        attempts: (json['attempts'] as num).toInt(),
      );

  double get percentage => attempts > 0 ? (goals / attempts * 100) : 0.0;

  String get displayName {
    const names = {
      '6ano': '6º Ano',
      '7ano': '7º Ano',
      '8ano': '8º Ano',
      '9ano': '9º Ano',
      '1medio': '1º Médio',
      '2medio': '2º Médio',
      '3medio': '3º Médio',
    };
    return names[sala] ?? sala;
  }
}
