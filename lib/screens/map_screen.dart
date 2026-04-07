import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tfg/widgets/osm_map_widget.dart';
import 'tago_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
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
                    child: GestureDetector(
                      onTap: () {
                        // Pasamos el ID del marcador a la pantalla TagoScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TagoScreen(tagoId: docId),
                          ),
                        );
                      },
                      child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                    ),
                  );
                }).toList();

                return OSMMapWidget(
                  extraMarkers: markers,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Aquí podrías abrir TagoScreen para escanear un NFC nuevo
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagoScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Escanear Tago'),
            ),
          ),
        ],
      ),
    );
  }
}
