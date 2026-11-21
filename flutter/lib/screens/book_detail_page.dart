import 'package:material_ui/material_ui.dart';

import '../models/book_model.dart';
import '../models/post_model.dart';
import '../services/book_service.dart';
import '../services/cart_service.dart';
import '../services/post_service.dart';
import 'post_detail_page.dart';

class BookDetailPage extends StatefulWidget {
  final int bookId;

  const BookDetailPage({super.key, required this.bookId});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  final BookService _bookService = BookService();
  final PostService _postService = PostService();
  final CartService _cartService = CartService();

  BookModel? _book;
  List<PostModel> _relatedPosts = [];
  int _quantity = 1;
  bool _loading = true;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final results = await Future.wait([
        _bookService.obtenerDetalleLibro(widget.bookId),
        _postService.obtenerPosts(bookId: widget.bookId),
      ]);
      if (!mounted) return;
      setState(() {
        _book = results[0] as BookModel;
        _relatedPosts = results[1] as List<PostModel>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _agregarAlCarrito() async {
    if (_book == null) return;
    setState(() => _adding = true);
    try {
      await _cartService.agregarLibro(bookId: _book!.id, quantity: _quantity);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se agregaron $_quantity ejemplar(es) al carrito'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ficha del Libro')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _book == null
              ? const Center(child: Text('No se encontró el libro.'))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: (_book!.coverUrl ?? '').isNotEmpty
                                    ? Image.network(
                                        _book!.coverUrl!,
                                        width: 130,
                                        height: 195,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        width: 130,
                                        height: 195,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.book, size: 54),
                                      ),
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _book!.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF08245C),
                                      ),
                                    ),
                                    if (_book!.subtitle != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        _book!.subtitle!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Por ${_book!.authorsLabel}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      '\$${_book!.price.toStringAsFixed(2)} MXN',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB45309),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text('ISBN-13: ${_book!.isbn13}'),
                                    if (_book!.publisher != null)
                                      Text('Editorial: ${_book!.publisher}'),
                                    if (_book!.publishedYear != null)
                                      Text('Año: ${_book!.publishedYear}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_book!.isBuyable)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    IconButton(
                                      onPressed: _quantity > 1
                                          ? () => setState(() => _quantity--)
                                          : null,
                                      icon: const Icon(Icons.remove_circle_outline),
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _quantity < _book!.stock
                                          ? () => setState(() => _quantity++)
                                          : null,
                                      icon: const Icon(Icons.add_circle_outline),
                                    ),
                                    const Spacer(),
                                    FilledButton.icon(
                                      onPressed:
                                          _adding ? null : _agregarAlCarrito,
                                      icon: const Icon(Icons.shopping_cart),
                                      label: Text(
                                        _adding
                                            ? 'Agregando...'
                                            : 'Agregar al carrito',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 18),
                          const Text(
                            'Sinopsis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _book!.synopsis ??
                                'Sin sinopsis registrada para esta edición.',
                            style: const TextStyle(fontSize: 15, height: 1.6),
                          ),
                          if (_relatedPosts.isNotEmpty) ...[
                            const Divider(height: 36),
                            const Text(
                              'Reseñas sobre esta obra',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._relatedPosts.map(
                              (p) => Card(
                                child: ListTile(
                                  title: Text(p.title),
                                  subtitle: Text(
                                    'Calificación: ${p.rating}/5 • ${p.voteScore} votos',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            PostDetailPage(post: p),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
