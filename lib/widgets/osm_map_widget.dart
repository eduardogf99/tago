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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
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
  }

  void _animatedMapMove(LatLng destLocation, double destZoom, double destRotation) {
    final camera = _mapController.camera;
    final latTween = Tween<double>(begin: camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: camera.zoom, end: destZoom);
    final rotationTween = Tween<double>(begin: camera.rotation, end: destRotation);

    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    final Animation<double> animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      final rotationValue = rotationTween.evaluate(animation);
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
      _mapController.rotate(rotationValue);
      setState(() {
        _currentRotation = rotationValue;
      });
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  LatLng? getCurrentUserLocation() => _currentLocation;

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
            initialCenter: const LatLng(41.6568, -0.8805),
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              if (widget.onTap != null) widget.onTap!(point);
            },
            onPositionChanged: (position, hasGesture) {
              setState(() {
                _currentRotation = _mapController.camera.rotation;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: RetinaMode.isHighDensity(context),
              userAgentPackageName: 'com.example.tfg',
            ),
            MarkerLayer(
              markers: [
                // Marcadores que vienen de Firestore
                if (widget.extraMarkers != null) ...widget.extraMarkers!,
                
                // Marcador de selección manual
                if (widget.selectedPosition != null)
                  Marker(
                    point: widget.selectedPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Colors.purple, size: 40),
                  ),
                
                // Marcador de usuario
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
                if (widget.selectedPosition != null)
                  Marker(
                    point: widget.selectedPosition!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_pin, color: Colors.purple, size: 40),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 20,
          right: 20,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  _animatedMapMove(_mapController.camera.center, _mapController.camera.zoom, 0.0);
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
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
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (_currentLocation != null) {
                    _animatedMapMove(_currentLocation!, 16.0, _mapController.camera.rotation);
                  }
                },
                child: Container(
                  width: 45,
                  height: 45,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.my_location, color: Colors.grey, size: 28),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
