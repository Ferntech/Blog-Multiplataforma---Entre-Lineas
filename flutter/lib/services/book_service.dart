import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

class BookService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<BookModel>> obtenerLibros({String? search, String? tag}) async {
    final params = <String, String>{
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
    };
    final uri = Uri.parse('$baseUrl/books').replace(queryParameters: params);
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Error al cargar el catálogo');
    }
    final List<dynamic> list = jsonDecode(res.body);
    return list
        .map((e) => BookModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BookModel> obtenerDetalleLibro(int bookId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/books/$bookId'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Libro no encontrado');
    }
    return BookModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<List<TagModel>> obtenerEtiquetas() async {
    final res = await http
        .get(Uri.parse('$baseUrl/tags'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return [];
    final List<dynamic> list = jsonDecode(res.body);
    return list
        .map((e) => TagModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
