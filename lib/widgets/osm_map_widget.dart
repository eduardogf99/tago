import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

class OSMMapWidget extends StatefulWidget {
  final Function(LatLng)? onTap;
  final LatLng? selectedPosition;
  final List<Marker>? extraMarkers;

  const OSMMapWidget({super.key, this.onTap, this.selectedPosition, this.extraMarkers});

  @override
  State<OSMMapWidget> createState() => OSMMapWidgetState();
}

class OSMMapWidgetState extends State<OSMMapWidget> with TickerProviderStateMixin {
  late final MapController _mapController;
  double _currentRotation = 0.0;
  bool _hasCenteredOnUser = false;

  LatLng? _currentLocation;
  double? _heading;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassStream;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initLocationAndCompass();
  }

  Future<void> _initLocationAndCompass() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      // Obtener posición inicial rápida
      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((Position position) {
        if (mounted) {
          LatLng newLocation = LatLng(position.latitude, position.longitude);
          setState(() {
            _currentLocation = newLocation;
            if (!_hasCenteredOnUser && widget.selectedPosition == null) {
              _mapController.move(newLocation, 15.0);
              _hasCenteredOnUser = true;
            }
          });
        }
      });

      _compassStream = FlutterCompass.events?.listen((CompassEvent event) {
        if (mounted) {
          setState(() {
            _heading = event.heading;
          });
        }
      });
    } catch (e) {
      debugPrint("Error inicializando ubicación: $e");
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    // No disponemos el controlador aquí si se usa en un PageView para evitar errores de "disposed"
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.selectedPosition ?? _currentLocation ?? const LatLng(41.6488, -0.8891),
        initialZoom: 15.0,
        onTap: (tapPosition, point) {
          if (widget.onTap != null) widget.onTap!(point);
        },
        onPositionChanged: (position, hasGesture) {
          // Evitamos setState innecesarios si no hay cambio real de rotación
          if (_currentRotation != _mapController.camera.rotation) {
            _currentRotation = _mapController.camera.rotation;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.example.tfg',
        ),
        MarkerLayer(
          markers: [
            if (widget.extraMarkers != null) ...widget.extraMarkers!,
            if (widget.selectedPosition != null)
              Marker(
                point: widget.selectedPosition!,
                width: 40,
                height: 40,
                child: const Icon(Icons.location_pin, color: Colors.purple, size: 40),
              ),
            if (_currentLocation != null)
              Marker(
                point: _currentLocation!,
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
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
    );
  }
}
