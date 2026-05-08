import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../../auth/auth_page.dart';
import 'contabilidad_metodos_pago_page.dart';
import 'contabilidad_pedidos_page.dart';
import 'contabilidad_tarifas_envio_page.dart';

class AdministracionContablePage extends StatefulWidget {
  final String adminName;
  final String rol;

  const AdministracionContablePage({
    super.key,
    required this.adminName,
    required this.rol,
  });

  @override
  State<AdministracionContablePage> createState() =>
      _AdministracionContablePageState();
}

class _AdministracionContablePageState
    extends State<AdministracionContablePage> {
  String filtro = '';
  final TextEditingController searchCtrl = TextEditingController();

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  List<_ContabilidadOption> get options {
    return const [
      _ContabilidadOption(
        title: 'Pagos pendientes',
        subtitle: 'Revisar, aprobar o rechazar transferencias de pedidos',
        description:
            'Controla las transferencias enviadas por clientes antes de pasar el pedido a bodega.',
        icon: Icons.receipt_long_rounded,
        color: Color(0xFFE91E63),
        tag: 'Pagos',
        page: ContabilidadPedidosPage(),
      ),
      _ContabilidadOption(
        title: 'Métodos de pago',
        subtitle: 'BAC, Lafise, Banpro, C\$ y dólares',
        description:
            'Administra las cuentas bancarias que el cliente verá durante el checkout.',
        icon: Icons.account_balance_rounded,
        color: Color(0xFF5E35B1),
        tag: 'Bancos',
        page: ContabilidadMetodosPagoPage(),
      ),
      _ContabilidadOption(
        title: 'Tarifas de envío',
        subtitle: 'Porcentajes por zona para el cliente',
        description:
            'Configura los porcentajes de envío usados para calcular el total del pedido.',
        icon: Icons.local_shipping_rounded,
        color: Color(0xFF00ACC1),
        tag: 'Envíos',
        page: ContabilidadTarifasEnvioPage(),
      ),
    ];
  }

  List<_ContabilidadOption> get filteredOptions {
    final q = filtro.trim().toLowerCase();

    if (q.isEmpty) return options;

    return options.where((option) {
      return option.title.toLowerCase().contains(q) ||
          option.subtitle.toLowerCase().contains(q) ||
          option.tag.toLowerCase().contains(q) ||
          option.description.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _abrirModulo(_ContabilidadOption option) async {
    final abrir = await _confirmAction(
      title: 'Abrir módulo',
      message:
          '¿Deseas abrir el módulo "${option.title}"?\n\n${option.description}',
      action: 'Abrir',
      icon: option.icon,
      color: option.color,
    );

    if (abrir != true) return;

    if (!mounted) return;

    _snack(
      'Abriendo ${option.title}...',
      icon: option.icon,
      color: option.color,
    );

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => option.page),
    );
  }

  Future<void> _confirmLogout() async {
    final salir = await _confirmAction(
      title: 'Cerrar sesión',
      message: '¿Seguro que deseas salir del panel contable?',
      action: 'Salir',
      icon: Icons.logout_rounded,
      color: Colors.redAccent,
    );

    if (salir != true) return;

    ApiService().clearToken();

    if (!mounted) return;

    _snack(
      'Sesión cerrada correctamente.',
      icon: Icons.check_circle_rounded,
      color: Colors.green,
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthHomePage()),
      (route) => false,
    );
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String action,
    required IconData icon,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: Icon(icon),
              label: Text(action),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _snack(
    String message, {
    required IconData icon,
    required Color color,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
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

  @override
  Widget build(BuildContext context) {
    final visibles = filteredOptions;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              int crossAxisCount = 1;
              double childAspectRatio = 2.35;

              if (width >= 1180) {
                crossAxisCount = 3;
                childAspectRatio = 1.02;
              } else if (width >= 850) {
                crossAxisCount = 3;
                childAspectRatio = 1.03;
              } else if (width >= 620) {
                crossAxisCount = 2;
                childAspectRatio = 1.22;
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                          child: _TopBar(
                            onLogout: _confirmLogout,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                          child: _ContabilidadHero(
                            adminName: widget.adminName,
                            rol: widget.rol,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                          child: _MetricPanel(totalModules: options.length),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: _SearchBox(
                            controller: searchCtrl,
                            onChanged: (value) {
                              setState(() => filtro = value);
                            },
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _SectionHeader(
                            title: 'Centro de administración contable',
                            subtitle:
                                'Gestiona pagos, cuentas bancarias y tarifas usadas por los clientes.',
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 14),
                      ),
                      if (visibles.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final option = visibles[index];

                                return _AnimatedModule(
                                  delay: index * 60,
                                  child: _ModuleCard(
                                    option: option,
                                    onTap: () => _abrirModulo(option),
                                  ),
                                );
                              },
                              childCount: visibles.length,
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
      ),
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
            'Spazio Cosmetic Contabilidad',
            style: TextStyle(
              color: Color(0xFF2C3E50),
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        _CircleButton(
          tooltip: 'Cerrar sesión',
          icon: Icons.logout_rounded,
          color: Colors.redAccent,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _CircleButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedScale(
        scale: hover ? 1.07 : 1,
        duration: const Duration(milliseconds: 180),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(hover ? 35 : 14),
                blurRadius: hover ? 16 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            tooltip: widget.tooltip,
            onPressed: widget.onTap,
            icon: Icon(widget.icon, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _ContabilidadHero extends StatelessWidget {
  final String adminName;
  final String rol;

  const _ContabilidadHero({
    required this.adminName,
    required this.rol,
  });

  @override
  Widget build(BuildContext context) {
    final rolTexto = _normalizarRol(rol);
    final fechaTexto = _fechaSimple();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
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
                Icons.account_balance_wallet_rounded,
                size: 145,
                color: Colors.white.withAlpha(20),
              ),
            ),
            LayoutBuilder(
              builder: (_, constraints) {
                final narrow = constraints.maxWidth < 620;

                final logo = Container(
                  width: narrow ? 64 : 76,
                  height: narrow ? 64 : 76,
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
                );

                final content = Expanded(
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
                        adminName.isEmpty ? 'Usuario contable' : adminName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: narrow ? 23 : 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Panel operativo financiero · $fechaTexto',
                        style: TextStyle(
                          color: Colors.white.withAlpha(205),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          const _HeroBadge(
                            icon: Icons.verified_user_rounded,
                            label: 'Administración contable',
                            color: Color(0xFF00E676),
                          ),
                          const _HeroBadge(
                            icon: Icons.payment_rounded,
                            label: 'Pagos y tarifas',
                            color: Color(0xFFFFD54F),
                          ),
                          _HeroBadge(
                            icon: Icons.badge_rounded,
                            label: rolTexto,
                            color: const Color(0xFF80DEEA),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                return Row(
                  children: [
                    logo,
                    const SizedBox(width: 18),
                    content,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _normalizarRol(String rol) {
    final limpio = rol
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim()
        .split(' ')
        .where((p) => p.trim().isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');

    return limpio.isEmpty ? 'Rol contable' : limpio;
  }

  String _fechaSimple() {
    final now = DateTime.now();

    final dia = now.day.toString().padLeft(2, '0');
    final mes = now.month.toString().padLeft(2, '0');
    final anio = now.year.toString();

    return '$dia/$mes/$anio';
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (_, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
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
      ),
    );
  }
}

class _MetricPanel extends StatelessWidget {
  final int totalModules;

  const _MetricPanel({
    required this.totalModules,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final isNarrow = constraints.maxWidth < 620;

        final cards = [
          _MetricCard(
            icon: Icons.dashboard_customize_rounded,
            title: 'Módulos',
            value: '$totalModules',
            color: const Color(0xFF5E35B1),
          ),
          const _MetricCard(
            icon: Icons.account_balance_rounded,
            title: 'Cuentas',
            value: 'Activas',
            color: Color(0xFFE91E63),
          ),
          const _MetricCard(
            icon: Icons.local_shipping_rounded,
            title: 'Tarifas',
            value: 'Config.',
            color: Color(0xFF00ACC1),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: cards
                .map(
                  (card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
            const SizedBox(width: 12),
            Expanded(child: cards[2]),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatefulWidget {
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
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(14),
        transform: Matrix4.identity()..translate(0.0, hover ? -3.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: widget.color.withAlpha(hover ? 28 : 10),
              blurRadius: hover ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(widget.icon, color: widget.color, size: 28),
            const SizedBox(height: 8),
            Text(
              widget.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.color,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Buscar módulo contable...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
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

class _AnimatedModule extends StatelessWidget {
  final Widget child;
  final int delay;

  const _AnimatedModule({
    required this.child,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay.clamp(0, 320)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _ModuleCard extends StatefulWidget {
  final _ContabilidadOption option;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.option,
    required this.onTap,
  });

  @override
  State<_ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<_ModuleCard> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final option = widget.option;

    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        transform: Matrix4.identity()..translate(0.0, hover ? -5.0 : 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: hover ? option.color.withAlpha(85) : option.color.withAlpha(26),
          ),
          boxShadow: [
            BoxShadow(
              color: hover ? option.color.withAlpha(40) : option.color.withAlpha(18),
              blurRadius: hover ? 22 : 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(26),
            splashColor: option.color.withAlpha(30),
            highlightColor: option.color.withAlpha(12),
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -18,
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    scale: hover ? 1.08 : 1,
                    child: Icon(
                      option.icon,
                      size: 104,
                      color: option.color.withAlpha(18),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: option.color.withAlpha(28),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              option.icon,
                              color: option.color,
                              size: hover ? 30 : 28,
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
                      const SizedBox(height: 10),
                      Text(
                        option.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11.5,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
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
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 220),
                            offset: hover ? const Offset(0.15, 0) : Offset.zero,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: option.color,
                              size: 17,
                            ),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 74,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No se encontró ningún módulo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Probá buscar por pagos, bancos, cuentas o envíos.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContabilidadOption {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Widget page;
  final Color color;
  final String tag;

  const _ContabilidadOption({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.page,
    required this.color,
    required this.tag,
  });
}