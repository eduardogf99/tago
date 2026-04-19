import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tfg/widgets/osm_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'tago_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  void _showTagoInfo(BuildContext context, String docId, Map<String, dynamic> data) async {
    // Comprobamos si el usuario ha escaneado este tago previamente
    // Buscamos en una subcolección del usuario 'escaneos' o similar.

    bool hasScanned = false;
    if (_currentUserId != null) {
      final scanDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(_currentUserId)
          .collection('escaneos')
          .doc(docId)
          .get();
      hasScanned = scanDoc.exists;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        String titulo = data['titulo'] ?? 'Sin título';
        String? imagenUrl = data['imagenUrl'];
        String pista = data['pista'] ?? 'No hay pistas disponibles.';
        bool mostrarPista = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(titulo, textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                    child: ClipOval(
                      child: hasScanned 
                        ? (imagenUrl != null && imagenUrl.isNotEmpty
                            ? Image.network(
                                imagenUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stack) => const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.image, size: 50, color: Colors.grey))
                        : const Center(
                            child: Text(
                              "???",
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (hasScanned)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); 
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TagoScreen(tagoId: docId),
                          ),
                        );
                      },
                      child: const Text("Ver"),
                    )
                  else
                    Column(
                      children: [
                        const Text(
                          "Escanea este TaGo para ver su contenido",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                        const SizedBox(height: 15),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Pista", style: TextStyle(fontWeight: FontWeight.bold)),
                            Switch(
                              value: mostrarPista,
                              onChanged: (value) {
                                setState(() {
                                  mostrarPista = value;
                                });
                              },
                            ),
                          ],
                        ),
                        if (mostrarPista)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              pista,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.deepPurple),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: const Text("TaGo"),
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      ),
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('marcadores').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar marcadores'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Convertimos los documentos de Firestore en una lista de Marcadores para el mapa
                List<Marker> markers = snapshot.data!.docs.map((doc) {
                  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                  String docId = doc.id;
                  
                  return Marker(
                    point: LatLng(data['lat'], data['lng']),
                    width: 40,
                    height: 40,
                    rotate: true,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _showTagoInfo(context, docId, data),
                      child: const Icon(Icons.location_on_rounded, color: Colors.blue, size: 40),
                    ),
                  );
                }).toList();

                return OSMMapWidget(
                  extraMarkers: markers,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
