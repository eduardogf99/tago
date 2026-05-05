import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'signin_screen.dart';
import 'reset_password_screen.dart';
import '../widgets/login_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo oscuro general de la app
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'BIENVENIDO',
          style: TextStyle(
            color: AppColors.doradoClaro,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              // Sustituimos Card por un Container estilizado
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.azulContenedor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.doradoClaro.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo o Icono representativo arriba del formulario
                  const Icon(
                    Icons.language_outlined,
                    size: 80,
                    color: AppColors.doradoClaro,
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                      color: AppColors.doradoClaro,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Widget que contiene los TextFields y botones de login
                  // Nota: Asegúrate de que LoginForm también use AppColors
                  const LoginForm(),

                  const SizedBox(height: 20),
                  const Divider(color: AppColors.azulStamps, thickness: 1),
                  const SizedBox(height: 10),

                  // Sección de Restablecer Contraseña
                  const Text(
                    '¿Olvidó su contraseña?',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                      );
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.azulClaro),
                    child: const Text('Restablecer contraseña'),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(color: AppColors.azulStamps, indent: 40, endIndent: 40),
                  ),

                  // Sección de Registro
                  const Text(
                    '¿Aún no tienes cuenta?',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SigninScreen()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.doradoClaro,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Registrarse ahora'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}