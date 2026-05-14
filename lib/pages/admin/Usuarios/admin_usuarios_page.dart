import 'package:flutter/material.dart';

import '../../../controllers/admin/usuarios_controller.dart';
import 'dialogs/create_user_dialog.dart';
import 'widgets/usuarios_widgets.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  final UsuariosController _controller = UsuariosController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
    searchController.addListener(_filterUsers);
  }

  bool _esPersonalAdministrativo(Map<String, dynamic> user) {
    final tipo = (user['tipo_usuario'] ?? '').toString().toLowerCase();
    final role = (user['role'] ?? '').toString().toLowerCase();

    return tipo == 'personal_administrativo' ||
        role == 'administrador' ||
        role == 'despacho';
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);

    try {
      final data = await _controller.obtenerUsuarios();

      final administrativos = data
          .where((u) => _esPersonalAdministrativo(u))
          .map((u) => Map<String, dynamic>.from(u))
          .toList();

      if (!mounted) return;

      setState(() {
        users = administrativos;
        filteredUsers = _applyFilter(administrativos, searchController.text);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> list,
    String query,
  ) {
    final q = query.toLowerCase().trim();

    return list.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final role = (u['role'] ?? '').toString().toLowerCase();

      return name.contains(q) || email.contains(q) || role.contains(q);
    }).toList();
  }

  void _filterUsers() {
    setState(() {
      filteredUsers = _applyFilter(users, searchController.text);
    });
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final int userId = int.tryParse(user['id'].toString()) ?? 0;

    if (userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('ID de usuario inválido.'),
        ),
      );
      return;
    }

    final bool isActivo = usuarioActivo(user);

    try {
      final msg = await _controller.cambiarEstadoUsuario(
        id: userId,
        activo: !isActivo,
        tipoUsuario: 'personal_administrativo',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text(msg),
        ),
      );

      await loadUsers();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> openCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const CreateUserDialog(),
    );

    if (result == true) {
      await loadUsers();
    }
  }

  int get totalAdministrativos => users.length;

  int get totalActivos => users.where(usuarioActivo).length;

  int get totalInactivos => users.where((u) => !usuarioActivo(u)).length;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activos = filteredUsers.where(usuarioActivo).toList();
    final inactivos = filteredUsers.where((u) => !usuarioActivo(u)).toList();

    return DefaultTabController(
      length: 2,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text(
              'Personal Administrativo',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF2C3E50),
                letterSpacing: -0.5,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
            bottom: TabBar(
              labelColor: const Color(0xFF5E35B1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF5E35B1),
              tabs: [
                Tab(text: 'Activos ($totalActivos)'),
                Tab(text: 'Inactivos ($totalInactivos)'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: openCreateUserDialog,
            backgroundColor: const Color(0xFF5E35B1),
            icon: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
            label: const Text(
              'Nuevo administrativo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF5E35B1),
                  ),
                )
              : Column(
                  children: [
                    UsuariosHeaderStats(
                      total: totalAdministrativos,
                      activos: totalActivos,
                      inactivos: totalInactivos,
                    ),
                    UsuariosSearchBox(
                      controller: searchController,
                      onClear: () {
                        searchController.clear();
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          UsuariosList(
                            users: activos,
                            emptyMessage:
                                'No hay personal administrativo activo.',
                            onToggle: _toggleUserStatus,
                            onRefresh: loadUsers,
                          ),
                          UsuariosList(
                            users: inactivos,
                            emptyMessage:
                                'No hay personal administrativo inactivo.',
                            onToggle: _toggleUserStatus,
                            onRefresh: loadUsers,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
} 