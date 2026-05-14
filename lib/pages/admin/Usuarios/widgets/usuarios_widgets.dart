import 'package:flutter/material.dart';

bool usuarioActivo(Map<String, dynamic> user) {
  return user['activo'] == true || user['activo'] == 1 || user['activo'] == '1';
}

String usuarioRole(Map<String, dynamic> user) {
  final role = user['role']?.toString().toLowerCase().trim() ?? 'despacho';

  if (role == 'administrador') return 'administrador';
  if (role == 'despacho') return 'despacho';

  return 'despacho';
}

String usuarioTipo(Map<String, dynamic> user) {
  return 'personal_administrativo';
}

String roleLabel(String role) {
  final r = role.toLowerCase();

  if (r == 'administrador') return 'Administrador';
  if (r == 'despacho') return 'Despacho';

  return 'Administrativo';
}

Color roleColor(String role) {
  final r = role.toLowerCase();

  if (r == 'administrador') return const Color(0xFFE91E63);
  if (r == 'despacho') return const Color(0xFFF5A623);

  return const Color(0xFF5E35B1);
}

IconData roleIcon(String role) {
  final r = role.toLowerCase();

  if (r == 'administrador') {
    return Icons.admin_panel_settings_rounded;
  }

  if (r == 'despacho') {
    return Icons.local_shipping_rounded;
  }

  return Icons.badge_rounded;
}

class UsuariosHeaderStats extends StatelessWidget {
  final int total;
  final int activos;
  final int inactivos;

  const UsuariosHeaderStats({
    super.key,
    required this.total,
    required this.activos,
    required this.inactivos,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF5E35B1),
                  Color(0xFF7E57C2),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5E35B1).withAlpha(35),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Control de personal administrativo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Solo se muestran usuarios administrativos: administrador y despacho.',
                  style: TextStyle(
                    color: Colors.white.withAlpha(215),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        icon: Icons.groups_rounded,
                        label: 'Total',
                        value: '$total',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.verified_user_rounded,
                        label: 'Activos',
                        value: '$activos',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        icon: Icons.block_rounded,
                        label: 'Inactivos',
                        value: '$inactivos',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(215),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
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
        constraints: const BoxConstraints(maxWidth: 850),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade100),
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
                hintText: 'Buscar administrativo por nombre, correo o rol...',
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
                constraints: const BoxConstraints(maxWidth: 850),
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
          height: MediaQuery.of(context).size.height * 0.45,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 72,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Los clientes normales no se muestran en esta vista.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
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
    final color = roleColor(role);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: isActivo ? 1.0 : 0.62,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActivo ? Colors.transparent : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  roleIcon(role),
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name']?.toString() ?? 'Sin nombre',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          text: roleLabel(role).toUpperCase(),
                          color: color,
                        ),
                        _Badge(
                          text: 'PERSONAL ADMIN',
                          color: const Color(0xFF5E35B1),
                        ),
                        _Badge(
                          text: isActivo ? 'ACTIVO' : 'INACTIVO',
                          color: isActivo ? Colors.green : Colors.redAccent,
                        ),
                      ],
                    ),
                  ],
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
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}