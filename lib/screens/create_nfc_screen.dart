import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import '../services/auth_service.dart';

class CreateNfcScreen extends StatefulWidget {
  final LatLng position;

  const CreateNfcScreen({super.key, required this.position});

  @override
  State<CreateNfcScreen> createState() => _CreateNfcScreenState();
}

class _CreateNfcScreenState extends State<CreateNfcScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      final File file = File(selectedImage.path);
      final int sizeInBytes = await file.length();
      const int maxSizeInBytes = 10 * 1024 * 1024; // 10 MB

      if (sizeInBytes > maxSizeInBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La imagen pesa mas de 10 MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _image = file;
      });
    }
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCreateTaGo() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    String tagoId = const Uuid().v4();

    // Notificadores para actualizar el texto del diálogo dinámicamente
    final ValueNotifier<String> statusTitleNotifier = ValueNotifier<String>("Acerca la pegatina NFC");
    final ValueNotifier<String> statusSubNotifier = ValueNotifier<String>("Esperando etiqueta...");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            ValueListenableBuilder<String>(
              valueListenable: statusTitleNotifier,
              builder: (context, value, _) => Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: statusSubNotifier,
              builder: (context, value, _) => Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) throw "NFC no disponible";

      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          NfcManager.instance.stopSession(errorMessage: "No escribible");
          return;
        }

        NdefMessage message = NdefMessage([NdefRecord.createText(tagoId)]);

        try {
          // 1. Escribir en el NFC
          statusSubNotifier.value = "Escribiendo ID en etiqueta...";
          await ndef.write(message);
          await NfcManager.instance.stopSession();
          
          // 2. Cambiar texto cuando empieza la subida a Firebase
          statusTitleNotifier.value = "Creando TaGo";
          statusSubNotifier.value = "Subiendo información e imagen...";
          
          // Guardamos en Firestore (esto incluye la subida a Storage)
          await _saveToFirestore(tagoId, title, description, _image);

          if (mounted) {
            Navigator.pop(context); // Cierra el diálogo de progreso
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('TaGo creado con éxito')),
            );
            Navigator.pop(context); // Vuelve al mapa
          }
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: "Error: $e");
          if (mounted) {
            Navigator.pop(context); // Cierra el diálogo si hay error
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error NFC: $e')));
    }
  }

  Future<void> _saveToFirestore(String id, String title, String description, File? imageFile) async {
    String? imageUrl;

    if (imageFile != null) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('marcadores_images')
            .child('$id.jpg');
        
        final SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = storageRef.putFile(imageFile, metadata);
        
        TaskSnapshot snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        debugPrint("ERROR CRÍTICO AL SUBIR IMAGEN: $e");
        // Se podría lanzar error aquí si quieres detener el proceso si la imagen falla
      }
    }

    final userData = await _authService.getUserData();
    
    await FirebaseFirestore.instance.collection('marcadores').doc(id).set({
      'id': id,
      'titulo': title,
      'descripcion': description,
      'imagenUrl': imageUrl,
      'lat': widget.position.latitude,
      'lng': widget.position.longitude,
      'creador': userData?.usuario ?? "Desconocido",
      'fechaCreacion': FieldValue.serverTimestamp(),
      'ultimoEscaneo': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear TaGo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación: ${widget.position.latitude.toStringAsFixed(4)}, ${widget.position.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              const Text('Título del TaGo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, introduce un título';
                  return null;
                },
                decoration: const InputDecoration(hintText: 'Escribe un titulo', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              const Text('Imagen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: () => _showPicker(context),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(120),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(120),
                            child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Pulsa para añadir una imagen', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Por favor, introduce una descripción';
                  return null;
                },
                decoration: const InputDecoration(hintText: 'Escribe una breve descripción', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _handleCreateTaGo();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Crear TaGo', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
