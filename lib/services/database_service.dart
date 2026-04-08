import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final CollectionReference _usuariosRef = 
      FirebaseFirestore.instance.collection('usuarios');
  final CollectionReference _marcadoresRef = 
      FirebaseFirestore.instance.collection('marcadores');

  Future<UserModel?> obtenerUsuario(String uid) async {
    try {
      DocumentSnapshot doc = await _usuariosRef.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error al obtener usuario: $e");
      rethrow;
    }
  }

  // Usamos set con merge para que funcione tanto si el documento existe como si no
  Future<void> actualizarUsuario(String uid, Map<String, dynamic> data) async {
    try {
      await _usuariosRef.doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      print("Error al actualizar usuario: $e");
      rethrow;
    }
  }

  // Subida de imagen de perfil
  Future<String> subirImagenPerfil(String uid, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('perfiles').child('$uid.jpg');
      UploadTask uploadTask = ref.putFile(
        imageFile, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      print("URL Perfil generada: $url");
      return url;
    } catch (e) {
      print("Error en subirImagenPerfil: $e");
      rethrow;
    }
  }

  // Subida de imagen de marcador (TaGo)
  Future<String> subirImagenMarcador(String id, File imageFile) async {
    try {
      Reference ref = _storage.ref().child('marcadores_images').child('$id.jpg');
      UploadTask uploadTask = ref.putFile(
        imageFile, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      TaskSnapshot snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      print("URL Marcador generada: $url");
      return url;
    } catch (e) {
      print("Error en subirImagenMarcador: $e");
      rethrow;
    }
  }

  Future<void> crearMarcador(String id, Map<String, dynamic> data) async {
    try {
      await _marcadoresRef.doc(id).set(data);
    } catch (e) {
      print("Error al crear marcador: $e");
      rethrow;
    }
  }
}
