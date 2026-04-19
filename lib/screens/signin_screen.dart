import 'package:flutter/material.dart';
import 'package:tfg/screens/login_screen.dart';
import 'package:tfg/screens/main_screen.dart';
import 'package:tfg/services/auth_service.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  bool _acceptTerms = false;
  bool _isCheckingUser = false;
  String? _usernameError; // Almacena el error de disponibilidad del servidor
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  Future<void> _ejecutarRegistro() async {
    // 1. Validaciones básicas locales
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    setState(() {
      _isCheckingUser = true;
      _usernameError = null; // Limpiamos error previo
    });
    
    try {
      // 2. Intentamos el registro (el servicio comprobará la disponibilidad)
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
      if (mounted) {
        final errorMsg = e.toString();
        // 3. Si el error es de nombre en uso, lo mandamos al validador del campo
        if (errorMsg.contains('en uso')) {
          setState(() {
            _usernameError = 'El nombre de usuario ya está en uso';
          });
          // Forzamos al formulario a redibujar los errores
          _formKey.currentState!.validate();
        } else {
          // Otros errores (email, red, etc.) se muestran en SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isCheckingUser = false);
    }
  }

  // Función para el login con Google
  Future<void> _loginGoogle() async {
    try {
      final user = await _authService.iniciarSesionConGoogle();
      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error Google: ${e.toString()}")),
        );
      }
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
                      onPressed: _loginGoogle,
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
                      onChanged: (value) {
                        // Limpiamos el error del servidor al empezar a escribir de nuevo
                        if (_usernameError != null) {
                          setState(() {
                            _usernameError = null;
                          });
                        }
                      },
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
                        if (_usernameError != null) {
                          return _usernameError;
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
                      readOnly: true,
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
                    
                    _isCheckingUser 
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                      onPressed: _ejecutarRegistro,
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
