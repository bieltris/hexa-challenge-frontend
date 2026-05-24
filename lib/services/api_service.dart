import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/score_model.dart';
import '../models/question_model.dart';
import '../models/comment_model.dart';
import '../models/mission_model.dart';
import '../models/player_score_model.dart';
import '../models/rank.dart';

class PlayerMe {
  final String name;
  final String sala;
  final int goals;
  final int attempts;
  final Rank rank;

  const PlayerMe({
    required this.name,
    required this.sala,
    required this.goals,
    required this.attempts,
    required this.rank,
  });

  factory PlayerMe.fromJson(Map<String, dynamic> json) {
    final goals = (json['goals'] as num?)?.toInt() ?? 0;
    return PlayerMe(
      name: json['name'] as String? ?? '',
      sala: json['sala'] as String? ?? '',
      goals: goals,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      rank: Rank.fromJson(json['rank'] as Map<String, dynamic>?, goals: goals),
    );
  }
}

class MapRegionModel {
  final String id;
  final String? sala;
  final String salaName;
  final int percent;
  final int goals;

  const MapRegionModel({
    required this.id,
    required this.sala,
    required this.salaName,
    required this.percent,
    required this.goals,
  });

  factory MapRegionModel.fromJson(String id, Map<String, dynamic> json) {
    return MapRegionModel(
      id: id,
      sala: json['sala'] as String?,
      salaName: json['salaName'] as String? ?? 'Ninguém conquistou ainda',
      percent: (json['percent'] as num?)?.round() ?? 0,
      goals: (json['goals'] as num?)?.toInt() ?? 0,
    );
  }
}

class MapRegionsSnapshot {
  final Map<String, MapRegionModel> regions;
  final int totalGoals;
  final bool isMock;

  const MapRegionsSnapshot({
    required this.regions,
    required this.totalGoals,
    this.isMock = false,
  });

  factory MapRegionsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawRegions = json['regions'] as Map<String, dynamic>? ?? {};
    return MapRegionsSnapshot(
      totalGoals: (json['totalGoals'] as num?)?.toInt() ?? 0,
      regions: rawRegions.map(
        (id, value) => MapEntry(
          id,
          MapRegionModel.fromJson(id, value as Map<String, dynamic>),
        ),
      ),
    );
  }

  factory MapRegionsSnapshot.empty() {
    return const MapRegionsSnapshot(
      regions: {},
      totalGoals: 0,
      isMock: false,
    );
  }
}

