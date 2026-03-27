import 'package:flutter/material.dart';
import '../../../services/usuarios_service.dart';

class AdminUsuariosPage extends StatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  State<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends State<AdminUsuariosPage> {
  final UsuariosService _usuariosService = UsuariosService();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> users = [];
  List<dynamic> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
    searchController.addListener(_filterUsers);
  }

  Future<void> loadUsers() async {
    setState(() => isLoading = true);
    try {
      final data = await _usuariosService.obtenerUsuarios();
      if (mounted) {
        setState(() {
          users = data;
          _filterUsers(); // Aplica filtro inicial para ordenar la lista
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterUsers() {
    final query = searchController.text.toLowerCase().trim();
    setState(() {
      filteredUsers = users.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  Future<void> _toggleUserStatus(int id, bool currentStatus) async {
    try {
      final msg = await _usuariosService.cambiarEstadoUsuario(id, !currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.black87, content: Text(msg)),
        );
        loadUsers(); // Recargar la lista para reflejar el cambio y mover de pestaña
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> openCreateUserDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (result == true) loadUsers();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color roleColor(String role) {
    if (role.toLowerCase() == 'administrador') return const Color(0xFFE91E63);
    if (role.toLowerCase() == 'despacho') return const Color(0xFFF5A623);
    return const Color(0xFF4A90E2);
  }

  IconData roleIcon(String role) {
    if (role.toLowerCase() == 'administrador') return Icons.admin_panel_settings_rounded;
    if (role.toLowerCase() == 'despacho') return Icons.local_shipping_rounded;
    return Icons.person_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Dividimos la lista filtrada en Activos e Inactivos
    final activos = filteredUsers.where((u) => u['activo'] == true || u['activo'] == 1).toList();
    final inactivos = filteredUsers.where((u) => u['activo'] == false || u['activo'] == 0).toList();

    return DefaultTabController(
      length: 2,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Oculta el teclado al tocar la pantalla
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: const Text(
              'Personal del Sistema',
              style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2C3E50), letterSpacing: -0.5),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
            bottom: const TabBar(
              labelColor: Color(0xFF5E35B1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF5E35B1),
              tabs: [
                Tab(text: 'Activos'),
                Tab(text: 'Inactivos'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: openCreateUserDialog,
            backgroundColor: const Color(0xFF5E35B1),
            icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
            label: const Text('Nuevo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF5E35B1)))
              : Column(
                  children: [
                    // BUSCADOR RESPONSIVO
                    Center(
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
                              controller: searchController,
                              decoration: InputDecoration(
                                hintText: 'Buscar por nombre o correo...',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                prefixIcon: const Icon(Icons.search, color: Color(0xFF5E35B1)),
                                suffixIcon: searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, color: Colors.grey),
                                        onPressed: () {
                                          searchController.clear();
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // TABS CONTENT
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildUserList(activos, emptyMessage: 'No hay usuarios activos.'),
                          _buildUserList(inactivos, emptyMessage: 'No hay usuarios desactivados.'),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildUserList(List<dynamic> list, {required String emptyMessage}) {
    return RefreshIndicator(
      color: const Color(0xFF5E35B1),
      onRefresh: loadUsers,
      child: list.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(emptyMessage, style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800), // Ancho máximo para Web/PC
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final user = list[index];
                    final role = user['role']?.toString() ?? 'cliente';
                    final bool isActivo = user['activo'] == true || user['activo'] == 1;
                    final int userId = int.tryParse(user['id'].toString()) ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8), 
                            blurRadius: 10, 
                            offset: const Offset(0, 4)
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // AVATAR CON OPACIDAD SI ESTÁ INACTIVO
                            Opacity(
                              opacity: isActivo ? 1.0 : 0.4,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: roleColor(role).withAlpha(25),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(roleIcon(role), color: roleColor(role), size: 28),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // DATOS
                            Expanded(
                              child: Opacity(
                                opacity: isActivo ? 1.0 : 0.6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name']?.toString() ?? 'Sin nombre',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2C3E50)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user['email']?.toString() ?? '',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: roleColor(role).withAlpha(25),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        role.toUpperCase(),
                                        style: TextStyle(color: roleColor(role), fontWeight: FontWeight.w800, fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // SWITCH DE ESTADO
                            Switch(
                              value: isActivo,
                              activeColor: Colors.white,
                              activeTrackColor: Colors.green,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey.shade300,
                              onChanged: (val) => _toggleUserStatus(userId, isActivo),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

// =================================================================
// FORMULARIO MODAL (Crear Usuario)
// =================================================================
class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final UsuariosService _usuariosService = UsuariosService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = 'despacho';
  bool isSaving = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text('Las contraseñas no coinciden.'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await _usuariosService.crearUsuarioAdministrativo(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        passwordConfirmation: confirmPasswordController.text.trim(),
        role: selectedRole,
      );

      // NOTA: Ya NO llamamos al correo manualmente aquí porque 
      // el backend de Laravel se encarga de enviarlo automáticamente.

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Usuario creado correctamente.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Error al crear usuario: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF5E35B1)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF5E35B1), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        width: 400, // Ancho máximo acoplado para PC/Tablets
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E35B1).withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_add_rounded, color: Color(0xFF5E35B1)),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Nuevo Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: buildInputDecoration('Nombre completo', Icons.person_outline_rounded),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Ingresa el nombre' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: buildInputDecoration('Correo electrónico', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa el correo';
                    if (!value.contains('@')) return 'Correo no válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: buildInputDecoration('Rol del sistema', Icons.badge_outlined),
                  items: const [
                    DropdownMenuItem(
                      value: 'despacho',
                      child: Text('Encargado de Despacho', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    DropdownMenuItem(
                      value: 'administrador',
                      child: Text('Administrador Total', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value ?? 'despacho';
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: buildInputDecoration(
                    'Contraseña',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Ingresa la contraseña';
                    if (value.trim().length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: buildInputDecoration(
                    'Confirmar contraseña',
                    Icons.lock_reset_rounded,
                    suffix: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Confirma la contraseña' : null,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSaving ? null : saveUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5E35B1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Guardar Usuario', style: TextStyle(fontWeight: FontWeight.bold)),
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