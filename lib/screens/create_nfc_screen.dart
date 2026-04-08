import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'dart:typed_data';
import '../services/database_service.dart';
import '../widgets/image_helper.dart';

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

  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<void> _pickImage() async {
    File? selectedImage = await ImageHelper.mostrarSelector(context);
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
      });
    }
  }

  Future<void> _handleCreateTaGo() async {
    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    String tagoId = const Uuid().v4();

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

        // Creamos el mensaje con el ID y el AAR (Android Application Record)
        // El AAR asegura que Android abra SIEMPRE nuestra aplicación
        NdefMessage message = NdefMessage([
          NdefRecord.createText(tagoId),
          NdefRecord.createExternal(
            'android.com',
            'pkg',
            Uint8List.fromList('com.example.tfg'.codeUnits), // Tu package name
          ),
        ]);

        try {
          // 1. Escribimos en el NFC
          statusSubNotifier.value = "Escribiendo ID en etiqueta...";
          await ndef.write(message);
          await NfcManager.instance.stopSession();
          
          // 2. Proceso de subida a Firebase
          statusTitleNotifier.value = "Creando TaGo";
          statusSubNotifier.value = "Subiendo información e imagen...";
          
          // --- ESTO ES LO QUE ESTABA FALLANDO: ASEGURAMOS QUE ESPERA LA SUBIDA ---
          await _saveToFirestore(tagoId, title, description, _image);

          if (mounted) {
            Navigator.pop(context); // Cierra diálogo
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('TaGo creado con éxito')),
            );
            Navigator.pop(context); // Vuelve al mapa
          }
        } catch (e) {
          NfcManager.instance.stopSession(errorMessage: "Error: $e");
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: $e')));
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

    // Aseguramos la subida de imagen y esperamos el resultado
    if (imageFile != null) {
      try {
        imageUrl = await _dbService.subirImagenMarcador(id, imageFile);
        debugPrint("IMAGEN SUBIDA CON ÉXITO: $imageUrl");
      } catch (e) {
        debugPrint("ERROR CRÍTICO AL SUBIR IMAGEN: $e");
      }
    }

    final String? uid = _authService.currentUid;
    final userData = uid != null ? await _dbService.obtenerUsuario(uid) : null;
    
    // Guardamos el documento final. 'imagenUrl' ya no debería ser null si hubo éxito arriba.
    await _dbService.crearMarcador(id, {
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
                  onTap: _pickImage,
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

