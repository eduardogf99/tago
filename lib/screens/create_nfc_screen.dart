import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import '../controller/nfc_controller.dart';
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

  // Variables de control para el estado del NFC
  bool _nfcAvailable = false;
  bool _isWritingProcessActive = false;
  String _currentTagoId = '';
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _initAndPrepareNfc();
  }

  // Prepara el entorno NFC de forma segura
  Future<void> _initAndPrepareNfc() async {
    // 1. Pausamos el listener global de fondo para evitar conflictos
    await NfcController.pauseBackgroundListener();

    // 2. Comprobamos disponibilidad de hardware
    _nfcAvailable = await NfcManager.instance.isAvailable();
    if (!_nfcAvailable) return;

    // 3. Dejamos el lector activo de forma persistente en esta pantalla
    NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          // Solo actuamos si el usuario ha pulsado el botón de confirmar el formulario
          if (!_isWritingProcessActive) return;

          var ndef = Ndef.from(tag);

          // Validación 1: ¿Soporta formato NDEF?
          if (ndef == null) {
            _closeNfcWaitingDialog();
            _isWritingProcessActive = false;
            _showSnackBar('Esta etiqueta no es compatible con el formato requerido', Colors.orange);
            return;
          }

          // Validación 2: ¿Está bloqueada en escritura? (Tu petición)
          if (!ndef.isWritable) {
            _closeNfcWaitingDialog();
            _isWritingProcessActive = false;
            _showSnackBar('Error: Este NFC ya está bloqueado en modo de solo lectura', Colors.red);
            return;
          }

          // Si todo es correcto, procedemos a grabar el ID generado previamente
          NdefMessage message = NdefMessage([
            NdefRecord.createText(_currentTagoId),
            NdefRecord.createExternal('android.com', 'pkg', Uint8List.fromList('com.example.tfg'.codeUnits)),
          ]);

          try {
            // Grabamos datos
            await ndef.write(message);

            // Bloqueamos el hardware irreversiblemente (Quitado en desarrollo si es necesario)
            await ndef.writeLock();

            _closeNfcWaitingDialog();
            _isWritingProcessActive = false;

            // Procedemos con la sincronización al servidor
            if (mounted) {
              await _processTagoCreation(
                  _currentTagoId,
                  _titleController.text.trim(),
                  _descriptionController.text.trim(),
                  _hintController.text.trim()
              );
            }
          } catch (e) {
            _closeNfcWaitingDialog();
            _isWritingProcessActive = false;
            _showSnackBar('Error al grabar o bloquear el NFC: $e', Colors.red);
          }
        },
        onError: (error) async {
          debugPrint("Error persistente en pantalla de creación: $error");
        }
    );
  }

  // Disparador del botón principal
  Future<void> _handleCreateTaGo() async {
    if (!_formKey.currentState!.validate()) return;

    // Si el dispositivo no tiene NFC activo, salta la simulación/aviso
    if (!_nfcAvailable) {
      _showSimulationDialog();
      return;
    }

    // Preparamos los datos de sesión de escritura
    _currentTagoId = const Uuid().v4();
    _isWritingProcessActive = true;

    // Mostramos el aviso visual para que acerquen el tag
    _showNfcWaitingDialog();
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
      ),
    );
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
        Navigator.pop(context); // Cierra el diálogo de sincronización

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TaGo creado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Regresa a la pantalla anterior del mapa/lista
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error al guardar: $e', Colors.red);
      }
    }
  }

  Future<void> _pickImage() async {
    File? selectedImage = await ImageHelper.mostrarSelector(context);
    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
      });
    }
  }

  void _showSimulationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hardware NFC no detectado"),
        content: const Text("Parece que su dispositivo no tiene activada la opción de NFC o no dispone de ella."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Entendido")),
        ],
      ),
    );
  }

  void _showNfcWaitingDialog() {
    _dialogShowing = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _isWritingProcessActive = false; // Cancela la escritura si cierran el modal tocando fuera
            _dialogShowing = false;
          }
        },
        child: const AlertDialog(
          title: Text("Acerca la pegatina NFC"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.nfc, size: 50, color: Colors.blue),
              SizedBox(height: 10),
              Text("Esperando etiqueta para grabar y bloquear el ID..."),
            ],
          ),
        ),
      ),
    );
  }

  void _closeNfcWaitingDialog() {
    if (_dialogShowing && mounted) {
      Navigator.pop(context);
      _dialogShowing = false;
    }
  }

  Future<void> _saveToBackend(String id, String title, String description, String hint, File? imageFile) async {
    String? imageUrl;
    if (imageFile != null) {
      imageUrl = await _dbService.subirImagenMarcador(id, imageFile);
    }

    final locationData = await _getLocationData(widget.position.latitude, widget.position.longitude);
    final String? uid = _authService.currentUid;

    if (uid == null) throw Exception("No hay un usuario autenticado");

    Map<String, dynamic> tagoData = {
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
    };

    await Future.wait([
      _dbService.crearMarcador(id, tagoData),
      _dbService.registrarTagoCreado(uid, id),
    ]);
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                  ),
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                  ),
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.azulStamps, width: 1.5),
                  ),
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
              const SizedBox(height: 40),
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

    // Al salir de la pantalla matamos la sesión de escritura y reactivamos el listener global
    NfcManager.instance.stopSession().then((_) {
      NfcController.resumeBackgroundListener();
    }).catchError((_) {
      NfcController.resumeBackgroundListener();
    });

    super.dispose();
  }
}