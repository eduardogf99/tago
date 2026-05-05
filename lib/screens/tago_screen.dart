import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_colors.dart';
import '../widgets/osm_map_widget.dart';

class TagoScreen extends StatefulWidget {
  final String? tagoId;

  const TagoScreen({super.key, this.tagoId});

  @override
  State<TagoScreen> createState() => _TagoScreenState();
}

class _TagoScreenState extends State<TagoScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tagoData;
  String _creadorNombre = 'Cargando...';

  @override
  void initState() {
    super.initState();
    if (widget.tagoId != null) {
      _loadTagoData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTagoData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('marcadores')
          .doc(widget.tagoId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() => _tagoData = data);

        final String? creadorId = data['creadorId'];
        if (creadorId != null && creadorId.isNotEmpty) {
          final userDoc = await FirebaseFirestore.instance.collection('usuarios').doc(creadorId).get();
          if (userDoc.exists) {
            setState(() => _creadorNombre = (userDoc.data() as Map<String, dynamic>)['usuario'] ?? 'Desconocido');
          }
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint("Error cargando TaGo: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Nunca';
    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date.toDate());
    }
    if (date is String) {
      DateTime? dt = DateTime.tryParse(date);
      if (dt != null) return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    }
    return 'Fecha no válida';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.azulOscuro,
        body: Center(child: CircularProgressIndicator(color: AppColors.doradoClaro)),
      );
    }

    if (_tagoData == null) {
      return Scaffold(
        backgroundColor: AppColors.azulOscuro,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('No encontrado', style: TextStyle(color: AppColors.doradoClaro)),
          leading: const BackButton(color: AppColors.doradoClaro),
        ),
        body: const Center(child: Text('Error al cargar.', style: TextStyle(color: Colors.white))),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    String titulo = _tagoData!['titulo'] ?? 'Sin título';
    String descripcion = _tagoData!['descripcion'] ?? 'Sin descripción';
    String? imagenUrl = _tagoData!['imagenUrl'];
    LatLng tagoPosition = LatLng(_tagoData!['lat'] ?? 0.0, _tagoData!['lng'] ?? 0.0);
    String lastScan = _formatDate(_tagoData!['ultimoEscaneo']);

    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("TAGO", style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2),),
        leading: const BackButton(color: AppColors.doradoClaro),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Contenedor principal estilo "Ficha"
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Título destacado
                  Text(
                    titulo.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.doradoClaro,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),

                  // Imagen Circular con borde dorado
                  Center(
                    child: Container(
                      width: screenWidth * 0.55,
                      height: screenWidth * 0.55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.doradoClaro, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ],
                      ),
                      child: ClipOval(
                        child: imagenUrl != null && imagenUrl.isNotEmpty
                            ? Image.network(
                          imagenUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50, color: AppColors.doradoClaro),
                        )
                            : const Icon(Icons.image, size: 80, color: AppColors.azulStamps),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Sección Descripción
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'DESCRIPCIÓN',
                      style: TextStyle(color: AppColors.doradoClaro, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    descripcion,
                    textAlign: TextAlign.justify,
                    style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 25),
                  const Divider(color: AppColors.azulStamps),
                  const SizedBox(height: 15),

                  // Detalles del Creador y Fecha
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: AppColors.azulClaro, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Creado por: $_creadorNombre',
                          style: const TextStyle(color: AppColors.azulClaro, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.qr_code_scanner, color: AppColors.azulClaro, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Último escaneo: $lastScan',
                          style: const TextStyle(color: AppColors.azulClaro, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Mapa con bordes redondeados y borde dorado
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 10),
                child: Text(
                  'UBICACIÓN',
                  style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.doradoClaro, width: 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: OSMMapWidget(selectedPosition: tagoPosition),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}