import 'dart:io';

/// Entity containing comprehensive information about a picked image
class ImageInfoEntity {
  final String path;
  final String filename;
  final String mimeType;
  final int sizeInBytes;
  final double sizeInKb;
  final double sizeInMb;
  final String extension;
  final File file;
  final DateTime? lastModified;
  final int? width;
  final int? height;

  ImageInfoEntity({
    required this.path,
    required this.filename,
    required this.mimeType,
    required this.sizeInBytes,
    required this.extension,
    required this.file,
    this.lastModified,
    this.width,
    this.height,
  }) : sizeInKb = sizeInBytes / 1024,
        sizeInMb = sizeInBytes / (1024 * 1024);

  /// Get formatted file size as a readable string
  String get formattedSize {
    if (sizeInMb >= 1) {
      return '${sizeInMb.toStringAsFixed(2)} MB';
    } else if (sizeInKb >= 1) {
      return '${sizeInKb.toStringAsFixed(2)} KB';
    } else {
      return '$sizeInBytes bytes';
    }
  }

  /// Get image dimensions as a readable string
  String? get dimensions {
    if (width != null && height != null) {
      return '${width}x$height';
    }
    return null;
  }

  /// Check if image is within size limit (in MB)
  bool isWithinSizeLimit(double maxSizeInMb) {
    return sizeInMb <= maxSizeInMb;
  }

  /// Check if image has valid extension
  bool hasValidExtension(List<String> validExtensions) {
    return validExtensions.contains(extension.toLowerCase());
  }

  @override
  String toString() {
    return 'ImageInfoEntity(File Path: $path, filename: $filename, size: $formattedSize, mimeType: $mimeType, dimensions: $dimensions, lastModified: $lastModified, extension: $extension, sizeInBytes: $sizeInBytes, width: $width, height: $height, sizeInKb: $sizeInKb, sizeInMb: $sizeInMb, file: $file)';
  }

  /// Create ImageInfoEntity from XFile
  static Future<ImageInfoEntity> fromFile(File file) async {
    final fileStat = await file.stat();
    final filename = file.path.split('/').last;
    final extension = filename.contains('.') ? filename.split('.').last : '';

    // Determine mime type based on extension
    String mimeType = 'image/jpeg'; // default
    switch (extension.toLowerCase()) {
      case 'png':
        mimeType = 'image/png';
        break;
      case 'jpg':
      case 'jpeg':
        mimeType = 'image/jpeg';
        break;
      case 'gif':
        mimeType = 'image/gif';
        break;
      case 'webp':
        mimeType = 'image/webp';
        break;
      case 'bmp':
        mimeType = 'image/bmp';
        break;
      case 'heic':
      case 'heif':
        mimeType = 'image/heic';
        break;
    }

    return ImageInfoEntity(
      path: file.path,
      filename: filename,
      mimeType: mimeType,
      sizeInBytes: fileStat.size,
      extension: extension,
      file: file,
      lastModified: fileStat.modified,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'filename': filename,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
      'sizeInKb': sizeInKb,
      'sizeInMb': sizeInMb,
      'extension': extension,
      'lastModified': lastModified?.toIso8601String(),
      'width': width,
      'height': height,
      'formattedSize': formattedSize,
      'dimensions': dimensions,
    };
  }
}
