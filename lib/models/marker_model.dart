import 'package:latlong2/latlong.dart';

class MapMarkerModel {
  final String id;
  final String title;
  final LatLng position;

  MapMarkerModel({
    required this.id,
    required this.title,
    required this.position,
  });

  // Convierte el objeto a un mapa para ser almacenado en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'LatLng': position,
    };
  }

  // Convierte el mapa recuperado de Firestore a un objeto
  factory MapMarkerModel.fromMap(Map<String, dynamic> map) {
    return MapMarkerModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      position: map['LatLng'] ?? '',
    );
  }
}

