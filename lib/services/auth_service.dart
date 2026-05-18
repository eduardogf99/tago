import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart'; // <-- IMPORTANTE: Añadimos intl para gestionar fechas aquí
import '../models/user_model.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth;
  final DatabaseService _dbService;
  final GoogleSignIn _googleSignIn;

  // Constructor con inyección de dependencias (usa las reales por defecto)
  AuthService({
    FirebaseAuth? auth,
    DatabaseService? dbService,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _dbService = dbService ?? DatabaseService(),
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          clientId: '1008380081377-fb1eln8kvg5dc0t0kvr4ggtuqrvheouh.apps.googleusercontent.com',
        );

  Stream<User?> get userState => _auth.authStateChanges();
  String? get currentUid => _auth.currentUser?.uid;

  Future<UserModel?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) return await _dbService.obtenerUsuario(user.uid);
    return null;
  }

  Future<bool> usuarioExiste(String usuario) async {
    final usuarios = await _dbService.obtenerTodosLosUsuarios();
    return usuarios.any((u) => u.usuario.toLowerCase() == usuario.toLowerCase());
  }

  // Inicio de sesión con google
  Future<UserCredential?> iniciarSesionConGoogle() async {
    try {
      // Iniciar el selector de cuentas de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Crear la credencial para Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión en Firebase
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Si es un usuario nuevo, crear su ficha a través de API REST
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // Ponemos una fecha válida por defecto o una estandarizada en vez de texto plano libre
        String fechaPorDefecto = DateFormat('dd-MM-yyyy').format(DateTime(2000, 1, 1));

        UserModel nuevoUsuario = UserModel(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          usuario: userCredential.user!.displayName ?? 'Usuario Google',
          fechaNacimiento: fechaPorDefecto, // <-- Cambiado para mantener coherencia de tipo fecha
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

  Future<UserCredential> registrarUsuario({
    required String email,
    required String password,
    required String usuario,
    required String fechaNacimiento,
  }) async {
    if (await usuarioExiste(usuario)) throw 'El nombre de usuario ya está en uso';

    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );


    String fechaNormalizada = fechaNacimiento;
    if (fechaNacimiento.contains('-') && fechaNacimiento.split('-')[0].length == 4) {
      DateTime parsedDate = DateTime.parse(fechaNacimiento);
      fechaNormalizada = DateFormat('dd-MM-yyyy').format(parsedDate);
    }

    UserModel nuevoUsuario = UserModel(
      uid: result.user!.uid,
      email: email,
      usuario: usuario,
      fechaNacimiento: fechaNormalizada, // <-- Guardamos la fecha asegurando el formato correcto
      isAdmin: false,
    );

    await _dbService.actualizarUsuario(nuevoUsuario.uid, nuevoUsuario.toMap());
    return result;
  }

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

  Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> restablecerContrasena(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}