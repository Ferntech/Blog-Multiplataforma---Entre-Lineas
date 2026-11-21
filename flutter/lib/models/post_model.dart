import 'book_model.dart';
import 'user_model.dart';

class PostModel {
  final int id;
  final int? authorId;
  final int bookId;
  final String title;
  final String slug;
  final String? excerpt;
  final String content;
  final int rating;
  final String status;
  final String? publishedAt;
  final String createdAt;
  final UserSummaryModel? author;
  final BookModel book;
  final List<TagModel> tags;
  final int voteScore;
  final int userVote;
  final int commentsCount;

  const PostModel({
    required this.id,
    this.authorId,
    required this.bookId,
    required this.title,
    required this.slug,
    this.excerpt,
    required this.content,
    required this.rating,
    required this.status,
    this.publishedAt,
    required this.createdAt,
    this.author,
    required this.book,
    this.tags = const [],
    this.voteScore = 0,
    this.userVote = 0,
    this.commentsCount = 0,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'] as List<dynamic>? ?? const [];

    return PostModel(
      id: (json['id'] as num).toInt(),
      authorId: (json['author_id'] as num?)?.toInt(),
      bookId: (json['book_id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      excerpt: json['excerpt']?.toString(),
      content: json['content']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      status: json['status']?.toString() ?? 'published',
      publishedAt: json['published_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      author: json['author'] is Map<String, dynamic>
          ? UserSummaryModel.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      book: BookModel.fromJson(json['book'] as Map<String, dynamic>),
      tags: rawTags
          .map((t) => TagModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      voteScore: (json['vote_score'] as num?)?.toInt() ?? 0,
      userVote: (json['user_vote'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
    );
  }

  PostModel copyWith({
    int? voteScore,
    int? userVote,
    int? commentsCount,
    UserSummaryModel? author,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      bookId: bookId,
      title: title,
      slug: slug,
      excerpt: excerpt,
      content: content,
      rating: rating,
      status: status,
      publishedAt: publishedAt,
      createdAt: createdAt,
      author: author ?? this.author,
      book: book,
      tags: tags,
      voteScore: voteScore ?? this.voteScore,
      userVote: userVote ?? this.userVote,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
