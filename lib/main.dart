import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/tago_screen.dart'; // Importamos la pantalla de Tago
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Definimos un GlobalKey para navegar sin contexto si es necesario
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Iniciamos la escucha de NFC en segundo plano
  _initNfcListener();
  
  runApp(const MyApp());
}

// Función para manejar el desbloqueo y navegación
Future<void> _handleTagoUnlock(String scannedId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  try {
    // 1. Verificar si el Tago existe en la base de datos global
    final tagoDoc = await FirebaseFirestore.instance.collection('marcadores').doc(scannedId).get();
    if (!tagoDoc.exists) {
      debugPrint("TaGo con ID $scannedId no encontrado en Firestore");
      return;
    }

    final data = tagoDoc.data() as Map<String, dynamic>;
    final String titulo = data['titulo'] ?? 'Sin título';

    // 2. Verificar si el usuario ya lo ha escaneado antes
    final scanDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('escaneos')
        .doc(scannedId)
        .get();

    final context = navigatorKey.currentContext;
    if (context == null) return;

    if (!scanDoc.exists) {
      // ES NUEVO: Desbloquear en Firebase
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('escaneos')
          .doc(scannedId)
          .set({'fechaEscaneo': FieldValue.serverTimestamp()});

      // Mostrar el AlertDialog de "Nuevo TaGo desbloqueado"
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.stars, color: Colors.amber),
              SizedBox(width: 10),
              Text("¡Nuevo TaGo!"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Has desbloqueado un nuevo sitio:"),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Cerrar dialog
                navigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (context) => TagoScreen(tagoId: scannedId)),
                );
              },
              child: const Text("Ver"),
            ),
          ],
        ),
      );
    } else {
      // YA ESTABA DESBLOQUEADO: Mostrar aviso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 10),
              Text("Ya desbloqueado"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Este TaGo ya está en tu colección:"),
              const SizedBox(height: 10),
              Text(
                titulo,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cerrar"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // Cerrar dialog
                navigatorKey.currentState?.push(
                  MaterialPageRoute(builder: (context) => TagoScreen(tagoId: scannedId)),
                );
              },
              child: const Text("Ver"),
            ),
          ],
        ),
      );
    }
  } catch (e) {
    debugPrint("Error al procesar NFC: $e");
  }
}

void _initNfcListener() async {
  try {
    bool isAvailable = await NfcManager.instance.isAvailable();
    if (!isAvailable) return;

    // Esta sesión se queda escuchando mientras la app esté activa
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      var ndef = Ndef.from(tag);
      if (ndef != null && ndef.cachedMessage != null) {
        final records = ndef.cachedMessage!.records;
        if (records.isNotEmpty) {
          String payload = String.fromCharCodes(records.first.payload);
          // Extraer ID (saltando el prefijo de lenguaje de NDEF)
          String scannedId = payload.substring(records.first.payload[0] + 1);
          _handleTagoUnlock(scannedId);
        }
      }
    });
  } catch (e) {
    debugPrint("Error iniciando lector NFC persistente: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaGo',
      navigatorKey: navigatorKey, // Asignamos la llave global
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
