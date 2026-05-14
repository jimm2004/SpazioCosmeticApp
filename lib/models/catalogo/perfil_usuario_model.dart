class PerfilUsuarioModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool activo;

  const PerfilUsuarioModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.activo = true,
  });

  factory PerfilUsuarioModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map ? Map<String, dynamic>.from(json['data']) : json;
    final user = data['user'] is Map ? Map<String, dynamic>.from(data['user']) : data;
    return PerfilUsuarioModel(
      id: _toInt(user['id']),
      name: (user['name'] ?? user['nombre'] ?? '').toString(),
      email: (user['email'] ?? '').toString(),
      role: (user['role'] ?? user['rol'] ?? 'cliente').toString(),
      activo: _toBool(user['activo'] ?? user['estado'] ?? true),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    final text = value?.toString().toLowerCase().trim() ?? '';
    if (text == 'inactivo' || text == '0' || text == 'false') return false;
    return true;
  }
}
