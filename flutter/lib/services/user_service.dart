import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'session_manager.dart';

class UserService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<UserModel> obtenerPerfil(int userId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/users/$userId'))
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      final user = UserModel.fromJson(data);
      if (SessionManager.instance.userId == user.id) {
        SessionManager.instance.setUser(user);
      }
      return user;
    }
    throw Exception(_mensajeError(response));
  }

  Future<UserModel> actualizarPerfil({
    required int userId,
    required String fullName,
    required String email,
    String? avatarUrl,
    String? bio,
    String? phone,
    String? addressLine,
    String? city,
    String? state,
    String? postalCode,
    String country = 'México',
  }) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl/users/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'full_name': fullName.trim(),
            'email': email.trim().toLowerCase(),
            'avatar_url': (avatarUrl ?? '').trim().isEmpty ? null : avatarUrl!.trim(),
            'bio': (bio ?? '').trim().isEmpty ? null : bio!.trim(),
            'phone': (phone ?? '').trim().isEmpty ? null : phone!.trim(),
            'address_line': (addressLine ?? '').trim().isEmpty ? null : addressLine!.trim(),
            'city': (city ?? '').trim().isEmpty ? null : city!.trim(),
            'state': (state ?? '').trim().isEmpty ? null : state!.trim(),
            'postal_code': (postalCode ?? '').trim().isEmpty ? null : postalCode!.trim(),
            'country': country.trim().isEmpty ? 'México' : country.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic data =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      final updated = UserModel.fromJson(data);
      SessionManager.instance.setUser(updated);
      return updated;
    }
    throw Exception(_mensajeError(response));
  }

  Future<List<UserSummaryModel>> listarContactos({
    required int excludeUserId,
    String? search,
  }) async {
    final params = <String, String>{
      'exclude_user_id': excludeUserId.toString(),
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final uri = Uri.parse('$baseUrl/users/contacts').replace(queryParameters: params);
    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(_mensajeError(response));
    }
    final List<dynamic> list = jsonDecode(response.body);
    return list
        .map((e) => UserSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _mensajeError(http.Response respuesta) {
    try {
      final datos = jsonDecode(respuesta.body);
      if (datos is Map && datos['detail'] != null) {
        return datos['detail'].toString();
      }
    } catch (_) {}
    return 'Error HTTP ${respuesta.statusCode}';
  }
}
