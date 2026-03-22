import 'package:flutter/material.dart';
import 'package:tfg/models/user_model.dart';
import 'package:tfg/services/auth_service.dart';
import 'package:tfg/services/database_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String? uid = _authService.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: uid == null 
        ? const Center(child: Text("No hay sesión iniciada"))
        : FutureBuilder<UserModel?>(
            future: _dbService.obtenerUsuario(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text("Error al cargar los datos del perfil"));
              }

              final user = snapshot.data!;

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
                          child: const ClipOval(
                            child: Icon(Icons.person, size: 50),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Fila Usuario
                      _buildInfoRow('Usuario', user.usuario),
                      const Divider(),

                      // Fila Correo
                      _buildInfoRow('Correo', user.email),
                      const Divider(),

                      // Fila Fecha de nacimiento
                      _buildInfoRow('Fecha de nacimiento', user.fechaNacimiento),
                      const Divider(),

                      // Fila ID Amigo
                      _buildInfoRow('ID amigo', '${user.uid.substring(0, 8)}...'),
                      const Divider(),

                      // Placeholder TaGo's
                      _buildInfoRow('TaGo\'s creados', '0'),
                      const Divider(),

                      const SizedBox(height: 20),
                      
                      // Botón cerrar sesión usando el servicio
                      SizedBox(
                        width: screenWidth * 0.4,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _authService.cerrarSesion();
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

  // Widget auxiliar para no repetir código de filas
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label: $value',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          ),
          IconButton(
            onPressed: () {}, // Funcionalidad futura
            icon: const Icon(Icons.edit, size: 20),
          ),
        ],
      ),
    );
  }
}
