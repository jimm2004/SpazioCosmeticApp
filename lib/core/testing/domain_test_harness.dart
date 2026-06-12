import '../utils/money_utils.dart';

/// Capa pequeña y testeable con reglas de dominio usadas por las pruebas.
/// Sirve como base para mover lógica repetida desde controladores/páginas
/// hacia funciones puras y fáciles de validar con cobertura real.
class AuthRules {
  const AuthRules._();

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static bool isValidEmail(String email) {
    final normalized = normalizeEmail(email);
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(normalized);
  }

  static String normalizeRole(String role) {
    return role
        .toLowerCase()
        .trim()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  static String routeForRole(String role) {
    final normalized = normalizeRole(role);
    if (normalized == 'administrador' || normalized == 'admin') {
      return '/admin';
    }
    if (normalized == 'administracion_contable') {
      return '/contabilidad';
    }
    if (normalized == 'despacho' || normalized == 'bodega') {
      return '/despacho';
    }
    return '/catalogo';
  }

  static void validateLogin(String email, String password) {
    if (normalizeEmail(email).isEmpty || password.trim().isEmpty) {
      throw ArgumentError('Correo y contraseña son obligatorios.');
    }
    if (!isValidEmail(email)) {
      throw ArgumentError('Correo inválido.');
    }
  }

  static void validatePassword(String password) {
    if (password.trim().length < 6) {
      throw ArgumentError('La contraseña debe tener al menos 6 caracteres.');
    }
  }

  static String extractToken(Map<String, dynamic> response) {
    final data = response['data'];
    return response['token']?.toString() ??
        response['access_token']?.toString() ??
        response['plainTextToken']?.toString() ??
        response['plain_text_token']?.toString() ??
        (data is Map ? data['token']?.toString() : null) ??
        (data is Map ? data['access_token']?.toString() : null) ??
        (data is Map ? data['plainTextToken']?.toString() : null) ??
        (data is Map ? data['plain_text_token']?.toString() : null) ??
        '';
  }

  static Map<String, dynamic> sessionFromResponse(Map<String, dynamic> response) {
    final user = Map<String, dynamic>.from(response['user'] as Map? ?? const {});
    final token = extractToken(response);
    final role = normalizeRole(user['role']?.toString() ?? user['rol']?.toString() ?? 'cliente');

    if (token.isEmpty) {
      throw StateError('El servidor no devolvió token.');
    }

    return {
      'id': user['id'],
      'name': user['name'] ?? user['nombre'] ?? 'Usuario',
      'email': normalizeEmail(user['email']?.toString() ?? ''),
      'role': role,
      'token': token,
      'route': routeForRole(role),
    };
  }
}

class CartItem {
  final int productId;
  final String name;
  final int unitPriceCents;
  final int quantity;

  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPriceCents,
    required this.quantity,
  });

  int get subtotalCents => MoneyUtils.multiply(unitPriceCents, quantity);

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      name: name,
      unitPriceCents: unitPriceCents,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartRules {
  const CartRules._();

  static void validateQuantity(int quantity) {
    if (quantity <= 0) {
      throw ArgumentError('La cantidad debe ser mayor que cero.');
    }
  }

  static List<CartItem> addItem(List<CartItem> items, CartItem item) {
    validateQuantity(item.quantity);
    final index = items.indexWhere((element) => element.productId == item.productId);
    if (index == -1) {
      return [...items, item];
    }
    final updated = [...items];
    final current = updated[index];
    updated[index] = current.copyWith(quantity: current.quantity + item.quantity);
    return updated;
  }

  static List<CartItem> removeItem(List<CartItem> items, int productId) {
    return items.where((item) => item.productId != productId).toList();
  }

  static List<CartItem> updateQuantity(List<CartItem> items, int productId, int quantity) {
    validateQuantity(quantity);
    return items
        .map((item) => item.productId == productId ? item.copyWith(quantity: quantity) : item)
        .toList();
  }

  static int totalUnits(List<CartItem> items) {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  static int subtotalCents(List<CartItem> items) {
    return MoneyUtils.sum(items.map((item) => item.subtotalCents));
  }

  static bool isEmpty(List<CartItem> items) => items.isEmpty;
}

class CheckoutRules {
  const CheckoutRules._();

  static int totalCents({
    required int subtotalCents,
    required int shippingCents,
    int discountCents = 0,
  }) {
    final withShipping = MoneyUtils.add(subtotalCents, shippingCents);
    return MoneyUtils.applyDiscount(withShipping, discountCents);
  }

  static bool isSupportedPaymentMethod(String method) {
    final normalized = method.trim().toLowerCase();
    return const {'efectivo', 'transferencia', 'tarjeta', 'contado', 'credito'}.contains(normalized);
  }

  static void validateAddress(String address) {
    if (address.trim().length < 8) {
      throw ArgumentError('La dirección debe ser más específica.');
    }
  }

  static void validateCheckout({
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
  }) {
    if (CartRules.isEmpty(items)) {
      throw StateError('El carrito no puede estar vacío.');
    }
    if (!isSupportedPaymentMethod(paymentMethod)) {
      throw ArgumentError('Método de pago no soportado.');
    }
    validateAddress(address);
  }

  static Map<String, dynamic> buildPayload({
    required List<CartItem> items,
    required String paymentMethod,
    required String address,
    int shippingCents = 0,
  }) {
    validateCheckout(items: items, paymentMethod: paymentMethod, address: address);
    final subtotal = CartRules.subtotalCents(items);
    return {
      'items': items.length,
      'unidades': CartRules.totalUnits(items),
      'metodo_pago': paymentMethod.trim().toLowerCase(),
      'direccion': address.trim(),
      'subtotal_centavos': subtotal,
      'envio_centavos': shippingCents,
      'total_centavos': totalCents(subtotalCents: subtotal, shippingCents: shippingCents),
    };
  }
}

class AdminPedido {
  final int id;
  final String codigo;
  final String estado;
  final int totalCents;

  const AdminPedido({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.totalCents,
  });
}

class AdminPedidoRules {
  const AdminPedidoRules._();

  static String normalizeStatus(String status) {
    return status.trim().toLowerCase().replaceAll(' ', '_');
  }

  static bool canDispatch(String status) {
    final normalized = normalizeStatus(status);
    return normalized == 'pago_aprobado' || normalized == 'pendiente_bodega';
  }

  static bool canCancel(String status) {
    final normalized = normalizeStatus(status);
    return normalized != 'despachado' && normalized != 'cancelado';
  }

  static List<AdminPedido> filterByStatus(List<AdminPedido> pedidos, String status) {
    final normalized = normalizeStatus(status);
    return pedidos.where((pedido) => normalizeStatus(pedido.estado) == normalized).toList();
  }

  static Map<String, int> resumen(List<AdminPedido> pedidos) {
    final result = <String, int>{};
    for (final pedido in pedidos) {
      final key = normalizeStatus(pedido.estado);
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  static int totalCarteraCents(List<AdminPedido> pedidos) {
    return MoneyUtils.sum(pedidos.map((pedido) => pedido.totalCents));
  }

  static String buildDispatchCode(AdminPedido pedido) {
    final cleanCode = pedido.codigo.trim().isEmpty ? 'PED-${pedido.id}' : pedido.codigo.trim();
    return 'DSP-$cleanCode';
  }
}

class StoreMoodFixtures {
  const StoreMoodFixtures._();

  static Map<String, dynamic> loginResponse({String role = 'cliente'}) => {
        'plain_text_token': 'token-demo-123',
        'user': {
          'id': 1,
          'name': 'Cliente Demo',
          'email': 'CLIENTE@MOOD.COM',
          'role': role,
        },
      };

  static List<CartItem> cart() => const [
        CartItem(productId: 1, name: 'Labial Mood', unitPriceCents: 12500, quantity: 2),
        CartItem(productId: 2, name: 'Base Spazio', unitPriceCents: 30000, quantity: 1),
      ];

  static List<AdminPedido> pedidos() => const [
        AdminPedido(id: 1, codigo: 'PED-001', estado: 'pago_aprobado', totalCents: 55000),
        AdminPedido(id: 2, codigo: 'PED-002', estado: 'pendiente_bodega', totalCents: 22000),
        AdminPedido(id: 3, codigo: 'PED-003', estado: 'despachado', totalCents: 18000),
      ];
}
