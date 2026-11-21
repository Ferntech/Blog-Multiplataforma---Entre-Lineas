import 'package:material_ui/material_ui.dart';

import '../models/comentario_model.dart';
import '../models/post_model.dart';
import '../services/cart_service.dart';
import '../services/comentario_service.dart';
import '../services/post_service.dart';
import '../services/session_manager.dart';
import 'book_detail_page.dart';
import 'chat_page.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  final ComentarioService _comentarioService = ComentarioService();
  final CartService _cartService = CartService();
  final TextEditingController _commentCtrl = TextEditingController();

  late PostModel _post;
  List<ComentarioModel> _comentarios = [];
  GiphyMediaModel? _selectedMedia;
  bool _loadingComments = true;
  bool _sendingComment = false;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _cargarDetalleYComentarios();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDetalleYComentarios() async {
    try {
      final results = await Future.wait([
        _postService.obtenerDetallePost(_post.id),
        _comentarioService.obtenerComentarios(_post.id),
      ]);
      if (!mounted) return;
      setState(() {
        _post = results[0] as PostModel;
        _comentarios = results[1] as List<ComentarioModel>;
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
    }
  }

  Future<void> _emitirVoto(int valor) async {
    if (_voting) return;
    final nuevoValor = (_post.userVote == valor) ? 0 : valor;
    setState(() => _voting = true);

    try {
      final res = await _postService.votarPost(
        postId: _post.id,
        voteValue: nuevoValor,
      );
      if (!mounted) return;
      setState(() {
        _post = _post.copyWith(
          voteScore: res['vote_score'] ?? _post.voteScore,
          userVote: res['user_vote'] ?? nuevoValor,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  Future<void> _publicarComentario() async {
    final texto = _commentCtrl.text.trim();
    if (texto.isEmpty && _selectedMedia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un comentario o selecciona un GIF/Sticker'),
        ),
      );
      return;
    }

    setState(() => _sendingComment = true);
    try {
      final nuevo = await _comentarioService.agregarComentario(
        postId: _post.id,
        content: texto,
        media: _selectedMedia,
      );
      if (!mounted) return;
      setState(() {
        _comentarios.insert(0, nuevo);
        _post = _post.copyWith(commentsCount: _comentarios.length);
        _commentCtrl.clear();
        _selectedMedia = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _abrirSelectorGiphy() async {
    final elegido = await showModalBottomSheet<GiphyMediaModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _GiphyPickerSheet(),
    );
    if (elegido != null && mounted) {
      setState(() => _selectedMedia = elegido);
    }
  }

  Future<void> _agregarLibroAlCarrito() async {
    try {
      await _cartService.agregarLibro(bookId: _post.book.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${_post.book.title}" agregado al carrito'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = SessionManager.instance.userId;
    final esAutorPropio =
        _post.authorId != null && _post.authorId == currentUserId;

    return Scaffold(
      appBar: AppBar(title: const Text('Reseña Literaria')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_post.tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _post.tags
                        .map(
                          (t) => Chip(
                            label: Text('#${t.name}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                const SizedBox(height: 8),
                Text(
                  _post.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08245C),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (i) => Icon(
                        i < _post.rating
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFD97706),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_post.rating}/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_post.author != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          _post.author!.fullName.isNotEmpty
                              ? _post.author!.fullName[0].toUpperCase()
                              : 'A',
                        ),
                      ),
                      title: Text(_post.author!.fullName),
                      subtitle: Text(
                        '${_post.author!.role.toUpperCase()} • ${_post.author!.karma} pts de reputación',
                      ),
                      trailing: (!esAutorPropio)
                          ? OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ChatPage(
                                      partnerId: _post.author!.id,
                                      partnerName: _post.author!.fullName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.mail_outline, size: 18),
                              label: const Text('Mensaje'),
                            )
                          : null,
                    ),
                  ),
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFFFFFBEB),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: (_post.book.coverUrl ?? '').isNotEmpty
                              ? Image.network(
                                  _post.book.coverUrl!,
                                  width: 60,
                                  height: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.book, size: 48),
                                )
                              : const Icon(Icons.book, size: 48),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OBRA RESEÑADA',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                              Text(
                                _post.book.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_post.book.price.toStringAsFixed(2)} MXN • Stock: ${_post.book.stock}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute<void>(
                                          builder: (_) => BookDetailPage(
                                            bookId: _post.book.id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Ver ficha'),
                                  ),
                                  FilledButton.icon(
                                    onPressed: _post.book.isBuyable
                                        ? _agregarLibroAlCarrito
                                        : null,
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 16,
                                    ),
                                    label: Text(
                                      _post.book.isBuyable
                                          ? 'Comprar'
                                          : 'Agotado',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _post.content,
                  style: const TextStyle(fontSize: 16, height: 1.65),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '¿Te resultó útil esta reseña?',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: esAutorPropio
                              ? 'No puedes votar tu propia reseña'
                              : 'Voto positivo',
                          onPressed: esAutorPropio ? null : () => _emitirVoto(1),
                          icon: Icon(
                            _post.userVote == 1
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            color: _post.userVote == 1
                                ? const Color(0xFFB45309)
                                : null,
                          ),
                        ),
                        Text(
                          '${_post.voteScore}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          tooltip: esAutorPropio
                              ? 'No puedes votar tu propia reseña'
                              : 'Voto negativo',
                          onPressed:
                              esAutorPropio ? null : () => _emitirVoto(-1),
                          icon: Icon(
                            _post.userVote == -1
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            color: _post.userVote == -1 ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 36),
                Text(
                  'Comentarios (${_comentarios.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF08245C),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _commentCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Comparte tu opinión sobre esta reseña...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (_selectedMedia != null) ...[
                          const SizedBox(height: 10),
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _selectedMedia!.mediaUrl,
                                  height: 130,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black87,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    onPressed: () =>
                                        setState(() => _selectedMedia = null),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: _abrirSelectorGiphy,
                              icon: const Icon(Icons.gif_box_outlined),
                              label: const Text('GIF / Sticker'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              onPressed: _sendingComment
                                  ? null
                                  : _publicarComentario,
                              icon: const Icon(Icons.send, size: 16),
                              label: Text(
                                _sendingComment ? 'Enviando...' : 'Comentar',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_loadingComments)
                  const Center(child: CircularProgressIndicator())
                else if (_comentarios.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Sé el primero en comentar esta reseña.'),
                    ),
                  )
                else
                  ..._comentarios.map(
                    (c) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  child: Text(
                                    c.user.fullName.isNotEmpty
                                        ? c.user.fullName[0].toUpperCase()
                                        : 'U',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.user.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  c.createdAt.split('T').first,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            if (c.content.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(c.content),
                            ],
                            if (c.media.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  c.media.first.mediaUrl,
                                  height: 150,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Text('[GIF no disponible]'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GiphyPickerSheet extends StatefulWidget {
  const _GiphyPickerSheet();

  @override
  State<_GiphyPickerSheet> createState() => _GiphyPickerSheetState();
}

class _GiphyPickerSheetState extends State<_GiphyPickerSheet> {
  final ComentarioService _service = ComentarioService();
  final TextEditingController _queryCtrl = TextEditingController();
  String _type = 'gif';
  List<GiphyMediaModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buscar();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.buscarGiphy(
        query: _queryCtrl.text,
        type: _type,
      );
      if (!mounted) return;
      setState(() {
        _items = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: 430,
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Seleccionar desde Giphy',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ChoiceChip(
                  label: const Text('GIFs'),
                  selected: _type == 'gif',
                  onSelected: (_) {
                    setState(() => _type = 'gif');
                    _buscar();
                  },
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Stickers'),
                  selected: _type == 'sticker',
                  onSelected: (_) {
                    setState(() => _type = 'sticker');
                    _buscar();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _queryCtrl,
              onSubmitted: (_) => _buscar(),
              decoration: InputDecoration(
                hintText: 'Buscar reacción (ej. libros, lectura, aplauso)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _buscar,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, textAlign: TextAlign.center))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return InkWell(
                              onTap: () => Navigator.pop(context, item),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.previewUrl ?? item.mediaUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
