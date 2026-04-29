import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:tfg/widgets/osm_map_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/tago_dialogs.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
              builder: (context, marcadoresSnapshot) {
                if (marcadoresSnapshot.hasError) {
                  return const Center(child: Text('Error al cargar marcadores'));
                }

                if (marcadoresSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _currentUserId != null 
                    ? FirebaseFirestore.instance.collection('usuarios').doc(_currentUserId).collection('escaneos').snapshots()
                    : const Stream.empty(),
                  builder: (context, escaneosSnapshot) {
                    Set<String> scannedIds = {};
                    if (escaneosSnapshot.hasData) {
                      scannedIds = escaneosSnapshot.data!.docs.map((doc) => doc.id).toSet();
                    }

                    List<Marker> markers = marcadoresSnapshot.data!.docs.map((doc) {
                      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                      String docId = doc.id;
                      bool isScanned = scannedIds.contains(docId);
                      int reportes = data['reportes'] ?? 0;
                      
                      Color iconColor;
                      if (reportes >= 5) {
                        iconColor = const Color.fromRGBO(241, 77, 77, 1.0);
                      } else if (isScanned) {
                        iconColor = const Color.fromRGBO(61, 156, 91, 1.0);
                      } else {
                        iconColor = Colors.blue;
                      }
                      
                      return Marker(
                        point: LatLng(data['lat'], data['lng']),
                        width: 40,
                        height: 40,
                        rotate: true,
                        alignment: Alignment.topCenter,
                        child: GestureDetector(
                          onTap: () => TagoDialogs.mostrarInfoMarcador(
                            context: context, 
                            docId: docId,
                            hasScanned: isScanned,
                          ),
                          child: Transform.translate(
                            offset: const Offset(0, -5),
                            child: Icon(
                              isScanned ? Icons.location_off_rounded : Icons.location_on_rounded,
                              color: iconColor,
                              size: 40
                            ),
                          ),
                        ),
                      );
                    }).toList();

                    return OSMMapWidget(extraMarkers: markers);
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
