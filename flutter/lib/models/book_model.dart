class AuthorModel {
  final int id;
  final String name;
  final String slug;
  final String? nationality;

  const AuthorModel({
    required this.id,
    required this.name,
    required this.slug,
    this.nationality,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      nationality: json['nationality']?.toString(),
    );
  }
}

class TagModel {
  final int id;
  final String name;
  final String slug;

  const TagModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class BookModel {
  final int id;
  final String title;
  final String? subtitle;
  final String slug;
  final String? isbn10;
  final String isbn13;
  final String? publisher;
  final int? publishedYear;
  final int? pageCount;
  final String language;
  final String? coverUrl;
  final String? synopsis;
  final double price;
  final int stock;
  final String status;
  final List<AuthorModel> authors;
  final List<TagModel> tags;

  const BookModel({
    required this.id,
    required this.title,
    this.subtitle,
    required this.slug,
    this.isbn10,
    required this.isbn13,
    this.publisher,
    this.publishedYear,
    this.pageCount,
    this.language = 'es',
    this.coverUrl,
    this.synopsis,
    required this.price,
    required this.stock,
    required this.status,
    this.authors = const [],
    this.tags = const [],
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    final rawAuthors = json['authors'] as List<dynamic>? ?? const [];
    final rawTags = json['tags'] as List<dynamic>? ?? const [];

    return BookModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      slug: json['slug']?.toString() ?? '',
      isbn10: json['isbn_10']?.toString(),
      isbn13: json['isbn_13']?.toString() ?? '',
      publisher: json['publisher']?.toString(),
      publishedYear: (json['published_year'] as num?)?.toInt(),
      pageCount: (json['page_count'] as num?)?.toInt(),
      language: json['language']?.toString() ?? 'es',
      coverUrl: json['cover_url']?.toString(),
      synopsis: json['synopsis']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'active',
      authors: rawAuthors
          .map((a) => AuthorModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      tags: rawTags
          .map((t) => TagModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  String get authorsLabel => authors.isEmpty
      ? 'Autor no especificado'
      : authors.map((a) => a.name).join(', ');

  bool get isBuyable => status == 'active' && stock > 0;
}
