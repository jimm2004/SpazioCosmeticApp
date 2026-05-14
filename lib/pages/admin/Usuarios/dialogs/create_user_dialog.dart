import 'package:flutter/material.dart';

import '../../../../controllers/admin/usuarios_controller.dart';

class CreateUserDialog extends StatefulWidget {
  const CreateUserDialog({super.key});

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final UsuariosController _controller = UsuariosController();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedRole = 'despacho';

  bool isSaving = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  String alertMessage = 'Completa los datos para crear personal administrativo.';
  IconData alertIcon = Icons.info_outline_rounded;
  Color alertColor = const Color(0xFF5E35B1);

  @override
  void initState() {
    super.initState();

    nameController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);
    passwordController.addListener(_onFormChanged);
    confirmPasswordController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!mounted) return;

    setState(() {
      if (nameController.text.trim().isEmpty) {
        _setLocalAlert(
          message: 'Pendiente: ingresa el nombre completo.',
          icon: Icons.person_outline_rounded,
          color: Colors.orange,
        );
      } else if (!_emailValido(emailController.text.trim())) {
        _setLocalAlert(
          message: 'Pendiente: ingresa un correo válido.',
          icon: Icons.email_outlined,
          color: Colors.orange,
        );
      } else if (passwordController.text.trim().length < 6) {
        _setLocalAlert(
          message: 'Pendiente: la contraseña debe tener mínimo 6 caracteres.',
          icon: Icons.lock_outline_rounded,
          color: Colors.orange,
        );
      } else if (confirmPasswordController.text.trim().isNotEmpty &&
          passwordController.text.trim() !=
              confirmPasswordController.text.trim()) {
        _setLocalAlert(
          message: 'Atención: las contraseñas no coinciden.',
          icon: Icons.warning_amber_rounded,
          color: Colors.redAccent,
        );
      } else if (_formularioListo) {
        _setLocalAlert(
          message:
              'Listo para crear ${selectedRole == 'administrador' ? 'Administrador Total' : 'Encargado de Despacho'}.',
          icon: Icons.check_circle_rounded,
          color: Colors.green,
        );
      } else {
        _setLocalAlert(
          message: 'Completa los datos para crear personal administrativo.',
          icon: Icons.info_outline_rounded,
          color: const Color(0xFF5E35B1),
        );
      }
    });
  }

  void _setLocalAlert({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    alertMessage = message;
    alertIcon = icon;
    alertColor = color;
  }

  void _showChangeSnack({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        duration: const Duration(milliseconds: 1300),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _emailValido(String email) {
    final regex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  bool get _formularioListo {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    return name.isNotEmpty &&
        _emailValido(email) &&
        pass.length >= 6 &&
        confirm == pass;
  }

  double get _passwordStrength {
    final pass = passwordController.text.trim();

    if (pass.isEmpty) return 0;
    if (pass.length < 6) return 0.30;
    if (pass.length < 8) return 0.55;

    final hasNumber = RegExp(r'\d').hasMatch(pass);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
    final hasSpecial = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(pass);

    double score = 0.65;

    if (hasNumber) score += 0.12;
    if (hasUpper) score += 0.12;
    if (hasSpecial) score += 0.11;

    return score.clamp(0, 1);
  }

  String get _passwordStrengthText {
    final value = _passwordStrength;

    if (value == 0) return 'Sin contraseña';
    if (value < 0.45) return 'Débil';
    if (value < 0.75) return 'Media';
    return 'Fuerte';
  }

  Color get _passwordStrengthColor {
    final value = _passwordStrength;

    if (value == 0) return Colors.grey;
    if (value < 0.45) return Colors.redAccent;
    if (value < 0.75) return Colors.orange;
    return Colors.green;
  }

  Future<void> saveUser() async {
    if (!_formKey.currentState!.validate()) {
      _showChangeSnack(
        message: 'Revisa los campos marcados antes de guardar.',
        color: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      _showChangeSnack(
        message: 'Las contraseñas no coinciden.',
        color: Colors.orange,
        icon: Icons.lock_reset_rounded,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final msg = await _controller.crearUsuarioAdministrativo(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        passwordConfirmation: confirmPasswordController.text.trim(),
        role: selectedRole,
      );

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      navigator.pop(true);

      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showChangeSnack(
        message: e.toString().replaceFirst('Exception: ', ''),
        color: Colors.redAccent,
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    nameController.removeListener(_onFormChanged);
    emailController.removeListener(_onFormChanged);
    passwordController.removeListener(_onFormChanged);
    confirmPasswordController.removeListener(_onFormChanged);

    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration buildInputDecoration(
    String label,
    IconData icon, {
    Widget? suffix,
  }) {
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
        borderSide: const BorderSide(
          color: Color(0xFF5E35B1),
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = selectedRole == 'administrador';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 430,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DialogHeader(
                  selectedRole: selectedRole,
                ),

                const SizedBox(height: 18),

                _LiveAlertCard(
                  message: alertMessage,
                  icon: alertIcon,
                  color: alertColor,
                ),

                const SizedBox(height: 18),

                _RolePreviewCard(
                  selectedRole: selectedRole,
                ),

                const SizedBox(height: 18),

                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: buildInputDecoration(
                    'Nombre completo',
                    Icons.person_outline_rounded,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre';
                    }

                    if (value.trim().length < 3) {
                      return 'Nombre demasiado corto';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: buildInputDecoration(
                    'Correo electrónico',
                    Icons.email_outlined,
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  validator: (value) {
                    final email = value?.trim() ?? '';

                    if (email.isEmpty) {
                      return 'Ingresa el correo';
                    }

                    if (!_emailValido(email)) {
                      return 'Correo no válido';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: selectedRole,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  decoration: buildInputDecoration(
                    'Rol del sistema',
                    Icons.badge_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'despacho',
                      child: Text(
                        'Encargado de Despacho',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'administrador',
                      child: Text(
                        'Administrador Total',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  onChanged: isSaving
                      ? null
                      : (value) {
                          final nuevoRol = value ?? 'despacho';

                          setState(() {
                            selectedRole = nuevoRol;
                            _setLocalAlert(
                              message: nuevoRol == 'administrador'
                                  ? 'Rol cambiado: tendrá acceso total administrativo.'
                                  : 'Rol cambiado: gestionará despacho y operaciones.',
                              icon: nuevoRol == 'administrador'
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.local_shipping_rounded,
                              color: nuevoRol == 'administrador'
                                  ? const Color(0xFFE91E63)
                                  : const Color(0xFFF5A623),
                            );
                          });

                          _showChangeSnack(
                            message: nuevoRol == 'administrador'
                                ? 'Cambio aplicado: Administrador Total.'
                                : 'Cambio aplicado: Encargado de Despacho.',
                            color: nuevoRol == 'administrador'
                                ? const Color(0xFFE91E63)
                                : const Color(0xFFF5A623),
                            icon: nuevoRol == 'administrador'
                                ? Icons.admin_panel_settings_rounded
                                : Icons.local_shipping_rounded,
                          );
                        },
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: buildInputDecoration(
                    'Contraseña',
                    Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });

                        _showChangeSnack(
                          message: obscurePassword
                              ? 'Contraseña oculta.'
                              : 'Contraseña visible temporalmente.',
                          color: Colors.black87,
                          icon: obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        );
                      },
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  validator: (value) {
                    final pass = value?.trim() ?? '';

                    if (pass.isEmpty) {
                      return 'Ingresa la contraseña';
                    }

                    if (pass.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 10),

                _PasswordStrengthBar(
                  value: _passwordStrength,
                  text: _passwordStrengthText,
                  color: _passwordStrengthColor,
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: buildInputDecoration(
                    'Confirmar contraseña',
                    Icons.lock_reset_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                      color: Colors.grey,
                      onPressed: () {
                        setState(() {
                          obscureConfirm = !obscureConfirm;
                        });

                        _showChangeSnack(
                          message: obscureConfirm
                              ? 'Confirmación oculta.'
                              : 'Confirmación visible temporalmente.',
                          color: Colors.black87,
                          icon: obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        );
                      },
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                  validator: (value) {
                    final confirm = value?.trim() ?? '';

                    if (confirm.isEmpty) {
                      return 'Confirma la contraseña';
                    }

                    if (passwordController.text.trim().isNotEmpty &&
                        confirm != passwordController.text.trim()) {
                      return 'Las contraseñas no coinciden';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 22),

                _SummaryCard(
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  role: selectedRole,
                  isReady: _formularioListo,
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: isSaving || !_formularioListo ? null : saveUser,
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              esAdmin
                                  ? Icons.admin_panel_settings_rounded
                                  : Icons.local_shipping_rounded,
                            ),
                      label: Text(
                        isSaving
                            ? 'Guardando...'
                            : esAdmin
                                ? 'Crear Admin'
                                : 'Crear Despacho',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: esAdmin
                            ? const Color(0xFFE91E63)
                            : const Color(0xFF5E35B1),
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
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

class _DialogHeader extends StatelessWidget {
  final String selectedRole;

  const _DialogHeader({
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = selectedRole == 'administrador';
    final Color color =
        esAdmin ? const Color(0xFFE91E63) : const Color(0xFF5E35B1);

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: Icon(
            esAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.local_shipping_rounded,
            color: color,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Text(
            'Nuevo Administrativo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveAlertCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _LiveAlertCard({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePreviewCard extends StatelessWidget {
  final String selectedRole;

  const _RolePreviewCard({
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = selectedRole == 'administrador';

    final Color color =
        esAdmin ? const Color(0xFFE91E63) : const Color(0xFFF5A623);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 230),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(
              esAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.local_shipping_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  esAdmin ? 'Administrador Total' : 'Encargado de Despacho',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  esAdmin
                      ? 'Tendrá acceso completo al panel administrativo.'
                      : 'Podrá gestionar tareas operativas de despacho.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final double value;
  final String text;
  final Color color;

  const _PasswordStrengthBar({
    required this.value,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: value,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Seguridad: $text',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final bool isReady;

  const _SummaryCard({
    required this.name,
    required this.email,
    required this.role,
    required this.isReady,
  });

  @override
  Widget build(BuildContext context) {
    final bool esAdmin = role == 'administrador';

    final Color color =
        isReady ? Colors.green : Colors.grey.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isReady
            ? Colors.green.withAlpha(18)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isReady ? Colors.green.withAlpha(40) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReady
                ? Icons.fact_check_rounded
                : Icons.pending_actions_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isReady
                  ? 'Se creará ${name.isEmpty ? 'el usuario' : name} como ${esAdmin ? 'Administrador Total' : 'Encargado de Despacho'} usando $email.'
                  : 'Resumen pendiente: completa nombre, correo, contraseña y confirmación.',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}