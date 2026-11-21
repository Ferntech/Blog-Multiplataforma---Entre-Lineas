import 'package:material_ui/material_ui.dart';

import '../models/book_model.dart';
import '../services/book_service.dart';
import '../services/cart_service.dart';
import '../widgets/category_chip.dart';
import 'book_detail_page.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final BookService _bookService = BookService();
  final CartService _cartService = CartService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<BookModel> _books = [];
  List<TagModel> _tags = [];
  String? _selectedTag;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarCatalogo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _bookService.obtenerLibros(
          search: _searchCtrl.text,
          tag: _selectedTag,
        ),
        _bookService.obtenerEtiquetas(),
      ]);
      if (!mounted) return;
      setState(() {
        _books = results[0] as List<BookModel>;
        _tags = results[1] as List<TagModel>;
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

  Future<void> _agregarRapido(BookModel book) async {
    try {
      await _cartService.agregarLibro(bookId: book.id, quantity: 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" agregado al carrito')),
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _cargarCatalogo(),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, autor, editorial o ISBN...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _cargarCatalogo();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _cargarCatalogo,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  isDense: true,
                ),
              ),
            ),
            if (_tags.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        text: 'Todos',
                        selected: _selectedTag == null,
                        onTap: () {
                          setState(() => _selectedTag = null);
                          _cargarCatalogo();
                        },
                      ),
                    ),
                    ..._tags.map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          text: tag.name,
                          selected: _selectedTag == tag.slug,
                          onTap: () {
                            setState(() {
                              _selectedTag =
                                  _selectedTag == tag.slug ? null : tag.slug;
                            });
                            _cargarCatalogo();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _cargarCatalogo,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_books.isEmpty) {
      return const Center(child: Text('No hay libros disponibles.'));
    }

    return RefreshIndicator(
      onRefresh: _cargarCatalogo,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _books.length,
        itemBuilder: (context, index) {
          final book = _books[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BookDetailPage(bookId: book.id),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (book.coverUrl ?? '').isNotEmpty
                          ? Image.network(
                              book.coverUrl!,
                              width: 72,
                              height: 108,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _emptyCover(),
                            )
                          : _emptyCover(),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF08245C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.authorsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\$${book.price.toStringAsFixed(2)} MXN',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                book.isBuyable
                                    ? 'Disponibles: ${book.stock}'
                                    : 'Agotado',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: book.isBuyable
                                      ? Colors.green.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: book.isBuyable
                                    ? () => _agregarRapido(book)
                                    : null,
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 16,
                                ),
                                label: const Text('Agregar'),
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
          );
        },
      ),
    );
  }

  Widget _emptyCover() {
    return Container(
      width: 72,
      height: 108,
      color: const Color(0xFFF3F4F6),
      child: const Icon(Icons.menu_book, color: Colors.grey),
    );
  }
}
