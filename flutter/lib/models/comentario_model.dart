import 'user_model.dart';

class GiphyMediaModel {
  final String mediaType;
  final String giphyId;
  final String mediaUrl;
  final String? previewUrl;
  final int? width;
  final int? height;
  final String? altText;

  const GiphyMediaModel({
    required this.mediaType,
    required this.giphyId,
    required this.mediaUrl,
    this.previewUrl,
    this.width,
    this.height,
    this.altText,
  });

  factory GiphyMediaModel.fromJson(Map<String, dynamic> json) {
    return GiphyMediaModel(
      mediaType: json['media_type']?.toString() ?? 'gif',
      giphyId: json['giphy_id']?.toString() ?? '',
      mediaUrl: json['media_url']?.toString() ?? '',
      previewUrl: json['preview_url']?.toString(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      altText: json['alt_text']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'media_type': mediaType,
      'giphy_id': giphyId,
      'media_url': mediaUrl,
      'preview_url': previewUrl,
      'width': width,
      'height': height,
      'alt_text': altText,
    };
  }
}

class ComentarioModel {
  final int id;
  final int postId;
  final int userId;
  final String content;
  final String status;
  final String createdAt;
  final UserSummaryModel user;
  final List<GiphyMediaModel> media;

  const ComentarioModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.user,
    this.media = const [],
  });

  factory ComentarioModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List<dynamic>? ?? const [];
    return ComentarioModel(
      id: (json['id'] as num).toInt(),
      postId: (json['post_id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? 'visible',
      createdAt: json['created_at']?.toString() ?? '',
      user: UserSummaryModel.fromJson(json['user'] as Map<String, dynamic>),
      media: rawMedia
          .map((m) => GiphyMediaModel.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
