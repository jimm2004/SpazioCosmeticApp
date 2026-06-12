/// Utilidades para manejar dinero en centavos.
///
/// Evita errores de precisión por usar `double` directamente en cálculos
/// monetarios. La app puede seguir mostrando decimales, pero internamente
/// los totales deben calcularse como enteros.
class MoneyUtils {
  const MoneyUtils._();

  static int toCents(num amount) {
    return (amount * 100).round();
  }

  static double fromCents(int cents) {
    return cents / 100;
  }

  static int add(int a, int b) {
    return a + b;
  }

  static int subtract(int a, int b) {
    return a - b;
  }

  static int multiply(int cents, int quantity) {
    if (quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity', 'No puede ser negativo');
    }
    return cents * quantity;
  }

  static int sum(Iterable<int> values) {
    return values.fold<int>(0, (previous, current) => previous + current);
  }

  static String formatCordobas(int cents) {
    final value = fromCents(cents).toStringAsFixed(2);
    return 'C\$ $value';
  }

  static String formatUsd(int cents) {
    final value = fromCents(cents).toStringAsFixed(2);
    return '\$ $value';
  }

  static int applyDiscount(int cents, int discountCents) {
    final result = cents - discountCents;
    return result < 0 ? 0 : result;
  }
}
