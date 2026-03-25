import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  // Instancias privadas de Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream para vigilar el estado del usuario
  Stream<User?> get userState => _auth.authStateChanges();

  // Obtener el ID del usuario actual
  String? get currentUid => _auth.currentUser?.uid;

  // Obtener los datos del usuario actual (incluido isAdmin)
  Future<UserModel?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db.collection('usuarios').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }

  Future<UserCredential> registrarUsuario({
    required String email,
    required String password,
    required String usuario,
    required String fechaNacimiento,
  }) async {
    // Crea el usuario en Firebase Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Creamos el objeto UserModel (isAdmin será false por defecto)
    UserModel nuevoUsuario = UserModel(
      uid: result.user!.uid,
      email: email,
      usuario: usuario,
      fechaNacimiento: fechaNacimiento,
      isAdmin: false, // Por defecto no es admin
    );

    // Guardamos en Firestore usando el toMap() del modelo
    await _db.collection('usuarios').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());

    return result;
  }

  // Función de Inicio de Sesión
  Future<void> iniciarSesion(String input, String password) async {
    String email = input;
    if (!input.contains('@')) {
      final query = await _db.collection('usuarios').where('usuario', isEqualTo: input).get();
      if (query.docs.isEmpty) throw 'Usuario no encontrado';
      email = query.docs.first.get('email');
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Función de Cerrar Sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }
}
