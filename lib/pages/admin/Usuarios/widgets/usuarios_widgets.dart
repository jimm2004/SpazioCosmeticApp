import 'package:flutter/material.dart';

bool usuarioActivo(Map<String, dynamic> user) {
  return user['activo'] == true || user['activo'] == 1;
}

String usuarioRole(Map<String, dynamic> user) {
  return user['role']?.toString() ?? 'cliente';
}

String usuarioTipo(Map<String, dynamic> user) {
  final tipo = user['tipo_usuario']?.toString();

  if (tipo != null && tipo.isNotEmpty) {
    return tipo;
  }

  final role = usuarioRole(user).toLowerCase();

  if (role == 'administrador' || role == 'despacho') {
    return 'personal_administrativo';
  }

  return 'cliente';
}

Color roleColor(String role) {
  final r = role.toLowerCase();

  if (r == 'administrador') return const Color(0xFFE91E63);
  if (r == 'despacho') return const Color(0xFFF5A623);

  return const Color(0xFF4A90E2);
}

IconData roleIcon(String role) {
  final r = role.toLowerCase();

  if (r == 'administrador') {
    return Icons.admin_panel_settings_rounded;
  }

  if (r == 'despacho') {
    return Icons.local_shipping_rounded;
  }

  return Icons.person_rounded;
}

class UsuariosSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const UsuariosSearchBox({
    super.key,
    required this.controller,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o rol...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF5E35B1),
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.grey,
                        ),
                        onPressed: onClear,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UsuariosList extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String emptyMessage;
  final Future<void> Function(Map<String, dynamic> user) onToggle;
  final Future<void> Function() onRefresh;

  const UsuariosList({
    super.key,
    required this.users,
    required this.emptyMessage,
    required this.onToggle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFF5E35B1),
      onRefresh: onRefresh,
      child: users.isEmpty
          ? UsuariosEmptyState(message: emptyMessage)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];

                    return UsuarioCard(
                      user: user,
                      onToggle: () => onToggle(user),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class UsuariosEmptyState extends StatelessWidget {
  final String message;

  const UsuariosEmptyState({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off_rounded,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggle;

  const UsuarioCard({
    super.key,
    required this.user,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final role = usuarioRole(user);
    final isActivo = usuarioActivo(user);
    final tipo = usuarioTipo(user);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Opacity(
              opacity: isActivo ? 1.0 : 0.4,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: roleColor(role).withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  roleIcon(role),
                  color: roleColor(role),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Opacity(
                opacity: isActivo ? 1.0 : 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']?.toString() ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          text: role.toUpperCase(),
                          color: roleColor(role),
                        ),
                        _Badge(
                          text: tipo == 'personal_administrativo'
                              ? 'ADMIN'
                              : 'CLIENTE',
                          color: tipo == 'personal_administrativo'
                              ? const Color(0xFF5E35B1)
                              : const Color(0xFF4A90E2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Switch(
              value: isActivo,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.green,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              onChanged: (_) => onToggle(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}