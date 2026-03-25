import 'package:flutter/material.dart';

class MapMarkerWidget extends StatefulWidget {
  final String title;

  const MapMarkerWidget({
    super.key,
    required this.title,
  });  @override
  State<MapMarkerWidget> createState() => _MapMarkerWidgetState();
}

class _MapMarkerWidgetState extends State<MapMarkerWidget> {
  bool _showTitle = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showTitle = !_showTitle;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Permite que el texto sobresalga del marcador
        children: [
          // Icono del marcador
          const Icon(
            Icons.location_on,
            color: Colors.red,
            size: 40,
          ),

          // Cuadro de información (solo se muestra si _showTitle es true)
          if (_showTitle)
            Positioned(
              top: -45, // Lo posiciona encima del icono
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}