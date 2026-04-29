import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/marker_model.dart';

class DatabaseService {
  // Configuración del servidor local para el emulador
  final String _baseUrl = "http://127.0.0.1:5001/tago-ec338/us-central1/api";

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- MÉTODOS DE RESPALDO (Directo a Firestore) ---

  Future<UserModel?> _obtenerUsuarioFirestore(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    return doc.exists ? UserModel.fromMap(doc.data() as Map<String, dynamic>) : null;
  }

  Future<List<UserModel>> _obtenerTodosUsuariosFirestore() async {
    final snapshot = await _db.collection('usuarios').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<List<MapMarkerModel>> _obtenerMarcadoresFirestore() async {
    final snapshot = await _db.collection('marcadores').get();
    return snapshot.docs.map((doc) => MapMarkerModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  // --- MARCADORES ---

  // Obtener todos los marcadores disponibles en el mapa
  Future<List<MapMarkerModel>> obtenerMarcadores() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/marcadores'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => MapMarkerModel.fromMap(item)).toList();
      }
      return await _obtenerMarcadoresFirestore();
    } catch (e) {
      return await _obtenerMarcadoresFirestore();
    }
  }

  // Obtener un marcador individual para ver sus detalles
  Future<Map<String, dynamic>?> obtenerMarcadorPorId(String id) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/marcadores'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        final tago = body.firstWhere((m) => m['id'] == id, orElse: () => null);
        if (tago != null) return tago as Map<String, dynamic>;
      }
      final doc = await _db.collection('marcadores').doc(id).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      final doc = await _db.collection('marcadores').doc(id).get();
      return doc.data() as Map<String, dynamic>?;
    }
  }

  // Guardar un nuevo marcador
  Future<void> crearMarcador(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marcadores'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id": id, ...data}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        await _db.collection('marcadores').doc(id).set(data);
      }
    } catch (e) {
      await _db.collection('marcadores').doc(id).set(data);
    }
  }

  // --- USUARIOS ---

  Future<List<UserModel>> obtenerTodosLosUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => UserModel.fromMap(item)).toList();
      }
      return await _obtenerTodosUsuariosFirestore();
    } catch (e) {
      return await _obtenerTodosUsuariosFirestore();
    }
  }

  Future<UserModel?> obtenerUsuario(String uid) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios/$uid'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserModel.fromMap(data);
      }
      return await _obtenerUsuarioFirestore(uid);
    } catch (e) {
      return await _obtenerUsuarioFirestore(uid);
    }
  }

  Future<void> actualizarUsuario(String uid, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"uid": uid, ...data}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        await _db.collection('usuarios').doc(uid).set(data, SetOptions(merge: true));
      }
    } catch (e) {
      await _db.collection('usuarios').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  // --- ESCANEOS  ---

  // Traer todos los marcadores que el usuario ha desbloqueado
  Future<List<String>> obtenerEscaneosUsuario(String uid) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios/$uid/escaneos'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        // Devolvemos solo la lista de IDs
        return body.map((item) => item['id'] as String).toList();
      }
      
      final snapshot = await _db.collection('usuarios').doc(uid).collection('escaneos').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      final snapshot = await _db.collection('usuarios').doc(uid).collection('escaneos').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    }
  }

  Future<bool> verificarEscaneo(String uid, String tagoId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios/$uid/escaneos/$tagoId'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      final doc = await _db.collection('usuarios').doc(uid).collection('escaneos').doc(tagoId).get();
      return doc.exists;
    }
  }

  Future<void> registrarEscaneo(String uid, String tagoId) async {
    try {
      await http.post(Uri.parse('$_baseUrl/usuarios/$uid/escaneos/$tagoId'))
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      await _db.collection('usuarios').doc(uid).collection('escaneos').doc(tagoId).set({
        'fechaEscaneo': DateTime.now().toIso8601String()
      });
    }
  }

  // --- SUBIDA DE IMÁGENES (Directo a Storage) ---

  Future<String> subirImagenPerfil(String uid, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('perfiles').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<String> subirImagenMarcador(String id, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('marcadores_images').child('$id.jpg');
      UploadTask uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }
}
