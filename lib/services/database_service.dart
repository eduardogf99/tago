import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class DatabaseService {
  // 1. Instancia privada de Firestore
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 2. Referencia a la colección de usuarios
  final CollectionReference _usuariosRef = 
      FirebaseFirestore.instance.collection('usuarios');

  // 3. Obtener los datos de un usuario por su UID
  Future<UserModel?> obtenerUsuario(String uid) async {
    try {
      DocumentSnapshot doc = await _usuariosRef.doc(uid).get();
      
      if (doc.exists) {
        // Convertimos el documento de Firestore en nuestro objeto UserModel
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error al obtener usuario: $e");
      rethrow;
    }
  }

  // Future<void> actualizarPerfil(UserModel usuario) async { ... }
  // Future<void> crearTago(TagoModel tago) async { ... }
}
