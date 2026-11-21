import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/comentario_model.dart';
import 'session_manager.dart';

class ComentarioService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<ComentarioModel>> obtenerComentarios(int postId) async {
    final respuesta = await http
        .get(Uri.parse('$baseUrl/blog-posts/$postId/comments'))
        .timeout(const Duration(seconds: 10));

    if (respuesta.statusCode != 200) {
      throw Exception('Error al consultar comentarios');
    }

    final List<dynamic> datos = jsonDecode(respuesta.body);
    return datos
        .map((json) => ComentarioModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ComentarioModel> agregarComentario({
    required int postId,
    required String content,
    GiphyMediaModel? media,
  }) async {
    final uid = SessionManager.instance.userId;
    final respuesta = await http
        .post(
          Uri.parse('$baseUrl/blog-posts/$postId/comments'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'user_id': uid,
            'content': content.trim(),
            'media': media?.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 201 && data is Map<String, dynamic>) {
      return ComentarioModel.fromJson(data);
    }

    if (data is Map && data['detail'] != null) {
      throw Exception(data['detail'].toString());
    }
    throw Exception('No se pudo publicar el comentario');
  }

  Future<List<GiphyMediaModel>> buscarGiphy({
    String query = '',
    String type = 'gif',
  }) async {
    final uri = Uri.parse('$baseUrl/giphy/search').replace(
      queryParameters: {
        'q': query.trim(),
        'type': type,
      },
    );
    final respuesta = await http.get(uri).timeout(const Duration(seconds: 10));

    final dynamic data =
        respuesta.body.isNotEmpty ? jsonDecode(respuesta.body) : null;
    if (respuesta.statusCode == 200 && data is List) {
      return data
          .map((item) => GiphyMediaModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data is Map && data['detail'] != null) {
      throw Exception(data['detail'].toString());
    }
    throw Exception('No se pudo consultar Giphy');
  }
}
