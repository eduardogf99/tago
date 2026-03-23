import 'package:flutter/material.dart';
import 'package:tfg/widgets/osm_map_widget.dart';
import '../widgets/app_navigation_bar.dart';
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
        backgroundColor: new Color.fromRGBO(0, 0, 0, 0),
      ),
      backgroundColor: new Color.fromRGBO(0, 0, 0, 0),
      body: Column(
        children: [
          // con Expanded el mapa ocupa el espacio disponible
          const Expanded(
            child: OSMMapWidget(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TagoScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Botón a ancho completo
              ),
              child: const Text('Escanear Tago'),
            ),
          ),
        ],
      ),
    );
  }
}
