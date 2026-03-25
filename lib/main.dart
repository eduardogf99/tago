import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart'; // Importamos la pantalla principal
import 'package:firebase_auth/firebase_auth.dart'; // Importamos Firebase Auth

// imports de firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase conectado");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Usamos un StreamBuilder para escuchar el estado de la sesión
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Si Firebase aún está cargando el estado de la sesión, mostramos un indicador
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // Si hay datos en el snapshot, significa que el usuario ya está logueado
          if (snapshot.hasData) {
            return const MainScreen();
          }
          // Si no, el usuario no está logueado y va al Login
          return const LoginScreen();
        },
      ),
    );
  }
}