class UserModel {
  final String uid;
  final String email;
  final String usuario;
  final String fechaNacimiento;
  final String? photoUrl; // Nuevo campo para la foto
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.email,
    required this.usuario,
    required this.fechaNacimiento,
    this.photoUrl,
    this.isAdmin = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'usuario': usuario,
      'fechaNacimiento': fechaNacimiento,
      'photoUrl': photoUrl,
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      usuario: map['usuario'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      photoUrl: map['photoUrl'],
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
