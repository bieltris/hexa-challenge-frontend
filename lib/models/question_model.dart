class QuestionModel {
  final int id;
  final String text;
  final String optA;
  final String optB;
  final String optC;
  final String correct; // 'A', 'B' ou 'C'

  const QuestionModel({
    required this.id,
    required this.text,
    required this.optA,
    required this.optB,
    required this.optC,
    required this.correct,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> j) => QuestionModel(
        id: (j['id'] as num).toInt(),
        text: j['text'] as String,
        optA: j['opt_a'] as String,
        optB: j['opt_b'] as String,
        optC: j['opt_c'] as String,
        correct: (j['correct'] as String).toUpperCase().trim(),
      );

  String optionText(String letter) {
    switch (letter.toUpperCase()) {
      case 'A': return optA;
      case 'B': return optB;
      case 'C': return optC;
      default:  return '';
    }
  }

  bool isCorrect(String chosen) =>
      chosen.toUpperCase().trim() == correct;
}
