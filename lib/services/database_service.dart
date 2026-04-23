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


  //de momento esto accede de forma directa a firestone. Si tarda más de 3 secs en acceder mediante api rest
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

  //MARCADORES

  Future<List<MapMarkerModel>> obtenerMarcadores() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/marcadores'))
          .timeout(const Duration(seconds: 2));
      
      if (response.statusCode == 200) {
        List<dynamic> body = json.decode(response.body);
        return body.map((item) => MapMarkerModel.fromMap(item)).toList();
      }
      return await _obtenerMarcadoresFirestore();
    } catch (e) {
      return await _obtenerMarcadoresFirestore();
    }
  }

  Future<void> crearMarcador(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/marcadores'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"id": id, ...data}),
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode != 201) {
        await _db.collection('marcadores').doc(id).set(data);
      }
    } catch (e) {
      await _db.collection('marcadores').doc(id).set(data);
    }
  }

  //USUARIOS

  Future<List<UserModel>> obtenerTodosLosUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/usuarios'))
          .timeout(const Duration(seconds: 2));

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
          .timeout(const Duration(seconds: 2));

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
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode != 200) {
        await _db.collection('usuarios').doc(uid).set(data, SetOptions(merge: true));
      }
    } catch (e) {

      await _db.collection('usuarios').doc(uid).set(data, SetOptions(merge: true));
    }
  }

  // IMÁGENES

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
