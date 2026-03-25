import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/osm_map_widget.dart';

class CreateNfcScreen extends StatefulWidget {
  const CreateNfcScreen({super.key});

  @override
  State<CreateNfcScreen> createState() => _CreateNfcScreenState();
}

class _CreateNfcScreenState extends State<CreateNfcScreen> {
  LatLng? _manualPosition;
  final GlobalKey<OSMMapWidgetState> _mapKey = GlobalKey<OSMMapWidgetState>();

  // Función para guardar en Firestore
  Future<void> _saveMarker(LatLng position) async {
    try {
      await FirebaseFirestore.instance.collection('marcadores').add({
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marcador guardado con éxito')),
        );
        setState(() => _manualPosition = null); // Limpiar selección
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: new Color.fromRGBO(0, 0, 0, 0),
      body: Column(
        children: [
          Expanded(
            child: OSMMapWidget(
              key: _mapKey,
              selectedPosition: _manualPosition,
              onTap: (point) {
                setState(() {
                  _manualPosition = point;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Botón 1: Usar posición actual (Siempre visible)
                ElevatedButton.icon(
                  onPressed: () {
                    final userPos = _mapKey.currentState?.getCurrentUserLocation();
                    if (userPos != null) {
                      _saveMarker(userPos);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Buscando señal GPS...')),
                      );
                    }
                  },
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi posición actual'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ),
                
                // Botón 2: Crear en punto marcado (Solo si hay posición manual)
                if (_manualPosition != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _saveMarker(_manualPosition!),
                    icon: const Icon(Icons.add_location_alt),
                    label: const Text('Crear en el punto marcado'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.purple.shade50,
                      foregroundColor: Colors.purple,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

