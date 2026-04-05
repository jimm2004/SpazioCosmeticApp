import 'package:flutter/material.dart';
import 'adminProductos/admin_productos_page.dart';
import 'Usuarios/admin_usuarios_page.dart';
import '../auth/auth_page.dart';

// CAMBIA ESTOS IMPORTS SI TUS ARCHIVOS TIENEN OTRO NOMBRE
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
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF4A90E2),
              page: const AdminUsuariosPage(),
            ),
            _AdminOption(
              title: 'Productos',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFFF5A623),
              page: const AdminProductosPage(),
            ),
            _AdminOption(
              title: 'Pedidos',
              icon: Icons.shopping_cart_checkout_rounded,
              color: const Color(0xFF7ED321),
              page: const AdminPedidosPage(),
            ),
            _AdminOption(
              title: 'Promociones',
              icon: Icons.campaign_rounded,
              color: const Color(0xFFE91E63),
              page: const AdminPromocionesPage(),
            ),
            _AdminOption(
              title: 'Reportes',
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFFBD10E0),
              page: const AdminReportesPage(),
            ),
            _AdminOption(
              title: 'Ajustes',
              icon: Icons.settings_rounded,
              color: const Color(0xFF4A4A4A),
              page: const AdminConfiguracionPage(),
            ),
            _AdminOption(
              title: 'Despacho',
              icon: Icons.local_shipping_rounded,
              color: const Color(0xFF00ACC1),
              page: const DespachoPage(),
            ),
            _AdminOption(
              title: 'Historial de despacho',
              icon: Icons.history_rounded,
              color: const Color(0xFF8E24AA),
              page: const HistorialDespachoPage(),
            ),
          ]
        : esDespacho
            ? [
                _AdminOption(
                  title: 'Despacho',
                  icon: Icons.local_shipping_rounded,
                  color: const Color(0xFF00ACC1),
                  page: const DespachoPage(),
                ),
                _AdminOption(
                  title: 'Historial de despacho',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF8E24AA),
                  page: const HistorialDespachoPage(),
                ),
              ]
            : [];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Panel de Control',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withAlpha(25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthHomePage()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 2;
            double childAspectRatio = 1.1;

            if (constraints.maxWidth >= 900) {
              crossAxisCount = 4;
              childAspectRatio = 1.3;
            } else if (constraints.maxWidth >= 600) {
              crossAxisCount = 3;
              childAspectRatio = 1.2;
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5E35B1), Color(0xFF8E24AA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E35B1).withAlpha(100),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(38),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/img/Logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.storefront_rounded,
                                    size: 40,
                                    color: Color(0xFF5E35B1),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '¡Hola de nuevo!',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    adminName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(50),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      esAdministrador
                                          ? 'Administrador'
                                          : esDespacho
                                              ? 'Despacho'
                                              : 'Usuario',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      if (esAdministrador) ...[
                        const Text(
                          'Resumen de Hoy',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Ventas',
                                value: '\$450',
                                icon: Icons.attach_money,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Pedidos',
                                value: '12',
                                icon: Icons.shopping_bag_outlined,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Nuevos',
                                value: '+5',
                                icon: Icons.person_add_alt_1_rounded,
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                      ],

                      Text(
                        esDespacho ? 'Módulo de Despacho' : 'Gestión del Sistema',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: options.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemBuilder: (context, index) {
                          final option = options[index];

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                highlightColor: option.color.withAlpha(12),
                                splashColor: option.color.withAlpha(25),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => option.page),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: option.color.withAlpha(30),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          option.icon,
                                          size: 34,
                                          color: option.color,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        option.title,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final MaterialColor color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.shade400, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOption {
  final String title;
  final IconData icon;
  final Widget page;
  final Color color;

  _AdminOption({
    required this.title,
    required this.icon,
    required this.page,
    required this.color,
  });
}

class AdminPedidosPage extends StatelessWidget {
  const AdminPedidosPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Pedidos',
        message: 'Visualiza y procesa los pedidos realizados.',
        icon: Icons.shopping_cart_checkout_rounded,
        color: Colors.green,
      );
}

class AdminPromocionesPage extends StatelessWidget {
  const AdminPromocionesPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Promociones',
        message: 'Crea banners y novedades para el catálogo.',
        icon: Icons.campaign_rounded,
        color: Colors.pinkAccent,
      );
}

class AdminReportesPage extends StatelessWidget {
  const AdminReportesPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Reportes',
        message: 'Mira las analíticas y métricas de venta.',
        icon: Icons.bar_chart_rounded,
        color: Colors.purpleAccent,
      );
}

class AdminConfiguracionPage extends StatelessWidget {
  const AdminConfiguracionPage({super.key});

  @override
  Widget build(BuildContext context) => const _AdminBasePage(
        title: 'Configuración',
        message: 'Ajustes generales del sistema.',
        icon: Icons.settings_rounded,
        color: Colors.blueGrey,
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C3E50),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text(
                  'Volver al Dashboard',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}