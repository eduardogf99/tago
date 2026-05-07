import 'package:flutter/material.dart';
import 'package:tfg/services/auth_service.dart';

import '../theme/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.restablecerContrasena(_emailController.text.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Se ha enviado un correo para restablecer tu contraseña.'),
              backgroundColor: AppColors.azulStamps, // Color informativo coherente
            ),
          );
          Navigator.pop(context); // Volver al login
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.azulOscuro,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.doradoClaro),
        title: const Text(
          'RESTABLECER',
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
              // Sustituimos Card por nuestro contenedor Passport
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.azulContenedor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: AppColors.doradoClaro.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset,
                      size: 70,
                      color: AppColors.doradoClaro,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'RECUPERAR ACCESO',
                      style: TextStyle(
                        color: AppColors.doradoClaro,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'Introduce tu correo electrónico y te enviaremos un enlace para cambiar tu contraseña.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.azulClaro, fontSize: 14),
                    ),
                    const SizedBox(height: 30),

                    // Campo de Email Estilizado
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: AppColors.doradoClaro,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: const TextStyle(color: AppColors.azulClaro),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.azulStamps),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.azulStamps),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.error, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, introduce tu correo';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Introduce un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),

                    _isLoading
                        ? const CircularProgressIndicator(color: AppColors.doradoClaro)
                        : ElevatedButton(
                      onPressed: _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.doradoClaro,
                        foregroundColor: AppColors.azulOscuro,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'ENVIAR ENLACE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(foregroundColor: AppColors.azulClaro),
                      child: const Text('Volver al inicio de sesión'),
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