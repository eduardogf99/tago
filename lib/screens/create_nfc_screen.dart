import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() {
        _image = File(selectedImage.path);
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

  // Función principal: Escribir NFC y Guardar en DB
  Future<void> _handleCreateTaGo() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa el título y la descripción')),
      );
      return;
    }

    // Generar un ID único para este TaGo
    String tagoId = const Uuid().v4();

    // Mostrar diálogo de escritura NFC
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Acerca la pegatina NFC", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Escribiendo..."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              NfcManager.instance.stopSession();
              Navigator.pop(context);
            },
            child: const Text("Cancelar"),
          )
        ],
      ),
    );

    try {
      // 1. Iniciar sesión NFC para escribir
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) throw "NFC no disponible en este dispositivo";

      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          NfcManager.instance.stopSession(errorMessage: "La pegatina no es escribible");
          return;
        }

        // Crear el mensaje NDEF con el ID del TaGo
        NdefMessage message = NdefMessage([
          NdefRecord.createText(tagoId),
        ]);

        try {
          await ndef.write(message);
          await NfcManager.instance.stopSession();
          
          // 2. Si la escritura fue bien, guardar en Firestore
          await _saveToFirestore(tagoId, title, description);
          
          if (mounted) {
            Navigator.pop(context); // Cerrar el diálogo
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('NFC escrito y TaGo guardado con éxito')),
            );
            Navigator.pop(context); // Volver al mapa
          }
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: "Error al escribir: $e");
        }
      });
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _saveToFirestore(String id, String title, String description) async {
    final userData = await _authService.getUserData();
    
    await FirebaseFirestore.instance.collection('marcadores').doc(id).set({
      'id': id,
      'titulo': title,
      'descripcion': description,
      'lat': widget.position.latitude,
      'lng': widget.position.longitude,
      'creador': userData?.usuario ?? "Desconocido",
      'fechaCreacion': FieldValue.serverTimestamp(),
      'ultimoEscaneo': FieldValue.serverTimestamp(),
      // 'imageUrl': Por ahora sin imagen hasta configurar Storage
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear TaGo (Admin)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Escribe un titulo', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Imagen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Center(
              child: GestureDetector(
                onTap: () => _showPicker(context),
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
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
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(hintText: 'Escribe una breve descripción', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _handleCreateTaGo,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                child: const Text('Crear TaGo', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
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
