import 'dart:io';
import '../../entities/image_info_entity.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _picker;

  ImagePickerService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  /// Pick a single image and return comprehensive image info
  Future<ImageInfoEntity?> pickSingleImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      final file = File(image.path);
      return await ImageInfoEntity.fromFile(file);
    } catch (e) {
      return null;
    }
  }

  /// Pick multiple images and return comprehensive image info for each
  Future<List<ImageInfoEntity>> pickMultipleImages({
    int imageQuality = 80,
    int? maxImages,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
      );

      final selectedImages = maxImages != null && images.length > maxImages
          ? images.take(maxImages).toList()
          : images;

      final List<ImageInfoEntity> imageInfoList = [];

      for (final xFile in selectedImages) {
        final file = File(xFile.path);
        final imageInfo = await ImageInfoEntity.fromFile(file);
        imageInfoList.add(imageInfo);
      }

      return imageInfoList;
    } catch (_) {
      return [];
    }
  }

  /// Pick a single image from camera
  Future<ImageInfoEntity?> pickImageFromCamera({int imageQuality = 80}) async {
    return pickSingleImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }

  /// Pick a single image from gallery
  Future<ImageInfoEntity?> pickImageFromGallery({int imageQuality = 80}) async {
    return pickSingleImage(
      source: ImageSource.gallery,
      imageQuality: imageQuality,
    );
  }

  /// Legacy method - Get path only (for backward compatibility)
  Future<String?> pickSingleImagePath({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
  }) async {
    final imageInfo = await pickSingleImage(
      source: source,
      imageQuality: imageQuality,
    );
    return imageInfo?.path;
  }

  /// Legacy method - Get File only (for backward compatibility)
  Future<File?> pickSingleImageFile({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 80,
  }) async {
    final imageInfo = await pickSingleImage(
      source: source,
      imageQuality: imageQuality,
    );
    return imageInfo?.file;
  }
}
