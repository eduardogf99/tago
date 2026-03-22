class UserModel {
  final String uid;
  final String email;
  final String usuario;
  final String fechaNacimiento;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    required this.usuario,
    required this.fechaNacimiento,
    this.isAdmin = false, // Por defecto es falso
  });

  // Convierte un objeto UserModel a un Mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'usuario': usuario,
      'fechaNacimiento': fechaNacimiento,
      'isAdmin': isAdmin,
    };
  }

  // Crea un objeto UserModel a partir de un documento de Firestore
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      usuario: map['usuario'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
