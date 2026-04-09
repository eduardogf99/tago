import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import '../widgets/osm_map_widget.dart';

class TagoScreen extends StatefulWidget {
  final String? tagoId; // ID del marcador en Firestore

  const TagoScreen({super.key, this.tagoId});

  @override
  State<TagoScreen> createState() => _TagoScreenState();
}

class _TagoScreenState extends State<TagoScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _tagoData;

  @override
  void initState() {
    super.initState();
    if (widget.tagoId != null) {
      _loadTagoData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTagoData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('marcadores')
          .doc(widget.tagoId)
          .get();

      if (doc.exists) {
        setState(() {
          _tagoData = doc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
        
        // Opcional: Actualizar el campo 'ultimoEscaneo'
        FirebaseFirestore.instance
            .collection('marcadores')
            .doc(widget.tagoId)
            .update({'ultimoEscaneo': FieldValue.serverTimestamp()});
            
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando TaGo: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tagoData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TaGo no encontrado')),
        body: const Center(child: Text('No se ha podido cargar la información de este TaGo.')),
      );
    }

    double screenWidth = MediaQuery.of(context).size.width;
    String titulo = _tagoData!['titulo'] ?? 'Sin título';
    String descripcion = _tagoData!['descripcion'] ?? 'Sin descripción';
    String? imagenUrl = _tagoData!['imagenUrl'];
    String creador = _tagoData!['creador'] ?? 'Desconocido';
    double lat = _tagoData!['lat'] ?? 0.0;
    double lng = _tagoData!['lng'] ?? 0.0;
    LatLng tagoPosition = LatLng(lat, lng);
    
    Timestamp? lastScanTs = _tagoData!['ultimoEscaneo'] as Timestamp?;
    String lastScan = lastScanTs != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(lastScanTs.toDate())
        : 'Nunca';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                titulo,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            // Imagen circular con animación de carga
            Center(
              child: Container(
                width: screenWidth * 0.5,
                height: screenWidth * 0.5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: ClipOval(
                  child: imagenUrl != null && imagenUrl.isNotEmpty
                      ? Image.network(
                          imagenUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                        )
                      : const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Fila con 4 iconos (funcionalidad pendiente de implementar)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_up_alt_outlined)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.thumb_down_alt_outlined)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.star_border)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.share)),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Descripción',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),
            Text(
              'Creado por: $creador',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'Último escaneo: $lastScan',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            // Mapa al final de la pantalla
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: 400,
                width: double.infinity,
                child: OSMMapWidget(
                  selectedPosition: tagoPosition,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
