import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

abstract interface class PhotoPicker {
  /// Caminho temporário da foto escolhida, ou `null` se cancelar.
  Future<String?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  final _picker = ImagePicker();

  @override
  Future<String?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    return file?.path;
  }
}
