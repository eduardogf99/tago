import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_tagoData == null) return Scaffold(appBar: AppBar(title: const Text('No encontrado')), body: const Center(child: Text('Error al cargar.')));

    double screenWidth = MediaQuery.of(context).size.width;
    String titulo = _tagoData!['titulo'] ?? 'Sin título';
    String descripcion = _tagoData!['descripcion'] ?? 'Sin descripción';
    String? imagenUrl = _tagoData!['imagenUrl'];
    LatLng tagoPosition = LatLng(_tagoData!['lat'] ?? 0.0, _tagoData!['lng'] ?? 0.0);
    
    // Usamos la nueva función de formateo seguro
    String lastScan = _formatDate(_tagoData!['ultimoEscaneo']);

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text(titulo, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: screenWidth * 0.5, height: screenWidth * 0.5,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
                child: ClipOval(
                  child: imagenUrl != null && imagenUrl.isNotEmpty
                      ? Image.network(imagenUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, size: 50))
                      : const Icon(Icons.image, size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(descripcion, textAlign: TextAlign.justify, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 30),
            const Divider(),
            Text('Creado por: $_creadorNombre', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Text('Último escaneo: $lastScan', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 30),
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(height: 400, width: double.infinity, child: OSMMapWidget(selectedPosition: tagoPosition)),
            ),
          ],
        ),
      ),
    );
  }
}
