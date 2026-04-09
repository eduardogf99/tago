import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> mostrarSelector(BuildContext context) async {
    ImageSource? selectedSource;

    // 1. Preguntamos la fuente (Cámara o Galería)
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  selectedSource = ImageSource.gallery;
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  selectedSource = ImageSource.camera;
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );

    // 2. Si el usuario eligió una fuente, procesamos la imagen
    if (selectedSource != null) {
      return await _procesarImagen(context, selectedSource!);
    }
    return null;
  }

  static Future<File?> _procesarImagen(BuildContext context, ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      // Bajamos un poco la calidad inicial desde el picker
      imageQuality: 85, 
    );
    
    if (image == null) return null;

    // Preparamos la ruta para el archivo comprimido
    final String targetPath = p.join(
      (await getTemporaryDirectory()).path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    // Compresión real: limitamos dimensiones a 1024px y calidad al 70%
    XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    if (compressedXFile == null) return File(image.path);

    final File file = File(compressedXFile.path);
    
    // Validación de tamaño (10 MB)
    final int sizeInBytes = await file.length();
    const int maxSizeInBytes = 10 * 1024 * 1024;

    if (sizeInBytes > maxSizeInBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La imagen pesa más de 10 MB'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }

    return file;
  }
}
