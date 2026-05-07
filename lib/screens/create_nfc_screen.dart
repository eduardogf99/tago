import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'dart:typed_data';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
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
  final TextEditingController _hintController = TextEditingController();
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

  Future<Map<String, String>> _getLocationData(double lat, double lon) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon');
      final response = await http.get(url, headers: {
        'User-Agent': 'TaGo_App_TFG'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          return {
            'pais': address['country'] ?? "Desconocido",
            'codigo_pais': address['country_code'] ?? "Desconocido",
            'comunidad': address['state'] ?? "Desconocido",
            'provincia': address['province'] ?? address['county'] ?? "Desconocido",
            'municipio': address['city'] ?? address['town'] ?? address['village'] ?? "Desconocido",
          };
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo datos de ubicación: $e");
    }
    return {'pais': "Desconocido", 'codigo_pais': "Desconocido", 'comunidad': "Desconocido", 'provincia': "Desconocido", 'municipio': "Desconocido"};
  }

  Future<void> _processTagoCreation(String tagoId, String title, String description, String hint) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Sincronizando con el servidor...", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Subiendo información e imagen...", style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      await _saveToBackend(tagoId, title, description, hint, _image);
      
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        
        // Pequeño delay para asegurar que la navegación no choca con el SnackBar
        Future.delayed(Duration.zero, () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('TaGo creado con éxito'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context); // Volver al mapa (MapAdminScreen)
          }
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleCreateTaGo() async {
    if (!_formKey.currentState!.validate()) return;

    final String title = _titleController.text.trim();
    final String description = _descriptionController.text.trim();
    final String hint = _hintController.text.trim();
    String tagoId = const Uuid().v4();

    try {
      bool isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _showSimulationDialog(tagoId, title, description, hint);
        return;
      }

      _showNfcWaitingDialog();
      
      await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        var ndef = Ndef.from(tag);
        if (ndef == null || !ndef.isWritable) {
          await NfcManager.instance.stopSession(errorMessage: "Etiqueta no válida");
          if (mounted) Navigator.pop(context);
          return;
        }

        NdefMessage message = NdefMessage([
          NdefRecord.createText(tagoId),
          NdefRecord.createExternal('android.com', 'pkg', Uint8List.fromList('com.example.tfg'.codeUnits)),
        ]);

        try {
          await ndef.write(message);
          await NfcManager.instance.stopSession();
          
          if (mounted) {
            Navigator.pop(context); // Cerrar diálogo NFC
            // Iniciamos la subida a base de datos
            await _processTagoCreation(tagoId, title, description, hint);
          }
        } catch (e) {
          await NfcManager.instance.stopSession();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error NFC: $e")));
          }
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    }
  }

  void _showSimulationDialog(String tagoId, String title, String description, String hint) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hardware NFC no detectado"),
        content: const Text("Parece que su dispositivo no tiene activada la opción de NFC"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ],
      ),
    );
  }

  void _showNfcWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const AlertDialog(
        title: Text("Acerca la pegatina NFC"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nfc, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text("Esperando etiqueta para grabar el ID..."),
          ],
        ),
      ),
    );
  }

  Future<void> _saveToBackend(String id, String title, String description, String hint, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _dbService.subirImagenMarcador(id, imageFile);
    }

    final locationData = await _getLocationData(widget.position.latitude, widget.position.longitude);
    final String? uid = _authService.currentUid;

    if (uid == null) throw Exception("No hay un usuario autenticado");

    // Creamos el marcador en la colección global 'marcadores'
    await _dbService.crearMarcador(id, {
      'id': id,
      'titulo': title,
      'descripcion': description,
      'pista': hint,
      'imagenUrl': imageUrl,
      'lat': widget.position.latitude,
      'lng': widget.position.longitude,
      'pais': locationData['pais'],
      'codigo_pais': locationData['codigo_pais'],
      'comunidad': locationData['comunidad'],
      'provincia': locationData['provincia'],
      'localidad': locationData['municipio'],
      'creadorId': uid,
      'fechaCreacion': DateTime.now().toIso8601String(),
      'ultimoEscaneo': DateTime.now().toIso8601String(),
    });

    // Registramos el TaGo en la subcolección 'creados' del usuario
    await _dbService.registrarTagoCreado(uid, id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        foregroundColor: AppColors.doradoClaro,
        backgroundColor: AppColors.azulOscuro,
        title: const Text('CREAR TAGO', style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2),)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ubicación: ${widget.position.latitude.toStringAsFixed(4)}, ${widget.position.longitude.toStringAsFixed(4)}',
                style: const TextStyle(color: AppColors.azulClaro, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 10),
              const Text('Título del TaGo', style: TextStyle(color: AppColors.doradoClaro, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: AppColors.blancoTexto),
                controller: _titleController,
                decoration: InputDecoration(
                  hintStyle: const TextStyle(color: AppColors.azulStamps),
                  hintText: 'Escribe un título', border: const OutlineInputBorder(),
                  // Borde cuando NO está seleccionado
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                  ),
                  // Borde cuando haces clic
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2.0),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 20),
              const Text('Imagen', style: TextStyle(color: AppColors.doradoClaro, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      color: AppColors.azulIntermedio,
                      border: Border.all(color: AppColors.azulClaro, width: 4),
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
                              Icon(Icons.add_a_photo, size: 50, color: AppColors.azulClaro),
                              SizedBox(height: 8),
                              Text('Pulsa para añadir una imagen', style: TextStyle(color: AppColors.azulClaro)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Descripción', style: TextStyle(color: AppColors.doradoClaro, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: AppColors.blancoTexto),
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintStyle: const TextStyle(color: AppColors.azulStamps),
                  hintText: 'Escribe una breve descripción', border: const OutlineInputBorder(),
                  // Borde cuando NO está seleccionado
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                  ),
                  // Borde cuando haces clic
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2.0),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 10),
              const Text('Pista', style: TextStyle(color: AppColors.doradoClaro, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                style: TextStyle(color: AppColors.blancoTexto),
                controller: _hintController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintStyle: const TextStyle(color: AppColors.azulStamps),
                  hintText: 'Escribe una pista para encontrarlo', border: const OutlineInputBorder(),
                  // Borde cuando NO está seleccionado
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                  ),
                  // Borde cuando haces clic
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2.0),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleCreateTaGo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.doradoClaro,
                    foregroundColor: AppColors.azulOscuro,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Crear TaGo', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 40),
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
    _hintController.dispose();
    super.dispose();
  }
}
