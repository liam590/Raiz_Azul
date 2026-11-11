class UserModel {
  final int id;
  final String nombreCompleto;
  final String username;
  final String? correo;
  final String rol;
  final int? idFinca;

  UserModel({
    required this.id,
    required this.nombreCompleto,
    required this.username,
    this.correo,
    required this.rol,
    this.idFinca,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['IdUsuario'] ?? 0,
      nombreCompleto: json['nombre_completo'] ?? json['Nombre'] ?? json['nombre'] ?? '',
      username: json['username'] ?? json['Username'] ?? '',
      correo: json['correo'] ?? json['Correo'],
      rol: json['rol'] ?? json['Rol'] ?? 'Productor',
      idFinca: json['id_finca'] ?? json['IdFinca'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'username': username,
      'correo': correo,
      'rol': rol,
      'id_finca': idFinca,
    };
  }
}