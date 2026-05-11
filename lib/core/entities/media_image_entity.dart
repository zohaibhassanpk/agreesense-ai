/// A backend media image reference with URL, alt text, and caption.
///
/// Used across recipes, cookbooks, and any API response that returns
/// the `{ url, alt_text, caption }` image object shape.
class MediaImageEntity {
  final String url;
  final String altText;
  final String caption;

  const MediaImageEntity({
    required this.url,
    this.altText = '',
    this.caption = '',
  });

  const MediaImageEntity.empty()
      : url = '',
        altText = '',
        caption = '';

  bool get isEmpty => url.isEmpty;
  bool get isNotEmpty => url.isNotEmpty;
}
