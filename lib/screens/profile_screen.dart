import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final Color azulOscuro = const Color(0xFF0D1B2A);
  final Color azulContenedor = const Color(0xFF1B263B);
  final Color azulStamps = const Color(0xFF415A77);
  final Color doradoClaro = const Color(0xFFE0C17A);

  String? _usernameError;

  Future<int> _getCount(String uid, String collectionPath) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .collection(collectionPath)
          .get();
      return query.docs.length;
    } catch (e) {
      debugPrint("Error contando $collectionPath: $e");
      return 0;
    }
  }

  // --- NUEVA FUNCIÓN DE EDICIÓN COMPLETA ---
  Future<void> _showEditProfileDialog(UserModel user) async {
    final TextEditingController userController = TextEditingController(text: user.usuario);
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();
    String selectedDate = user.fechaNacimiento;
    _usernameError = null; // Reiniciar error al abrir

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: azulContenedor,
          title: Text('Editar Perfil', style: TextStyle(color: doradoClaro)),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: userController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre de usuario',
                    labelStyle: TextStyle(color: doradoClaro),
                    errorText: _usernameError, // Aquí se muestra el mensaje debajo
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: doradoClaro)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: doradoClaro)),
                    errorStyle: const TextStyle(color: Colors.redAccent),
                  ),
                  // Validador visual simple
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'El nombre no puede estar vacío';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Nacimiento: $selectedDate", style: const TextStyle(color: Colors.white)),
                    IconButton(
                      icon: Icon(Icons.calendar_month, color: doradoClaro),
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          // Personalización de colores del picker para que pegue con tu diseño
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.dark(
                                primary: doradoClaro,
                                onPrimary: azulOscuro,
                                surface: azulContenedor,
                              ),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            selectedDate = "${picked.toLocal()}".split(' ')[0];
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: doradoClaro),
              onPressed: () async {
                // 1. Validar campos básicos
                if (!dialogFormKey.currentState!.validate()) return;

                String nuevoUsuario = userController.text.trim();

                // 2. Comprobación asíncrona de usuario
                if (nuevoUsuario != user.usuario) {
                  // Mostramos un estado de carga opcional o simplemente bloqueamos
                  bool existe = await _authService.usuarioExiste(nuevoUsuario);
                  if (existe) {
                    setDialogState(() {
                      _usernameError = 'El nombre de usuario ya existe';
                    });
                    return;
                  }
                }

                // 3. Si todo está bien, actualizamos
                await _dbService.actualizarUsuario(user.uid, {
                  'usuario': nuevoUsuario,
                  'fechaNacimiento': selectedDate,
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: Text('Guardar', style: TextStyle(color: azulOscuro)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(String uid) async {
    File? image = await ImageHelper.mostrarSelector(context);
    if (image != null) {
      await _uploadImage(uid, image);
    }
  }

  Future<void> _uploadImage(String uid, File file) async {
    try {
      String downloadUrl = await _dbService.subirImagenPerfil(uid, file);
      await _dbService.actualizarUsuario(uid, {'photoUrl': downloadUrl});
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto de perfil actualizada')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? uid = _authService.currentUid;

    return Scaffold(
      backgroundColor: azulOscuro,
      body: uid == null
          ? const Center(child: Text("No hay sesión iniciada"))
          : FutureBuilder<UserModel?>(
        future: _dbService.obtenerUsuario(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Error al cargar perfil", style: TextStyle(color: Colors.white)));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 80),
                      Text(
                        'PASSPORT',
                        style: TextStyle(
                          color: doradoClaro,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 80),
                      Icon(Icons.language_outlined, color: doradoClaro, size: 110),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // --- CONTENEDOR PRINCIPAL CON BOTÓN DE EDICIÓN ---
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: azulContenedor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.35,
                                child: GestureDetector(
                                  onTap: () => _pickImage(uid),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 55,
                                        backgroundColor: doradoClaro,
                                        child: CircleAvatar(
                                          radius: 52,
                                          backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                                              ? NetworkImage(user.photoUrl!)
                                              : null,
                                          child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                                              ? Icon(Icons.person, size: 50, color: azulOscuro)
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 10,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: doradoClaro,
                                          child: Icon(Icons.camera_alt, size: 15, color: azulOscuro),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.usuario,
                                      style: TextStyle(color: doradoClaro, fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      user.fechaNacimiento,
                                      style: TextStyle(color: doradoClaro.withOpacity(0.8), fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "ID: ${user.uid.substring(0, 12)}...",
                                      style: TextStyle(color: doradoClaro.withOpacity(0.8), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),

                          Row(
                            children: [
                              Icon(Icons.email_outlined, color: doradoClaro, size: 18),
                              const SizedBox(width: 10),
                              Text(user.email, style: TextStyle(color: doradoClaro, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 25),

                          FutureBuilder<List<int>>(
                            future: Future.wait([
                              _getCount(uid, 'escaneos'),
                              _getCount(uid, 'creados'),
                            ]),
                            builder: (context, statsSnapshot) {
                              String escaneados = statsSnapshot.hasData ? statsSnapshot.data![0].toString() : "...";
                              String creados = statsSnapshot.hasData ? statsSnapshot.data![1].toString() : "...";

                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildStatColumn("TaGo's\nescaneados", escaneados),
                                  _buildStatColumn("TaGo's\ncreados", creados),
                                  _buildStatColumn("Países\nvisitados", user.paisesDescubiertos.length.toString()),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 25),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'STAMPS',
                              style: TextStyle(color: doradoClaro, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: azulStamps,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: user.paisesDescubiertos.isEmpty
                                ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: Text("No hay sellos aún", style: TextStyle(color: Colors.white60))),
                            )
                                : GridView.builder(
                              padding: const EdgeInsets.only(top: 10, bottom: 10, left: 8, right: 8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 15,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: user.paisesDescubiertos.length,
                              itemBuilder: (context, index) {
                                String codigo = user.paisesDescubiertos[index].toLowerCase();
                                return Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: doradoClaro, width: 4),
                                  ),
                                  child: ClipOval(
                                    child: SvgPicture.network(
                                      'https://flagcdn.com/$codigo.svg',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
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
                              icon: const Icon(Icons.logout),
                              label: const Text('CERRAR SESIÓN'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // BOTÓN DE EDICIÓN EN LA ESQUINA
                    Positioned(
                      top: 10,
                      right: 25,
                      child: IconButton(
                        icon: Icon(Icons.edit, color: doradoClaro, size: 24),
                        onPressed: () => _showEditProfileDialog(user),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: doradoClaro.withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(color: doradoClaro, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}