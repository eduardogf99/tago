import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/tago_card.dart';

// Esta pantalla muestra la colección de TaGos descubiertos por el usuario
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final AuthService _authService = AuthService();
  
  // Cargamos los TaGos descubiertos
  Future<List<Map<String, dynamic>>> _fetchMyLibrary() async {
    final uid = _authService.currentUid;
    if (uid == null) return [];

    try {
      // 1. Obtener la lista de IDs escaneados desde la API
      final List<String> escaneosIds = await _dbService.obtenerEscaneosUsuario(uid);
      if (escaneosIds.isEmpty) return [];

      // 2. Obtener todos los marcadores para filtrar por ID
      final allMarkers = await _dbService.obtenerMarcadores();
      
      // 3. Cruzamos los datos y devolvemos la lista formateada
      return allMarkers
          .where((m) => escaneosIds.contains(m.id))
          .map((m) => {
            'id': m.id,
            'titulo': m.title,
            'imagenUrl': m.imagenUrl,
          })
          .toList();
    } catch (e) {
      debugPrint("Error al cargar biblioteca: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Biblioteca de TaGos', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchMyLibrary(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Error de conexión con la biblioteca. Comprueba que el servidor está activo.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final coleccion = snapshot.data ?? [];

          if (coleccion.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_stories, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 20),
                  const Text(
                    "¡Tu biblioteca está vacía!",
                    style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  const Text("¡Escanea un TaGo para empezar!"),
                ],
              ),
            );
          }

          // Pintamos la cuadrícula usando el componente reutilizable TagoCard
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, 
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            itemCount: coleccion.length,
            itemBuilder: (context, index) => TagoCard(item: coleccion[index]),
          );
        },
      ),
    );
  }
}
