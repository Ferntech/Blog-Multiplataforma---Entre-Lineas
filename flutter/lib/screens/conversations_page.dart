import 'package:material_ui/material_ui.dart';

import '../models/message_model.dart';
import '../models/user_model.dart';
import '../services/message_service.dart';
import '../services/session_manager.dart';
import '../services/user_service.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final MessageService _messageService = MessageService();
  final UserService _userService = UserService();

  List<ConversationModel> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarConversaciones();
  }

  Future<void> _cargarConversaciones() async {
    setState(() => _loading = true);
    try {
      final data = await _messageService.obtenerConversaciones();
      if (!mounted) return;
      setState(() {
        _conversations = data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _nuevaConversacion() async {
    final currentId = SessionManager.instance.userId;
    List<UserSummaryModel> contactos = [];
    try {
      contactos = await _userService.listarContactos(excludeUserId: currentId);
    } catch (_) {}

    if (!mounted) return;
    final elegido = await showDialog<UserSummaryModel>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo mensaje'),
        content: SizedBox(
          width: 360,
          height: 300,
          child: contactos.isEmpty
              ? const Center(child: Text('No hay otros miembros disponibles.'))
              : ListView.builder(
                  itemCount: contactos.length,
                  itemBuilder: (_, idx) {
                    final u = contactos[idx];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(u.fullName[0].toUpperCase()),
                      ),
                      title: Text(u.fullName),
                      subtitle: Text(u.role.toUpperCase()),
                      onTap: () => Navigator.pop(ctx, u),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );

    if (elegido != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatPage(
            partnerId: elegido.id,
            partnerName: elegido.fullName,
          ),
        ),
      );
      _cargarConversaciones();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaConversacion,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Nuevo chat'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? const Center(
                  child: Text('Aún no tienes conversaciones privadas.'),
                )
              : RefreshIndicator(
                  onRefresh: _cargarConversaciones,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(conv.partnerName[0].toUpperCase()),
                        ),
                        title: Text(
                          conv.partnerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          conv.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: conv.unreadCount > 0
                            ? CircleAvatar(
                                radius: 12,
                                backgroundColor: const Color(0xFFB45309),
                                child: Text(
                                  '${conv.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChatPage(
                                partnerId: conv.partnerId,
                                partnerName: conv.partnerName,
                              ),
                            ),
                          );
                          _cargarConversaciones();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
