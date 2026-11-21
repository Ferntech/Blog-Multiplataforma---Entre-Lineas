import 'package:material_ui/material_ui.dart';

import '../models/book_model.dart';
import '../models/post_model.dart';
import '../services/book_service.dart';
import '../services/post_service.dart';
import '../widgets/category_chip.dart';
import '../widgets/post_card.dart';
import 'post_detail_page.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final PostService _postService = PostService();
  final BookService _bookService = BookService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<PostModel> _posts = [];
  List<TagModel> _tags = [];
  String? _selectedTagSlug;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarInicial();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarInicial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _postService.obtenerPosts(
          search: _searchCtrl.text,
          tag: _selectedTagSlug,
        ),
        _bookService.obtenerEtiquetas(),
      ]);
      if (!mounted) return;
      setState(() {
        _posts = results[0] as List<PostModel>;
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

  Future<void> _filtrarPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _postService.obtenerPosts(
        search: _searchCtrl.text,
        tag: _selectedTagSlug,
      );
      if (!mounted) return;
      setState(() {
        _posts = data;
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
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _filtrarPosts(),
                decoration: InputDecoration(
                  hintText: 'Buscar reseña, libro o ISBN...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filtrarPosts();
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _filtrarPosts,
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
                        text: 'Todas',
                        selected: _selectedTagSlug == null,
                        onTap: () {
                          setState(() => _selectedTagSlug = null);
                          _filtrarPosts();
                        },
                      ),
                    ),
                    ..._tags.map(
                      (tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          text: '#${tag.name}',
                          selected: _selectedTagSlug == tag.slug,
                          onTap: () {
                            setState(() {
                              _selectedTagSlug = _selectedTagSlug == tag.slug
                                  ? null
                                  : tag.slug;
                            });
                            _filtrarPosts();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 46, color: Colors.grey),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _filtrarPosts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Text('No se encontraron reseñas con esos criterios.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _filtrarPosts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return PostCard(
            post: post,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PostDetailPage(post: post),
                ),
              );
              _filtrarPosts();
            },
          );
        },
      ),
    );
  }
}
