import 'package:flutter/material.dart';
import 'package:tfg/widgets/map_widget.dart';
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
      appBar: AppBar(
        title: const Text('Mapa'),
      ),
      body: Column(
        children: [
          // Expanded es para que el mapa ocupe el espacio en la columna
          const Expanded(
            child: MapWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagoScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear Tago'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
