import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/order_model.dart';
import 'session_manager.dart';

class OrderService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<OrderModel>> obtenerOrdenes() async {
    final uid = SessionManager.instance.userId;
    final res = await http
        .get(Uri.parse('$baseUrl/users/$uid/orders'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Error al consultar pedidos');
    }
    final List<dynamic> list = jsonDecode(res.body);
    return list
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
