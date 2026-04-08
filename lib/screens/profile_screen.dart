import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

  // Función para mostrar el diálogo de edición de texto
  Future<void> _showEditDialog(String label, String currentValue, String field, String uid) async {
    final TextEditingController controller = TextEditingController(text: currentValue);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar $label'),
        content: TextFormField(
          controller: controller,
          decoration: InputDecoration(hintText: "Introduce nuevo $label"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _dbService.actualizarUsuario(uid, {field: controller.text.trim()});
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refrescar pantalla
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  // Función para editar la fecha de nacimiento con un DatePicker
  Future<void> _editBirthDate(String uid, String currentPath) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      String formattedDate = "${pickedDate.toLocal()}".split(' ')[0];
      await _dbService.actualizarUsuario(uid, {'fechaNacimiento': formattedDate});
      setState(() {});
    }
  }

  // Función para seleccionar imagen
  Future<void> _pickImage(String uid) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  _uploadImage(uid, File(image.path));
                }
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () async {
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  _uploadImage(uid, File(image.path));
                }
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage(String uid, File file) async {
    try {
      String downloadUrl = await _dbService.subirImagenPerfil(uid, file);
      await _dbService.actualizarUsuario(uid, {'photoUrl': downloadUrl});
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String? uid = _authService.currentUid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.white, // O el color que prefieras
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
                      // Imagen de perfil interactiva
                      Center(
                        child: GestureDetector(
                          onTap: () => _pickImage(uid),
                          child: Stack(
                            children: [
                              Container(
                                width: screenWidth * 0.3,
                                height: screenWidth * 0.3,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  shape: BoxShape.circle,
                                  image: user.photoUrl != null
                                      ? DecorationImage(
                                          image: NetworkImage(user.photoUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: user.photoUrl == null
                                    ? const Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Fila Usuario
                      _buildInfoRow('Usuario', user.usuario, () => _showEditDialog('Usuario', user.usuario, 'usuario', uid)),
                      const Divider(),

                      // Fila Correo (Normalmente no se edita así por seguridad, pero dejamos el lápiz si quieres)
                      _buildInfoRow('Correo', user.email, null), 
                      const Divider(),

                      // Fila Fecha de nacimiento
                      _buildInfoRow('Fecha de nacimiento', user.fechaNacimiento, () => _editBirthDate(uid, user.fechaNacimiento)),
                      const Divider(),

                      // Fila ID Amigo (Solo lectura)
                      _buildInfoRow('ID amigo', '${user.uid.substring(0, 8)}...', null),
                      const Divider(),

                      // Placeholder TaGo's
                      _buildInfoRow('TaGo\'s creados', '0', null),
                      const Divider(),

                      const SizedBox(height: 20),
                      
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

  Widget _buildInfoRow(String label, String value, VoidCallback? onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 20),
            ),
        ],
      ),
    );
  }
}
