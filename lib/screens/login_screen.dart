import 'package:flutter/material.dart';
import 'signin_screen.dart';
import 'reset_password_screen.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de Sesión'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Aquí llamamos al nuevo widget que contiene toda la lógica
                    const LoginForm(),
                    
                    const SizedBox(height: 15),
                    const Divider(),
                    
                    // Sección de Restablecer Contraseña
                    const Text('¿Olvidó su contraseña?'),
                    TextButton(
                      onPressed: () {
                        // Navegación a la pantalla de restablecer
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                        );
                      },
                      child: const Text('Restablecer contraseña'),
                    ),

                    const Divider(),

                    // Sección de Registro
                    const Text('¿Aún no tienes cuenta?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SigninScreen()),
                        );
                      },
                      child: const Text('Registrarse'),
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
