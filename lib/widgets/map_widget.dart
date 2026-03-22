import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  // Posición inicial (ejemplo: El Pilar, Zaragoza)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(41.6568, -0.8805),
    zoom: 14.0,
  );

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      mapType: MapType.normal,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: {
        const Marker(
          markerId: MarkerId('pilar'),
          position: LatLng(41.6568, -0.8805),
          infoWindow: InfoWindow(title: 'Basílica del Pilar'),
        ),
      },
    );
  }
}
