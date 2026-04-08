import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final CollectionReference _usuariosRef = 
      FirebaseFirestore.instance.collection('usuarios');

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

  // Actualizar datos del usuario (nombre, fecha, etc.)
  Future<void> actualizarUsuario(String uid, Map<String, dynamic> data) async {
    await _usuariosRef.doc(uid).update(data);
  }

  // Subir imagen a Firebase Storage y devolver la URL
  Future<String> subirImagenPerfil(String uid, File imageFile) async {
    Reference ref = _storage.ref().child('perfiles').child('$uid.jpg');
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
