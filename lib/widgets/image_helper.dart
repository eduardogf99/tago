import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../theme/app_colors.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> mostrarSelector(BuildContext context) async {
    ImageSource? selectedSource;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.azulOscuro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 5),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.azulClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.doradoClaro),
                title: const Text(
                  'Galería',
                  style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  selectedSource = ImageSource.gallery;
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: AppColors.doradoClaro),
                title: const Text(
                  'Cámara',
                  style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  selectedSource = ImageSource.camera;
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (selectedSource != null) {
      return await _procesarImagen(context, selectedSource!);
    }
    return null;
  }

  static Future<File?> _procesarImagen(BuildContext context, ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (image == null) return null;

    final String targetPath = p.join(
      (await getTemporaryDirectory()).path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (compressedXFile == null) return File(image.path);

    final File file = File(compressedXFile.path);

    final int sizeInBytes = await file.length();
    const int maxSizeInBytes = 10 * 1024 * 1024;

    if (sizeInBytes > maxSizeInBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('La imagen pesa más de 10 MB'),
            backgroundColor: AppColors.rojoSuave,
          ),
        );
      }
      return null;
    }

    return file;
  }
}