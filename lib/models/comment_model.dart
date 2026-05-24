class CommentModel {
  final int id;
  final String sala;
  final String body;
  final String playerName;
  final String playerPhoto;
  final bool isPele;
  final DateTime createdAt;
  int likes;

  CommentModel({
    required this.id,
    required this.sala,
    required this.body,
    required this.playerName,
    required this.playerPhoto,
    required this.isPele,
    required this.createdAt,
    required this.likes,
  });

  factory CommentModel.fromJson(Map<String, dynamic> j) => CommentModel(
        id:          (j['id'] as num).toInt(),
        sala:        j['sala'] as String,
        body:        j['body'] as String,
        playerName:  j['player_name'] as String,
        playerPhoto: j['player_photo'] as String,
        isPele:      j['is_pele'] as bool? ?? false,
        createdAt:   DateTime.tryParse(j['created_at'] as String? ?? '') ??
                     DateTime.now(),
        likes:       (j['likes'] as num?)?.toInt() ?? 0,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60)  return 'agora mesmo';
    if (diff.inMinutes < 60)  return 'há ${diff.inMinutes}min';
    if (diff.inHours   < 24)  return 'há ${diff.inHours}h';
    if (diff.inDays    < 30)  return 'há ${diff.inDays}d';
    if (diff.inDays    < 365) return 'há ${(diff.inDays / 30).floor()}m';
    return 'há ${(diff.inDays / 365).floor()}a';
  }

  static const roomNames = {
    '6ano': '6º Ano', '7ano': '7º Ano', '8ano': '8º Ano',
    '9ano': '9º Ano', '1medio': '1º Médio',
    '2medio': '2º Médio', '3medio': '3º Médio',
  };

  String get salaName => roomNames[sala] ?? sala;

  bool get isGarrincha => playerName == 'Garrincha';
  bool get isNeymar    => playerName == 'Neymar';
  bool get isChico     => playerName == 'Chico';
}
