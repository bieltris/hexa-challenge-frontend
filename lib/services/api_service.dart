import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/score_model.dart';
import '../models/question_model.dart';
import '../models/comment_model.dart';

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
  }) async {
    await http
        .post(
          Uri.parse('$_base/api/shoot'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'sala': sala, 'scored': scored}),
        )
        .timeout(const Duration(seconds: 10));
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
