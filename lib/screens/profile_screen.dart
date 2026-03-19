import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Obtenemos el usuario actual de Firebase Auth
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Función para obtener los datos del usuario desde Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserData() async {
    return await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(currentUser?.uid)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: getUserData(),
        builder: (context, snapshot) {
          // 1. Mientras carga los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Si ocurre un error
          if (snapshot.hasError) {
            return Center(child: Text("Error al cargar datos: ${snapshot.error}"));
          }

          // 3. Si no hay datos o el documento no existe
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No se encontraron datos del usuario"));
          }

          // 4. Si todo está bien, extraemos los datos
          var userData = snapshot.data!.data();
          String usuario = userData?['usuario'] ?? 'No disponible';
          String email = userData?['email'] ?? 'No disponible';
          String fechaNac = userData?['fechaNacimiento'] ?? 'No disponible';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Imagen de perfil
                  Center(
                    child: Container(
                      width: screenWidth * 0.3,
                      height: screenWidth * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://via.placeholder.com/150',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, size: 50),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Fila Usuario
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Usuario: $usuario',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Fila Correo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Correo: $email',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Fila Fecha de nacimiento
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fecha de nacimiento: $fechaNac',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Fila ID Amigo (Usando el UID truncado como ejemplo)
                  Row(
                    children: [
                      Text(
                        'ID amigo: ${currentUser?.uid.substring(0, 8)}...',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Fila TaGo\'s creados (Placeholder)
                  const Row(
                    children: [
                      Text(
                        'TaGo\'s creados: 0',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const Divider(),

                  const SizedBox(height: 20),
                  // Botón cerrar sesión
                  SizedBox(
                    width: screenWidth * 0.4,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut(); // Cierra sesión en Firebase
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
