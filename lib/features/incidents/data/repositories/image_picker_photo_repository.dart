import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../../domain/repositories/incident_repository.dart';

/// [PhotoRepository] using the camera or gallery.
///
/// Photos are resized and re-encoded as JPEG by the picker itself, which
/// keeps uploads around 200–400 KB (the bucket limit is 2 MB).
class ImagePickerPhotoRepository implements PhotoRepository {
  ImagePickerPhotoRepository([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static const maxSide = 1600.0;
  static const quality = 75;

  @override
  Future<Result<Uint8List?>> pick({required bool fromCamera}) async {
    if (fromCamera) {
      // The app declares CAMERA, so Android requires it to be granted.
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        return Err(
          PermissionFailure(
            'Camera access is needed to take a photo.',
            permanentlyDenied: status.isPermanentlyDenied,
          ),
        );
      }
    }
    try {
      final file = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: maxSide,
        maxHeight: maxSide,
        imageQuality: quality,
      );
      return Success(file == null ? null : await file.readAsBytes());
    } on Object {
      return const Err(UnexpectedFailure('Could not read the photo.'));
    }
  }
}
