import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tfg/models/user_model.dart';
import 'package:tfg/services/auth_service.dart';
import 'package:tfg/services/database_service.dart';
import 'package:tfg/widgets/image_helper.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final DatabaseService _dbService = DatabaseService();

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
              String newValue = controller.text.trim();
              if (newValue.isNotEmpty) {
                // Si estamos editando el usuario y ha cambiado, comprobamos si ya existe
                if (field == 'usuario' && newValue != currentValue) {
                  bool exists = await _authService.usuarioExiste(newValue);
                  if (exists) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('El nombre de usuario ya está en uso'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }
                }

                await _dbService.actualizarUsuario(uid, {field: newValue});
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {}); // Refrescar para ver los cambios
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

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

  Future<void> _pickImage(String uid) async {
    File? image = await ImageHelper.mostrarSelector(context);
    if (image != null) {
      await _uploadImage(uid, image);
    }
  }

  Future<void> _uploadImage(String uid, File file) async {
    try {
      // 1. Subimos la imagen al Storage y obtenemos la URL
      String downloadUrl = await _dbService.subirImagenPerfil(uid, file);

      // 2. IMPORTANTE: Guardamos esa URL en el campo 'photoUrl' de Firestore
      await _dbService.actualizarUsuario(uid, {'photoUrl': downloadUrl});

      // 3. Refrescamos la UI
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la foto: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    String? uid = _authService.currentUid;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(122, 30, 44, 1),
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(
            color: Color.fromRGBO(201, 162, 39, 1),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                      const SizedBox(height: 30),
                      const Text(
                        'PASSPORT',
                        style: TextStyle(
                          color: Color.fromRGBO(201, 162, 39, 1),
                          fontSize: 50,
                          fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),
                      Icon(
                        Icons.language_outlined,
                        size: screenWidth * 0.5,
                        color: const Color.fromRGBO(201, 162, 39, 1),
                      ),
                      const SizedBox(height: 80),
                      // Imagen de perfil con detección de cambios
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
                                  border: Border.all(
                                    color: const Color.fromRGBO(201, 162, 39, 1),
                                    width: 5,
                                  ),
                                  image: user.photoUrl != null && user.photoUrl!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(user.photoUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                    ? Icon(Icons.person, size: screenWidth * 0.15, color: Colors.grey[700])
                                    : null,
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color.fromRGBO(201, 162, 39, 1),
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

                      _buildInfoRow('Usuario', user.usuario, () => _showEditDialog('Usuario', user.usuario, 'usuario', uid)),
                      const Divider(
                        color: Color.fromRGBO(197, 179, 129, 1.0),
                        thickness: 1,
                      ),
                      _buildInfoRow('Correo', user.email, null),
                      const Divider(
                        color: Color.fromRGBO(197, 179, 129, 1.0),
                        thickness: 1,
                      ),
                      _buildInfoRow('Fecha de nacimiento', user.fechaNacimiento, () => _editBirthDate(uid, user.fechaNacimiento)),
                      const Divider(
                        color: Color.fromRGBO(197, 179, 129, 1.0),
                        thickness: 1,
                      ),
                      _buildInfoRow('ID amigo', '${user.uid.substring(0, 8)}...', null),
                      const Divider(
                        color: Color.fromRGBO(197, 179, 129, 1.0),
                        thickness: 1,
                      ),
                      _buildInfoRow('TaGo\'s creados', '0', null),
                      const Divider(
                        color: Color.fromRGBO(197, 179, 129, 1.0),
                        thickness: 1,
                      ),

                      // SECCIÓN DE ESTAMPITAS (PAÍSES DESCUBIERTOS)
                      if (user.paisesDescubiertos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Stamps',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(201, 162, 39, 1),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 por fila
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.5, // Ajuste para que las banderas se vean bien
                          ),
                          itemCount: user.paisesDescubiertos.length,
                          itemBuilder: (context, index) {
                            String codigo = user.paisesDescubiertos[index].toLowerCase();
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SvgPicture.network(
                                  'https://flagcdn.com/$codigo.svg',
                                  fit: BoxFit.cover,
                                  placeholderBuilder: (context) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        const Divider(
                          color: Color.fromRGBO(197, 179, 129, 1.0),
                          thickness: 1,
                        ),
                      ],

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
                            backgroundColor: const Color.fromRGBO(201, 162, 39, 0.1),
                            foregroundColor: const Color.fromRGBO(201, 162, 39, 1),
                            side: const BorderSide(color: Color.fromRGBO(201, 162, 39, 1)),
                          ),
                          child: const Text('Cerrar sesión'),

                        ),
                      ),
                      const SizedBox(height: 20),
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
              style: const TextStyle(
                color: Color.fromRGBO(209, 180, 77, 1.0),
                fontSize: 17, fontWeight: FontWeight.w500,
              )
            ),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 20),
              color: const Color.fromRGBO(201, 162, 39, 1),
            ),
        ],
      ),
    );
  }
}
