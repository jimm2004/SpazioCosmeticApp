import 'package:flutter/material.dart';

import 'adminProductos/admin_productos_page.dart';
import 'Usuarios/admin_usuarios_page.dart';
import '../auth/auth_page.dart';

import 'despacho/despacho_page.dart';
import 'despacho/historial_despacho_page.dart';

class AdministradorPage extends StatelessWidget {
  final String adminName;
  final String rol;

  const AdministradorPage({
    super.key,
    required this.adminName,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final String rolNormalizado = rol.toLowerCase().trim();

    final bool esAdministrador =
        rolNormalizado == 'administrador' || rolNormalizado == 'admin';

    final bool esDespacho = rolNormalizado == 'despacho';

    final List<_AdminOption> options = esAdministrador
        ? [
            _AdminOption(
              title: 'Usuarios',
              subtitle: 'Gestiona personal administrativo',
              icon: Icons.admin_panel_settings_rounded,
              color: const Color(0xFF5E35B1),
              page: const AdminUsuariosPage(),
              tag: 'Admin',
            ),
            _AdminOption(
              title: 'Productos',
              subtitle: 'Fotos, precios y visibilidad',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFFF5A623),
              page: const AdminProductosPage(),
              tag: 'Catálogo',
            ),
            _AdminOption(
              title: 'Pedidos',
              subtitle: 'Control de pedidos realizados',
              icon: Icons.shopping_cart_checkout_rounded,
              color: const Color(0xFF00A86B),
              page: const AdminPedidosPage(),
              tag: 'Ventas',
            ),
            _AdminOption(
              title: 'Promociones',
              subtitle: 'Banners y novedades',
              icon: Icons.campaign_rounded,
              color: const Color(0xFFE91E63),
              page: const AdminPromocionesPage(),
              tag: 'Marketing',
            ),
            _AdminOption(
              title: 'Reportes',
              subtitle: 'Métricas y análisis',
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF8E24AA),
              page: const AdminReportesPage(),
              tag: 'KPI',
            ),
            _AdminOption(
              title: 'Ajustes',
              subtitle: 'Configuración general',
              icon: Icons.settings_rounded,
              color: const Color(0xFF455A64),
              page: const AdminConfiguracionPage(),
              tag: 'Sistema',
            ),
            _AdminOption(
              title: 'Despacho',
              subtitle: 'Preparación y salida',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF00ACC1),
              page: const DespachoPage(),
              tag: 'Operación',
            ),
            _AdminOption(
              title: 'Historial',
              subtitle: 'Registro de despachos',
              icon: Icons.history_rounded,
              color: const Color(0xFF3949AB),
              page: const HistorialDespachoPage(),
              tag: 'Archivo',
            ),
          ]
        : esDespacho
            ? [
                _AdminOption(
                  title: 'Despacho',
                  subtitle: 'Preparación y salida',
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFF00ACC1),
                  page: const DespachoPage(),
                  tag: 'Operación',
                ),
                _AdminOption(
                  title: 'Historial',
                  subtitle: 'Registro de despachos',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF3949AB),
                  page: const HistorialDespachoPage(),
                  tag: 'Archivo',
                ),
              ]
            : [];

    final String roleLabel = esAdministrador
        ? 'Administrador Total'
        : esDespacho
            ? 'Encargado de Despacho'
            : 'Usuario sin rol administrativo';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            double childAspectRatio = 0.92;

            if (constraints.maxWidth >= 1100) {
              crossAxisCount = 4;
              childAspectRatio = 1.08;
            } else if (constraints.maxWidth >= 760) {
              crossAxisCount = 3;
              childAspectRatio = 1.02;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: _TopBar(
                          onLogout: () => _confirmLogout(context),
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                        child: _DashboardHero(
                          adminName: adminName,
                          roleLabel: roleLabel,
                          esAdministrador: esAdministrador,
                          esDespacho: esDespacho,
                        ),
                      ),
                    ),

                    if (esAdministrador)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
                          child: _AdminMetricsPanel(
                            totalModules: options.length,
                          ),
                        ),
                      ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionHeader(
                          title: esDespacho
                              ? 'Centro de despacho'
                              : 'Centro de administración',
                          subtitle: esDespacho
                              ? 'Accesos habilitados para gestión operativa.'
                              : 'Accesos principales del sistema Spazio.',
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(
                      child: SizedBox(height: 14),
                    ),

                    options.isEmpty
                        ? SliverFillRemaining(
                            hasScrollBody: false,
                            child: _NoAccessState(roleLabel: roleLabel),
                          )
                        : SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                            sliver: SliverGrid(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final option = options[index];

                                  return _ModuleCard(
                                    option: option,
                                    index: index,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => option.page,
                                        ),
                                      );
                                    },
                                  );
                                },
                                childCount: options.length,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: childAspectRatio,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            '¿Seguro que deseas salir del panel administrativo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthHomePage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Salir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback onLogout;

  const _TopBar({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Spazio Admin',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final String adminName;
  final String roleLabel;
  final bool esAdministrador;
  final bool esDespacho;

  const _DashboardHero({
    required this.adminName,
    required this.roleLabel,
    required this.esAdministrador,
    required this.esDespacho,
  });

  @override
  Widget build(BuildContext context) {
    final Color roleColor = esAdministrador
        ? const Color(0xFFE91E63)
        : esDespacho
            ? const Color(0xFF00ACC1)
            : Colors.grey;

    final IconData roleIcon = esAdministrador
        ? Icons.admin_panel_settings_rounded
        : esDespacho
            ? Icons.local_shipping_rounded
            : Icons.person_off_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF15172B),
            Color(0xFF5E35B1),
            Color(0xFFE91E63),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E35B1).withAlpha(70),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 130,
              color: Colors.white.withAlpha(20),
            ),
          ),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/img/Logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) {
                    return const Icon(
                      Icons.storefront_rounded,
                      size: 42,
                      color: Color(0xFF5E35B1),
                    );
                  },
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _saludoDinamico(),
                      style: TextStyle(
                        color: Colors.white.withAlpha(210),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      adminName.isEmpty ? 'Usuario' : adminName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroBadge(
                          icon: roleIcon,
                          label: roleLabel,
                          color: roleColor,
                        ),
                        const _HeroBadge(
                          icon: Icons.verified_rounded,
                          label: 'Sesión activa',
                          color: Color(0xFF00C853),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _saludoDinamico() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'Buenos días,';
    if (hour < 18) return 'Buenas tardes,';
    return 'Buenas noches,';
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeroBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(45),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMetricsPanel extends StatelessWidget {
  final int totalModules;

  const _AdminMetricsPanel({
    required this.totalModules,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.dashboard_customize_rounded,
            title: 'Módulos',
            value: '$totalModules',
            color: const Color(0xFF5E35B1),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MetricCard(
            icon: Icons.inventory_2_rounded,
            title: 'Catálogo',
            value: 'Activo',
            color: Color(0xFFF5A623),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _MetricCard(
            icon: Icons.security_rounded,
            title: 'Acceso',
            value: 'Total',
            color: Color(0xFFE91E63),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 38,
          width: 5,
          decoration: BoxDecoration(
            color: const Color(0xFF5E35B1),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF2C3E50),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final _AdminOption option;
  final int index;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.option,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool largeStyle = index == 0 || index == 1;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        splashColor: option.color.withAlpha(30),
        highlightColor: option.color.withAlpha(12),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: option.color.withAlpha(26),
            ),
            boxShadow: [
              BoxShadow(
                color: option.color.withAlpha(18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -18,
                child: Icon(
                  option.icon,
                  size: largeStyle ? 112 : 92,
                  color: option.color.withAlpha(18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: option.color.withAlpha(28),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            option.icon,
                            color: option.color,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: option.color.withAlpha(20),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            option.tag,
                            style: TextStyle(
                              color: option.color,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      option.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2C3E50),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      option.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Abrir módulo',
                          style: TextStyle(
                            color: option.color,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: option.color,
                          size: 17,
                        ),
                      ],
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

class _NoAccessState extends StatelessWidget {
  final String roleLabel;

  const _NoAccessState({
    required this.roleLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_person_rounded,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acceso no disponible',
              style: TextStyle(
                color: Color(0xFF2C3E50),
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El rol "$roleLabel" no tiene módulos administrativos asignados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget page;
  final Color color;
  final String tag;

  const _AdminOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.page,
    required this.color,
    required this.tag,
  });
}

class AdminPedidosPage extends StatelessWidget {
  const AdminPedidosPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Pedidos',
        message: 'Visualiza y procesa los pedidos realizados.',
        icon: Icons.shopping_cart_checkout_rounded,
        color: Color(0xFF00A86B),
      );
}

class AdminPromocionesPage extends StatelessWidget {
  const AdminPromocionesPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Promociones',
        message: 'Crea banners y novedades para el catálogo.',
        icon: Icons.campaign_rounded,
        color: Color(0xFFE91E63),
      );
}

class AdminReportesPage extends StatelessWidget {
  const AdminReportesPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Reportes',
        message: 'Mira las analíticas y métricas de venta.',
        icon: Icons.bar_chart_rounded,
        color: Color(0xFF8E24AA),
      );
}

class AdminConfiguracionPage extends StatelessWidget {
  const AdminConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Configuración',
        message: 'Ajustes generales del sistema.',
        icon: Icons.settings_rounded,
        color: Color(0xFF455A64),
      );
}

class _AdminBasePage extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _AdminBasePage({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 430),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: color.withAlpha(24),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Icon(icon, size: 76, color: color),
                ),
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text(
                      'Volver al panel',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}