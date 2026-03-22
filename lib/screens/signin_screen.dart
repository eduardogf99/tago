import 'package:flutter/material.dart';
import 'package:tfg/screens/login_screen.dart';
import 'package:tfg/screens/main_screen.dart';
import 'package:tfg/services/auth_service.dart'; // Importamos el servicio

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  bool _acceptTerms = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Instancia del servicio
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  Future<void> _ejecutarRegistro() async {
    try {
      // Servicio para registrar
      await _authService.registrarUsuario(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        usuario: userController.text.trim(),
        fechaNacimiento: birthDateController.text.trim(),
      );

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al registrar: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Registrarse',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Implementar login con Google si es necesario
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('con google'),
                    ),
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce un correo';
                        }
                        final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegExp.hasMatch(value)) {
                          return 'Introduce un correo electrónico válido';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        border: OutlineInputBorder(),
                        hintText: 'ejemplo@correo.com',
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: userController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce un usuario';
                        } else if (value.length < 3) {
                          return 'El usuario debe tener al menos 3 caracteres';
                        } else if (value.length > 15) {
                          return 'El usuario no puede tener más de 15 caracteres';
                        } else if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                          return 'El usuario solo puede contener letras y números';
                        }
                        return null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce una contraseña';
                        } else if (value.length < 8) {
                          return 'La contraseña debe tener al menos 8 caracteres';
                        } else if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                          return 'La contraseña debe contener al menos una letra';
                        } else if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'La contraseña debe contener al menos un número';
                        }
                        return null;
                      },
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: repeatPasswordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, repite la contraseña';
                        } else if (value != passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Repetir Contraseña',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: birthDateController,
                      readOnly: true, // Evita teclado manual
                      decoration: const InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona tu fecha de nacimiento';
                        }
                        return null;
                      },
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          birthDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (value) {
                            setState(() {
                              _acceptTerms = value ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text('Acepto los términos y condiciones'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (!_acceptTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
                            );
                            return;
                          }
                          // Si todo es correcto, llamamos a la función que usa el servicio
                          _ejecutarRegistro();
                        }
                      },
                      child: const Text('Registrarse'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
