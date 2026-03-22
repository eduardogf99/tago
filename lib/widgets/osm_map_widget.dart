import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

class OSMMapWidget extends StatefulWidget {
  const OSMMapWidget({super.key});

  @override
  State<OSMMapWidget> createState() => _OSMMapWidgetState();
}

class _OSMMapWidgetState extends State<OSMMapWidget> {
  final MapController _mapController = MapController();
  double _currentRotation = 0.0;

  LatLng? _currentLocation;
  double? _heading;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  @override
  void initState() {
    super.initState();
    _initLocationAndCompass();
  }

  Future<void> _initLocationAndCompass() async {
    // Verificar y solicitar permisos
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // pilla la ubicación
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    });

    // pilla la direccion que estamos mirando
    _compassStream = FlutterCompass.events?.listen((CompassEvent event) {
      setState(() {
        _heading = event.heading;
      });
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(41.6568, -0.8805), // El Pilar
            initialZoom: 15.0,
            onPositionChanged: (position, hasGesture) {
              setState(() {
                _currentRotation = _mapController.camera.rotation;
              });
            },
          ),
          children: [
            TileLayer(
              // Nueva URL para el estilo Humanitario
              urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
              // Es necesario definir los subdominios para este servidor específico
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.tfg',
            ),
            MarkerLayer(
              markers: [
                // MARCADOR DE USUARIO (Ubicación + Dirección)
                if (_currentLocation != null)
                  Marker(
                    point: _currentLocation!,
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Haz de luz (dirección)
                        if (_heading != null)
                          Transform.rotate(
                            angle: (_heading! * (math.pi / 180)),
                            child: Transform.translate(
                              offset: const Offset(0, -13),
                              child: Icon(
                                Icons.arrow_drop_up,
                                size: 50,
                                color: Colors.blue.withOpacity(0.4),
                              ),
                            ),
                          ),
                        // Círculo de ubicación
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Widget de la Brújula Personalizada
        Positioned(
          top: 20,
          right: 20,
          child: GestureDetector(
            onTap: () {
              // reorienta el mapa al norte (0 grados)
              _mapController.rotate(0);
              // la brújula también se resetee
              setState(() {
                _currentRotation = 0.0;
              });
            },
            child: Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Colors.white70,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Transform.rotate(

                angle: _currentRotation * (math.pi / 180),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Parte Norte de la aguja (Roja)
                    Positioned(
                      top: -3,
                      child: Icon(
                        Icons.arrow_drop_up,
                        color: Colors.red,
                        size: 35,
                      ),
                    ),
                    // Parte Sur de la aguja (Negra/Gris)
                    Positioned(
                      bottom: -3,
                      child: Transform.rotate(
                        angle: math.pi,
                        child: Icon(
                          Icons.arrow_drop_up,
                          color: Colors.grey,
                          size: 35,
                        ),
                      ),
                    ),
                    // Eje central de la aguja
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}