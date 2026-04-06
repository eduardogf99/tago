import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthService {
  // Instancias privadas
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

  // Registro con Email y Contraseña
  Future<UserCredential> registrarUsuario({
    required String email,
    required String password,
    required String usuario,
    required String fechaNacimiento,
  }) async {
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    UserModel nuevoUsuario = UserModel(
      uid: result.user!.uid,
      email: email,
      usuario: usuario,
      fechaNacimiento: fechaNacimiento,
      isAdmin: false,
    );

    await _db.collection('usuarios').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());
    return result;
  }

  // Inicio de Sesión con Email/Usuario
  Future<void> iniciarSesion(String input, String password) async {
    String email = input;
    if (!input.contains('@')) {
      final query = await _db.collection('usuarios').where('usuario', isEqualTo: input).get();
      if (query.docs.isEmpty) throw 'Usuario no encontrado';
      email = query.docs.first.get('email');
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Inicio de sesión con google
  Future<UserCredential?> iniciarSesionConGoogle() async {
    try {
      // 1. Iniciar el selector de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // El usuario canceló la selección

      // 2. Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear la credencial para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 5. Si es un usuario nuevo, crear su ficha en Firestore
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        UserModel nuevoUsuario = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          usuario: userCredential.user!.displayName ?? 'Usuario Google',
          fechaNacimiento: 'No proporcionada', // Google no da la fecha de nacimiento
          isAdmin: false,
        );
        await _db.collection('usuarios').doc(nuevoUsuario.uid).set(nuevoUsuario.toMap());
      }

      return userCredential;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      rethrow;
    }
  }

  // Cerrar Sesión
  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut(); // También cerramos sesión en Google
    await _auth.signOut();
  }

  // Restablecer Contraseña
  Future<void> restablecerContrasena(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
