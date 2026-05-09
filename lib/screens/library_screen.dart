import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/tago_card.dart';

// Biblioteca que muestra los tagos que el usuario ha escaneado


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
      // obtenemos la lista de ids escaneados desde la API
      final List<String> escaneosIds = await _dbService.obtenerEscaneosUsuario(uid);
      if (escaneosIds.isEmpty) return [];

      // obtenemos todos los marcadores para filtrar por id
      final allMarkers = await _dbService.obtenerMarcadores();
      
      // devolvemos la lista
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
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        title: const Text('MI BIBLIOTECA DE TAGOS', style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2),),
        centerTitle: true,
        backgroundColor: AppColors.azulOscuro,
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
                  style: TextStyle(color: AppColors.error),
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
                  Icon(Icons.auto_stories, size: 80, color: AppColors.azulStamps),
                  const SizedBox(height: 20),
                  const Text(
                    "¡Tu biblioteca está vacía!",
                    style: TextStyle(fontSize: 18, color: AppColors.azulStamps, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 10),
                  const Text("¡Escanea un TaGo para empezar!", style: TextStyle(fontSize: 18, color: AppColors.azulStamps),),
                ],
              ),
            );
          }

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
