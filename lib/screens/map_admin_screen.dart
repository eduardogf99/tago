import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; // Añadido para manejar ubicación aquí
import '../theme/app_colors.dart';
import '../widgets/osm_map_widget.dart';
import 'create_nfc_screen.dart';

class MapAdminScreen extends StatefulWidget {
  const MapAdminScreen({super.key});

  @override
  State<MapAdminScreen> createState() => _MapAdminScreenState();
}

class _MapAdminScreenState extends State<MapAdminScreen> {
  LatLng? _manualPosition;

  void _navigateToCreateScreen(LatLng position) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNfcScreen(position: position),
      ),
    );
  }

  // Nueva función para obtener la ubicación actual directamente
  Future<void> _useCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      _navigateToCreateScreen(LatLng(position.latitude, position.longitude));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo obtener la ubicación actual')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      body: Column(
        children: [
          Expanded(
            child: OSMMapWidget(
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
                // Botón 1: Usar posición actual corregido
                ElevatedButton.icon(
                  onPressed: _useCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Usar mi posición actual',),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.doradoClaro,
                    foregroundColor: AppColors.azulContenedor,
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
                      backgroundColor: AppColors.doradoClaro,
                      foregroundColor: AppColors.azulContenedor,
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
