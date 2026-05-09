import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';
import '../models/marker_model.dart';

class DatabaseService {
  final String _baseUrl = "http://127.0.0.1:5001/tago-ec338/us-central1/api";

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final http.Client _httpClient;

  // El constructor permite inyectar mocks, pero usa las instancias reales por defecto
  DatabaseService({
    FirebaseFirestore? db,
    FirebaseStorage? storage,
    http.Client? httpClient,
  })  : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _httpClient = httpClient ?? http.Client();

  // MÉTODOS DE RESPALDO (Directo a Firestore) ---

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

  // MARCADORES ---

  Future<List<MapMarkerModel>> obtenerMarcadores() async {
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/marcadores'))
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

  Future<Map<String, dynamic>?> obtenerMarcadorPorId(String id) async {
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/marcadores'))
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

  Future<void> crearMarcador(String id, Map<String, dynamic> data) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/marcadores'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id": id, ...data}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 201 && response.statusCode != 200) {
        await _db.collection('marcadores').doc(id).set(data);
      }
    } catch (e) {
      print("Error llamando a la API, usando respaldo Firestore: $e");
      await _db.collection('marcadores').doc(id).set(data);
    }
  }

  Future<void> reportarMarcador(String id) async {
    try {
      await _db.collection('marcadores').doc(id).set({
        'reportes': FieldValue.increment(1)
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // USUARIOS ---

  Future<List<UserModel>> obtenerTodosLosUsuarios() async {
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/usuarios'))
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
      final response = await _httpClient.get(Uri.parse('$_baseUrl/usuarios/$uid'))
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
      final response = await _httpClient.post(
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

  // ESCANEOS ---

  Future<List<String>> obtenerEscaneosUsuario(String uid) async {
    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/usuarios/$uid/escaneos'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
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
      final response = await _httpClient.get(Uri.parse('$_baseUrl/usuarios/$uid/escaneos/$tagoId'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      final doc = await _db.collection('usuarios').doc(uid).collection('escaneos').doc(tagoId).get();
      return doc.exists;
    }
  }

  Future<void> registrarEscaneo(String uid, String tagoId) async {
    try {
      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/usuarios/$uid/escaneos/$tagoId'),
        headers: {"Content-Type": "application/json"},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 201) {
        await _registrarEscaneoRespaldoDirecto(uid, tagoId);
      }
    } catch (e) {
      await _registrarEscaneoRespaldoDirecto(uid, tagoId);
    }
  }

  Future<void> _registrarEscaneoRespaldoDirecto(String uid, String tagoId) async {
    WriteBatch batch = _db.batch();
    DocumentReference usuarioRef = _db.collection('usuarios').doc(uid);
    DocumentReference escaneoRef = usuarioRef.collection('escaneos').doc(tagoId);

    batch.set(escaneoRef, {
      'fechaEscaneo': DateTime.now().toIso8601String(),
      'tagoId': tagoId,
    });

    batch.set(usuarioRef, {
      'totalEscaneos': FieldValue.increment(1),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> registrarTagoCreado(String uid, String tagoId) async {
    await _db.collection('usuarios').doc(uid).collection('creados').doc(tagoId).set({
      'tagoId': tagoId,
      'fechaCreacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> eliminarTagoCompleto(String tagoId, String creadorId) async {
    try {
      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/marcadores/$tagoId'),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw Exception("Fallo en el servidor: ${response.body}");
      }
    } catch (e) {
      WriteBatch batch = _db.batch();
      batch.delete(_db.collection('marcadores').doc(tagoId));
      batch.delete(_db.collection('usuarios').doc(creadorId).collection('creados').doc(tagoId));
      await batch.commit();
    }
  }

  // SUBIDA DE IMÁGENES ---

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
