import 'package:flutter/material.dart';
import 'package:tfg/screens/login_screen.dart';
import 'package:tfg/screens/main_screen.dart';
import 'package:tfg/services/auth_service.dart';

import '../theme/app_colors.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  bool _acceptTerms = false;
  bool _isCheckingUser = false;
  String? _usernameError;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController repeatPasswordController = TextEditingController();
  final TextEditingController birthDateController = TextEditingController();

  Future<void> _ejecutarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes aceptar los términos y condiciones'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isCheckingUser = true;
      _usernameError = null;
    });

    try {
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
        if (errorMsg.contains('en uso')) {
          setState(() {
            _usernameError = 'El nombre de usuario ya está en uso';
          });
          _formKey.currentState!.validate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isCheckingUser = false);
    }
  }

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
          SnackBar(
            content: Text("Error Google: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
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
          'REGISTRO',
          style: TextStyle(color: AppColors.doradoClaro, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.azulContenedor,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.doradoClaro.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_add_outlined, size: 60, color: AppColors.doradoClaro),
                  const SizedBox(height: 20),

                  // Botón Google
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _loginGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('CONTINUAR CON GOOGLE'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.doradoClaro,
                        side: const BorderSide(color: AppColors.doradoClaro),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.azulStamps)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("O", style: TextStyle(color: AppColors.azulStamps)),
                      ),
                      Expanded(child: Divider(color: AppColors.azulStamps)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(emailController, 'Correo electrónico', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),

                  _buildTextField(userController, 'Usuario', Icons.person_outline, errorText: _usernameError),
                  const SizedBox(height: 15),

                  _buildTextField(passwordController, 'Contraseña', Icons.lock_outline, obscureText: true),
                  const SizedBox(height: 15),

                  _buildTextField(repeatPasswordController, 'Repetir Contraseña', Icons.lock_reset, obscureText: true, isRepeat: true),
                  const SizedBox(height: 15),

                  _buildDatePicker(),
                  const SizedBox(height: 15),

                  Theme(
                    data: ThemeData(unselectedWidgetColor: AppColors.doradoClaro),
                    child: CheckboxListTile(
                      value: _acceptTerms,
                      onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                      title: const Text('Acepto los términos y condiciones', style: TextStyle(color: Colors.white, fontSize: 13)),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.doradoClaro,
                      checkColor: AppColors.azulOscuro,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _isCheckingUser
                      ? const CircularProgressIndicator(color: AppColors.doradoClaro)
                      : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _ejecutarRegistro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.doradoClaro,
                        foregroundColor: AppColors.azulOscuro,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ),
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
                    child: const Text('¿Ya tienes cuenta? Inicia sesión', style: TextStyle(color: AppColors.azulClaro)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper para TextFields
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType, String? errorText, bool isRepeat = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      cursorColor: AppColors.doradoClaro,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.azulClaro),
        prefixIcon: Icon(icon, color: AppColors.azulStamps),
        errorText: errorText,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.azulStamps)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 2)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Campo requerido';
        if (label == 'Correo electrónico') {
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email no válido';
        }
        if (label == 'Usuario') {
          if (value.length < 3) return 'Mínimo 3 caracteres';
          if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) return 'Solo letras y números';
          if (_usernameError != null) return _usernameError;
        }
        if (label == 'Contraseña' && value.length < 8) return 'Mínimo 8 caracteres';
        if (isRepeat && value != passwordController.text) return 'Las contraseñas no coinciden';
        return null;
      },
    );
  }

  // Helper para DatePicker
  Widget _buildDatePicker() {
    return TextFormField(
      controller: birthDateController,
      readOnly: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Fecha de nacimiento',
        labelStyle: const TextStyle(color: AppColors.azulClaro),
        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.azulStamps),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.azulStamps)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.doradoClaro, width: 2)),
      ),
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.doradoClaro,
                  onPrimary: AppColors.azulOscuro,
                  surface: AppColors.azulContenedor,
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: AppColors.azulOscuro,
              ),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            birthDateController.text = "${pickedDate.toLocal()}".split(' ')[0];
          });
        }
      },
    );
  }
}