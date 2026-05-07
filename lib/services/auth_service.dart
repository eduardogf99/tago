import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  // Instancias privadas
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();
  
  // Client id qeu se pasa al json
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '1008380081377-fb1eln8kvg5dc0t0kvr4ggtuqrvheouh.apps.googleusercontent.com',
  );

  // Stream para vigilar el estado del usuario
  Stream<User?> get userState => _auth.authStateChanges();

  // Obtener el ID del usuario actual
  String? get currentUid => _auth.currentUser?.uid;

  // Obtener los datos del usuario actual
  Future<UserModel?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      return await _dbService.obtenerUsuario(user.uid);
    }
    return null;
  }

  // Verifica si un nombre de usuario ya existe
  Future<bool> usuarioExiste(String usuario) async {
    final usuarios = await _dbService.obtenerTodosLosUsuarios();
    return usuarios.any((u) => u.usuario.toLowerCase() == usuario.toLowerCase());
  }

  // Registro con Email y Contraseña
  Future<UserCredential> registrarUsuario({
    required String email,
    required String password,
    required String usuario,
    required String fechaNacimiento,
  }) async {
    // 1. Verificar si el nombre de usuario ya existe
    if (await usuarioExiste(usuario)) {
      throw 'El nombre de usuario ya está en uso';
    }

    // 2. Crear el usuario en Firebase Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 3. Crear el documento usando nuestro servicio
    UserModel nuevoUsuario = UserModel(
      uid: result.user!.uid,
      email: email,
      usuario: usuario,
      fechaNacimiento: fechaNacimiento,
      isAdmin: false,
    );

    await _dbService.actualizarUsuario(nuevoUsuario.uid, nuevoUsuario.toMap());
    return result;
  }

  // Inicio de Sesión con Email/Usuario
  Future<void> iniciarSesion(String input, String password) async {
    String email = input;
    if (!input.contains('@')) {
      final usuarios = await _dbService.obtenerTodosLosUsuarios();
      final userMatch = usuarios.where((u) => u.usuario == input);
      if (userMatch.isEmpty) throw 'Usuario no encontrado';
      email = userMatch.first.email;
    }
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Inicio de sesión con google
  Future<UserCredential?> iniciarSesionConGoogle() async {
    try {
      // 1. Iniciar el selector de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // 2. Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Crear la credencial para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // 5. Si es un usuario nuevo, crear su ficha a través de API REST
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        UserModel nuevoUsuario = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          usuario: userCredential.user!.displayName ?? 'Usuario Google',
          fechaNacimiento: 'No proporcionada',
          isAdmin: false,
        );
        await _dbService.actualizarUsuario(nuevoUsuario.uid, nuevoUsuario.toMap());
      }

      return userCredential;
    } catch (e) {
      print("Error en Google Sign-In: $e");
      rethrow;
    }
  }

  // Cerrar Sesión
  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Restablecer Contraseña
  Future<void> restablecerContrasena(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
