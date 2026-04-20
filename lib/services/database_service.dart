import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/marker_model.dart';

class DatabaseService {

  final String _baseUrl = "http://10.0.2.2:5001/tago-ec338/us-central1/api";

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;



  Future<List<MapMarkerModel>> obtenerMarcadores() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/marcadores'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => MapMarkerModel.fromMap(item)).toList();
      } else {
        print("Error en la API: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error al conectar con la API: $e");
      return [];
    }
  }

  Future<void> crearMarcador(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marcadores'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id": id, ...data}),
      );

      if (response.statusCode != 201) {
        throw Exception("Error al crear marcador: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al crear marcador (API): $e");
      rethrow;
    }
  }



  //Obtener la lista completa de usuarios
  Future<List<UserModel>> obtenerTodosLosUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios'));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => UserModel.fromMap(item)).toList();
      } else {
        print("Error al obtener usuarios: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error en obtenerTodosLosUsuarios: $e");
      return [];
    }
  }

  //Obtener un usuario específico por su UID
  Future<UserModel?> obtenerUsuario(String uid) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios/$uid'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromMap(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception("Error al obtener usuario: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en obtenerUsuario (API): $e");
      rethrow;
    }
  }

  // 3. Crear o actualizar un usuario
  Future<void> actualizarUsuario(String uid, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"uid": uid, ...data}),
      );

      if (response.statusCode != 200) {
        throw Exception("Error al actualizar usuario: ${response.statusCode}");
      }
    } catch (e) {
      print("Error en actualizarUsuario (API): $e");
      rethrow;
    }
  }

  // --- IMÁGENES (Directo a Firebase Storage por eficiencia) ---

  Future<String> subirImagenPerfil(String uid, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('perfiles').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(
        imageFile, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error en subirImagenPerfil: $e");
      rethrow;
    }
  }

  Future<String> subirImagenMarcador(String id, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('marcadores_images').child('$id.jpg');
      UploadTask uploadTask = ref.putFile(
        imageFile, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error en subirImagenMarcador: $e");
      rethrow;
    }
  }
}
