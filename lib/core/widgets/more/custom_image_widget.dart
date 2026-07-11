import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:agrisenseaiapp/core/widgets/loaders/custom_loader.dart';

/// A unified image widget that handles all image sources behind one interface.
///
/// Automatically detects the image type from the [image] string and renders
/// the appropriate widget:
/// - 🌐 Network URL (`http...`) → [CachedNetworkImage] with disk + memory cache
/// - 🖼 Asset path (`assets/...`) → [Image.asset] or [SvgPicture.asset]
/// - 📂 File path → [Image.file] or [SvgPicture.file]
///
/// ---
///
/// ## How caching works
///
/// Network images go through two caches:
///
/// **Disk cache** — the compressed image file (JPEG/PNG) is saved to device
/// storage after the first download. Subsequent requests read from disk instead
/// of the network, making loads fast and offline-friendly.
///
/// **Memory (RAM) cache** — before Flutter can display an image it must decode
/// the compressed file into raw pixels (4 bytes per pixel). This decoded bitmap
/// lives in RAM. A 2000×1500 JPEG that is only 200 KB on disk decodes to
/// ~12 MB in RAM.
///
/// ## Why memCacheWidth / memCacheHeight matter
///
/// By default the full original resolution is decoded into memory, even if the
/// widget only displays it at 64×64 pixels. [memCacheWidth] and
/// [memCacheHeight] cap the resolution at which the image is decoded and
/// stored in the memory cache — drastically reducing RAM usage with zero
/// visible quality loss.
///
/// **Rule of thumb:** set [memCacheWidth] to `display width in logical pixels × 2`
/// (the ×2 covers standard retina/HDPI screens).
///
/// ```
/// Avatar displayed at 40px  → memCacheWidth: 80–120
/// Thumbnail at 64px          → memCacheWidth: 128
/// Recipe card at 260px       → memCacheWidth: 520
/// Full-screen mobile (~390px) → memCacheWidth: 800
/// ```
///
/// Only set [memCacheHeight] when the container height is more restrictive
/// than the width (e.g., a wide banner that is only 80px tall). In most cases
/// [memCacheWidth] alone is enough — Flutter calculates height proportionally.
class CustomImage extends StatelessWidget {
  /// The image source. Accepts:
  /// - A network URL starting with `http`
  /// - An asset path starting with `assets/`
  /// - An absolute file path
  /// SVG files are detected automatically via the `.svg` extension.
  final String image;

  final double? height;
  final double? width;
  final BoxFit fit;
  final Color? color;

  /// Widget shown while the network image is downloading.
  /// Defaults to a centered [CustomLoader].
  final Widget? placeholder;

  /// Widget shown when the image fails to load or the source is empty.
  /// Defaults to [Icons.broken_image].
  final Widget? errorWidget;

  /// Caps the width at which a network image is decoded and held in RAM.
  /// Set to `display width (logical px) × 2`. See class-level docs for detail.
  final int? memCacheWidth;

  /// Caps the height at which a network image is decoded and held in RAM.
  /// Only needed when height is more restrictive than width. See class docs.
  final int? memCacheHeight;

  const CustomImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.color,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  bool get _isNetwork => image.startsWith('http');
  bool get _isSvg => image.toLowerCase().endsWith('.svg');
  bool get _isAsset => image.startsWith('assets/');
  bool get _isFile => File(image).existsSync();

  @override
  Widget build(BuildContext context) {
    if (image.isEmpty) {
      return _error();
    }

    /// 🌐 Network SVG
    if (_isNetwork && _isSvg) {
      return SvgPicture.network(
        image,
        height: height,
        width: width,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => _placeholder(),
      );
    }

    /// 🌐 Network Image
    if (_isNetwork) {
      return CachedNetworkImage(
        imageUrl: image,
        height: height,
        width: width,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (_, _) => _placeholder(),
        errorWidget: (_, _, _) => _error(),
      );
    }

    /// 🖼 Asset SVG
    if (_isAsset && _isSvg) {
      return SvgPicture.asset(
        image,
        height: height,
        width: width,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      );
    }

    /// 🖼 Asset Image
    if (_isAsset) {
      return Image.asset(
        image,
        height: height,
        width: width,
        fit: fit,
        color: color,
      );
    }

    /// 📂 File SVG
    if (_isFile && _isSvg) {
      return SvgPicture.file(
        File(image),
        height: height,
        width: width,
        fit: fit,
      );
    }

    /// 📂 File Image
    if (_isFile) {
      return Image.file(File(image), height: height, width: width, fit: fit);
    }

    return _error();
  }

  Widget _placeholder() {
    return placeholder ?? Center(child: CustomLoader(size: 20));
  }

  Widget _error() {
    return errorWidget ??
        const Icon(Icons.broken_image, size: 40, color: Colors.grey);
  }
}
