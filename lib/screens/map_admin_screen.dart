import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/osm_map_widget.dart';
import 'create_nfc_screen.dart';

class MapAdminScreen extends StatefulWidget {
  const MapAdminScreen({super.key});

  @override
  State<MapAdminScreen> createState() => _MapAdminScreenState();
}

class _MapAdminScreenState extends State<MapAdminScreen> {
  LatLng? _manualPosition;
  final GlobalKey<OSMMapWidgetState> _mapKey = GlobalKey<OSMMapWidgetState>();

  void _navigateToCreateScreen(LatLng position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNfcScreen(position: position),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
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
                // Botón 1: Usar posición actual
                ElevatedButton.icon(
                  onPressed: () {
                    final userPos = _mapKey.currentState?.getCurrentUserLocation();
                    if (userPos != null) {
                      _navigateToCreateScreen(userPos);
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
                
                // Botón 2: Crear en punto marcado
                if (_manualPosition != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToCreateScreen(_manualPosition!),
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