class ApiService {
  static const String _base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );

  // ── Scores ────────────────────────────────────────────────────────────────
  static Future<List<ScoreModel>> getScores() async {
    final res = await http
        .get(Uri.parse('$_base/api/scores'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => ScoreModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar placar: ${res.statusCode}');
  }

  // ── Shoot ─────────────────────────────────────────────────────────────────
  static Future<void> registerShot({
    required String sala,
    required bool scored,
    String? playerName,
  }) async {
    await http
        .post(
          Uri.parse('$_base/api/shoot'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sala': sala,
            'scored': scored,
            if (playerName != null && playerName.isNotEmpty) 'name': playerName,
          }),
        )
        .timeout(const Duration(seconds: 10));
  }

  // ── Player Scores ─────────────────────────────────────────────────────────
  static Future<List<PlayerScoreModel>> getPlayerScores() async {
    final res = await http
        .get(Uri.parse('$_base/api/players/scores'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => PlayerScoreModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar jogadores: ${res.statusCode}');
  }

  static Future<PlayerMe> getMe({
    required String name,
    required String sala,
  }) async {
    final uri = Uri.parse('$_base/api/players/me').replace(
      queryParameters: {'name': name, 'sala': sala},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return PlayerMe.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao carregar jogador: ${res.statusCode}');
  }

  // ── Territorial map ──────────────────────────────────────────────────────
  static Future<MapRegionsSnapshot> getMapRegions() async {
    try {
      final res = await http
          .get(Uri.parse('$_base/api/map/regions'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return MapRegionsSnapshot.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {}

    return MapRegionsSnapshot.empty();
  }

  // ── Missions ─────────────────────────────────────────────────────────────
  static Future<List<MissionModel>> getTodayMissions() async {
    final res = await http
        .get(Uri.parse('$_base/api/missions/today'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => MissionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar missões: ${res.statusCode}');
  }

  static Future<List<MissionModel>> getMissionHistory({
    required String sala,
    int limit = 30,
  }) async {
    final uri = Uri.parse('$_base/api/missions/history').replace(
      queryParameters: {'sala': sala, 'limit': '$limit'},
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => MissionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar histórico: ${res.statusCode}');
  }

  // ── Quiz ──────────────────────────────────────────────────────────────────
  static Future<List<QuestionModel>> getQuestions({int count = 5}) async {
    final res = await http
        .get(Uri.parse('$_base/api/questions/random?count=$count'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => QuestionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar perguntas: ${res.statusCode}');
  }

  // ── Comments ──────────────────────────────────────────────────────────────
  static Future<List<CommentModel>> getComments() async {
    final res = await http
        .get(Uri.parse('$_base/api/comments'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((j) => CommentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Erro ao carregar comentários: ${res.statusCode}');
  }

  static Future<CommentModel> postComment({
    required String sala,
    required String body,
    String? name,
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/comments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sala': sala,
            'body': body,
            if (name != null && name.isNotEmpty) 'name': name,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 201) {
      return CommentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao postar comentário: ${res.statusCode}');
  }

  static Future<CommentModel> postAudioComment({
    required String sala,
    required String name,
    required List<int> bytes,
    required int durMs,
    String mime = 'audio/mp4',
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/api/comments/audio'),
    );
    req.headers['x-audio-duration-ms'] = '$durMs';
    req.fields['sala'] = sala;
    req.fields['name'] = name;
    // Extensão derivada do mime (apenas para nomear o file no multipart)
    final ext = mime.contains('webm')
        ? 'webm'
        : mime.contains('mpeg')
            ? 'mp3'
            : 'm4a';
    req.files.add(http.MultipartFile.fromBytes(
      'audio',
      bytes,
      filename: 'audio.$ext',
      contentType: _parseMime(mime),
    ));
    final streamed = await req.send().timeout(const Duration(seconds: 20));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) {
      return CommentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao enviar áudio: ${res.statusCode} ${res.body}');
  }

  static MediaType? _parseMime(String mime) {
    final parts = mime.split('/');
    if (parts.length != 2) return null;
    return MediaType(parts[0], parts[1].split(';').first.trim());
  }

  static Future<void> reportComment(int id) async {
    final res = await http
        .post(Uri.parse('$_base/api/comments/$id/report'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Erro ao denunciar: ${res.statusCode}');
    }
  }

  static Future<Map<String, int>> getCommentStats() async {
    final res = await http
        .get(Uri.parse('$_base/api/comments/stats'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'pele': (j['pele'] as num).toInt(),
        'neymar': (j['neymar'] as num).toInt(),
        'chico': (j['chico'] as num).toInt(),
      };
    }
    throw Exception('Erro ao carregar stats: ${res.statusCode}');
  }

  static Future<Map<String, dynamic>> getTopRooms() async {
    final res = await http
        .get(Uri.parse('$_base/api/comments/top-rooms'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar top-rooms: ${res.statusCode}');
  }

  // ── Suggestions ───────────────────────────────────────────────────────────
  static Future<void> postSuggestion({required String body}) async {
    await http
        .post(
          Uri.parse('$_base/api/suggestions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'body': body}),
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> applyPenalty({
    required String sala,
    String? playerName,
    int points = 2,
  }) async {
    await http
        .post(
          Uri.parse('$_base/api/penalty'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sala': sala,
            'points': points,
            if (playerName != null && playerName.isNotEmpty) 'name': playerName,
          }),
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<void> awardPoints({
    required String sala,
    required int points,
    String? playerName,
  }) async {
    await http
        .post(
          Uri.parse('$_base/api/award'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sala': sala,
            'points': points,
            if (playerName != null && playerName.isNotEmpty) 'name': playerName,
          }),
        )
        .timeout(const Duration(seconds: 10));
  }

  static Future<int> likeComment(int id, {required bool increment}) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/comments/$id/like'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'increment': increment}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['likes'] as num).toInt();
    }
    throw Exception('Erro ao curtir: ${res.statusCode}');
  }
}
