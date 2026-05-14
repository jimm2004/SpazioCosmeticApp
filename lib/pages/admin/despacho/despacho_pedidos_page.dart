import 'package:flutter/material.dart';

import '../../../controllers/admin/admin_pedidos_controller.dart';
import '../../../core/platform/mood_platform.dart';
import '../../../services/admin_pedidos_service.dart';
import '../../../services/mood_api_client.dart';
import 'despacho_page.dart';

/// Vista para bodega/despacho.
/// Mantiene la firma anterior, pero delega la UI a DespachoPage para compartir
/// vista previa + PDF + confirmación de despacho.
class DespachoPedidosPage extends StatefulWidget {
  final String? baseUrl;
  final Future<String?> Function() tokenProvider;

  const DespachoPedidosPage({
    super.key,
    required this.tokenProvider,
    this.baseUrl,
  });

  @override
  State<DespachoPedidosPage> createState() => _DespachoPedidosPageState();
}

class _DespachoPedidosPageState extends State<DespachoPedidosPage> {
  late final AdminPedidosController controller;

  @override
  void initState() {
    super.initState();
    final api = MoodApiClient(
      baseUrl: widget.baseUrl ?? MoodPlatformConfig.apiBaseUrl(),
      tokenProvider: widget.tokenProvider,
    );
    controller = AdminPedidosController(AdminPedidosService(api));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DespachoPage(controller: controller);
  }
}
