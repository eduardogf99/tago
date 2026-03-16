class UserController {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    bool hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasNumber;
  }

  static String? validateRegistration({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
    required bool acceptedTerms,
  }) {
    if (email.isEmpty || !isValidEmail(email)) {
      return 'Introduce un correo electrónico válido.';
    }
    if (username.isEmpty) {
      return 'El usuario no puede estar vacío.';
    }
    if (!isValidPassword(password)) {
      return 'La contraseña debe tener al menos 8 caracteres, incluyendo letras y números.';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden.';
    }
    if (!acceptedTerms) {
      return 'Debes aceptar los términos y condiciones.';
    }
    return null; // Todo correcto
  }
}
