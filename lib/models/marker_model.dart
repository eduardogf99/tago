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

  // Convierte un objeto UserModel a un Mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'LatLng': position,
    };
  }

  // Crea un objeto UserModel a partir de un documento de Firestore
  factory MapMarkerModel.fromMap(Map<String, dynamic> map) {
    return MapMarkerModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      position: map['LatLng'] ?? '',
    );
  }
}

