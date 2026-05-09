import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';

import '../theme/app_colors.dart';

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
  bool _isLoading = true; // Estado de carga

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

      if (permission == LocationPermission.deniedForever) return;

      // Obtener posición inicial rápida con timeout
      try {
        Position position = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 5));
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        }
      } catch (e) {
        debugPrint("Error o timeout obteniendo posición inicial: $e");
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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

  @override
  void dispose() {
    _positionStream?.cancel();
    _compassStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.azulIntermedio,
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.selectedPosition ?? _currentLocation ?? const LatLng(41.6488, -0.8891),
            initialZoom: 15.0,
            onTap: (tapPosition, point) {
              if (widget.onTap != null) widget.onTap!(point);
            },
            onPositionChanged: (position, hasGesture) {
              if (mounted) {
                setState(() {
                  _currentRotation = _mapController.camera.rotation;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.tfg',
              retinaMode: RetinaMode.isHighDensity(context),
            ),
            MarkerLayer(
              markers: [
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
                              child: const Icon(
                                Icons.arrow_drop_up,
                                size: 50,
                                color: AppColors.azulStamps,
                              ),
                            ),
                          ),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.azulIntermedio,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.blancoTexto, width: 2),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (widget.extraMarkers != null) ...widget.extraMarkers!,
                if (widget.selectedPosition != null)
                  Marker(
                    point: widget.selectedPosition!,
                    width: 40,
                    height: 40,
                    rotate: true,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on_rounded, color: AppColors.azulIntermedio, size: 40),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          bottom: 40,
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
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Transform.rotate(
                    angle: _currentRotation * (math.pi / 180),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: -3,
                          child: const Icon(Icons.arrow_drop_up, color: Colors.red, size: 35),
                        ),
                        Positioned(
                          bottom: -3,
                          child: Transform.rotate(
                            angle: math.pi,
                            child: const Icon(Icons.arrow_drop_up, color: Colors.grey, size: 35),
                          ),
                        ),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
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
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
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
