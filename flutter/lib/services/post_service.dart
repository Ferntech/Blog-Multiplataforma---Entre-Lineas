import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/post_model.dart';
import 'session_manager.dart';

typedef VoteResult = Map<String, int>;

class PostService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<PostModel>> obtenerPosts({
    String? search,
    String? tag,
    int? bookId,
  }) async {
    final uid = SessionManager.instance.userId;
    final params = <String, String>{
      if (uid > 0) 'user_id': uid.toString(),
      if (bookId != null) 'book_id': bookId.toString(),
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };

    final uri = Uri.parse('$baseUrl/blog-posts').replace(
      queryParameters: params.isEmpty ? null : params,
    );
    final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception(
        'Error al consultar reseñas (HTTP ${respuesta.statusCode})',
      );
    }

    final List<dynamic> datos = jsonDecode(respuesta.body) as List<dynamic>;
    return datos
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<PostModel> obtenerDetallePost(int postId) async {
    final uid = SessionManager.instance.userId;
    final uri = Uri.parse('$baseUrl/blog-posts/$postId').replace(
      queryParameters: uid > 0 ? {'user_id': uid.toString()} : null,
    );
    final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('No se pudo cargar la reseña');
    }
    return PostModel.fromJson(
      jsonDecode(respuesta.body) as Map<String, dynamic>,
    );
  }

  Future<VoteResult> votarPost({
    required int postId,
    required int voteValue,
  }) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/blog-posts/$postId/vote'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'user_id': uid,
            'vote_value': voteValue,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && data is Map<String, dynamic>) {
      return {
        'vote_score': (data['vote_score'] as num).toInt(),
        'user_vote': (data['user_vote'] as num).toInt(),
        'author_karma': (data['author_karma'] as num?)?.toInt() ?? 0,
      };
    }

    if (data is Map && data['detail'] != null) {
      throw Exception(data['detail'].toString());
    }
    throw Exception('No se pudo registrar el voto');
  }
}
