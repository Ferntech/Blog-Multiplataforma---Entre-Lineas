import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'session_manager.dart';

class AuthService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  String? checkLogin({
    required String mail,
    required String password,
  }) {
    if (mail.trim().isEmpty || password.isEmpty) {
      return 'Ingresa tu correo y contraseña';
    }
    return null;
  }

  String? checkRegister({
    required String name,
    required String mail,
    required String password,
    required String checkPassword,
  }) {
    if (name.trim().isEmpty ||
        mail.trim().isEmpty ||
        password.isEmpty ||
        checkPassword.isEmpty) {
      return 'Completa todos los campos';
    }
    if (!mail.contains('@')) {
      return 'Ingresa un correo válido';
    }
    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (password != checkPassword) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  Future<UserModel> registerUser({
    required String name,
    required String mail,
    required String password,
    String? address,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'full_name': name.trim(),
            'email': mail.trim().toLowerCase(),
            'password': password,
            'address_line': address,
            'role': 'reader',
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic result =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        result is Map<String, dynamic>) {
      final user = UserModel.fromJson(result);
      SessionManager.instance.setUser(user);
      return user;
    }

    if (result is Map && result['detail'] != null) {
      throw Exception(result['detail'].toString());
    }
    throw Exception('No se pudo registrar el usuario (HTTP ${response.statusCode})');
  }

  Future<UserModel> authenticate({
    required String mail,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'email': mail.trim().toLowerCase(),
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic result =
        response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode == 200 && result is Map<String, dynamic>) {
      final user = UserModel.fromJson(result);
      SessionManager.instance.setUser(user);
      return user;
    }

    if (response.statusCode == 401) {
      throw Exception('Correo o contraseña incorrectos');
    }
    if (result is Map && result['detail'] != null) {
      throw Exception(result['detail'].toString());
    }
    throw Exception('Error al iniciar sesión: HTTP ${response.statusCode}');
  }
}
