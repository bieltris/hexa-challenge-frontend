class PlayerScoreModel {
  final String name;
  final String sala;
  final int goals;

  const PlayerScoreModel({
    required this.name,
    required this.sala,
    required this.goals,
  });

  factory PlayerScoreModel.fromJson(Map<String, dynamic> json) =>
      PlayerScoreModel(
        name: json['name'] as String,
        sala: json['sala'] as String,
        goals: (json['goals'] as num).toInt(),
      );

  String get salaDisplayName {
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
