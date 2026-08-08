import 'media_image_entity.dart';

/// Data model for [MediaImageEntity] with JSON parsing.
///
/// Includes [parseImageField] which handles both the legacy plain-URL
/// string format and the new `{ url, alt_text, caption }` object format.
class MediaImageModel extends MediaImageEntity {
  const MediaImageModel({required super.url, super.altText, super.caption});

  factory MediaImageModel.fromJson(Map<String, dynamic> json) {
    return MediaImageModel(
      url: json['url'] as String? ?? '',
      altText: json['alt_text'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
    );
  }

  /// Parses an image field that may be a plain URL string (legacy)
  /// or an object `{ url, alt_text, caption }` (new format).
  static MediaImageModel parseImageField(dynamic value) {
    if (value is String) {
      return MediaImageModel(url: value);
    }
    if (value is Map) {
      return MediaImageModel.fromJson(Map<String, dynamic>.from(value));
    }
    return const MediaImageModel(url: '');
  }

  /// Parses a nullable image field — returns null if value is null.
  static MediaImageModel? parseNullableImageField(dynamic value) {
    if (value == null) return null;
    return parseImageField(value);
  }

  /// Parses a list of image/media objects.
  static List<MediaImageModel> parseList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) {
      if (e is Map) {
        return MediaImageModel.fromJson(Map<String, dynamic>.from(e));
      }
      return const MediaImageModel(url: '');
    }).toList();
  }
}
