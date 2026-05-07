import 'package:latlong2/latlong.dart';

// Este modelo define la estructura de un TaGo (marcador) en la App
class MapMarkerModel {
  final String id;
  final String title;
  final LatLng position;
  final String? imagenUrl;

  MapMarkerModel({
    required this.id,
    required this.title,
    required this.position,
    this.imagenUrl,
  });

  // Prepara los datos para ser enviados a la API REST o Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': title,
      'lat': position.latitude,
      'lng': position.longitude,
      'imagenUrl': imagenUrl,
    };
  }

  // Crea un objeto TaGo a partir de los datos que devuelve la API (formato JSON)
  factory MapMarkerModel.fromMap(Map<String, dynamic> map) {
    return MapMarkerModel(
      id: map['id']?.toString() ?? '',
      title: map['titulo'] ?? map['title'] ?? 'TaGo sin nombre',
      imagenUrl: map['imagenUrl'],
      position: LatLng(
        (map['lat'] ?? 0.0).toDouble(),
        (map['lng'] ?? 0.0).toDouble(),
      ),
    );
  }
}
