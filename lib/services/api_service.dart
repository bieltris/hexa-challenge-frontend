import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/score_model.dart';
import '../models/question_model.dart';
import '../models/comment_model.dart';
import '../models/player_score_model.dart';

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
            if (playerName != null && playerName.isNotEmpty)
              'name': playerName,
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
  }) async {
    final res = await http
        .post(
          Uri.parse('$_base/api/comments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'sala': sala, 'body': body}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 201) {
      return CommentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao postar comentário: ${res.statusCode}');
  }

  static Future<Map<String, int>> getCommentStats() async {
    final res = await http
        .get(Uri.parse('$_base/api/comments/stats'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return {
        'pele':   (j['pele']   as num).toInt(),
        'neymar': (j['neymar'] as num).toInt(),
        'chico':  (j['chico']  as num).toInt(),
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
            if (playerName != null && playerName.isNotEmpty)
              'name': playerName,
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
            if (playerName != null && playerName.isNotEmpty)
              'name': playerName,
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
