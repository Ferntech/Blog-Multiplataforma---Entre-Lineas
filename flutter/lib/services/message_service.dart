import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/message_model.dart';
import 'session_manager.dart';

class MessageService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<List<ConversationModel>> obtenerConversaciones() async {
    final uid = SessionManager.instance.userId;
    final res = await http
        .get(Uri.parse('$baseUrl/users/$uid/conversations'))
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Error al cargar conversaciones');
    }
    final List<dynamic> list = jsonDecode(res.body);
    final convs = list
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalUnread = convs.fold(0, (sum, c) => sum + c.unreadCount);
    SessionManager.instance.updateBadges(unreadMessages: totalUnread);
    return convs;
  }

  Future<List<PrivateMessageModel>> obtenerHilo(int partnerId) async {
    final uid = SessionManager.instance.userId;
    final uri = Uri.parse('$baseUrl/users/$uid/messages')
        .replace(queryParameters: {'with_user_id': partnerId.toString()});
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw Exception('Error al cargar los mensajes');
    }
    final List<dynamic> list = jsonDecode(res.body);
    return list
        .map((e) => PrivateMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PrivateMessageModel> enviarMensaje({
    required int recipientId,
    required String content,
  }) async {
    final uid = SessionManager.instance.userId;
    final res = await http
        .post(
          Uri.parse('$baseUrl/messages'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'sender_id': uid,
            'recipient_id': recipientId,
            'content': content.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final dynamic data = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    if (res.statusCode == 201 && data is Map<String, dynamic>) {
      return PrivateMessageModel.fromJson(data);
    }
    throw Exception(
      (data is Map && data['detail'] != null)
          ? data['detail'].toString()
          : 'No se pudo enviar el mensaje',
    );
  }
}
