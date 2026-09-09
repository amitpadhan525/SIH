import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inrFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats a decimal string (e.g. "650.00" or "12500.50") into Indian Rupee format (e.g. "₹650.00")
  /// Preserves decimal precision and handles null/empty gracefully.
  static String format(String? priceString) {
    if (priceString == null || priceString.trim().isEmpty) {
      return '₹0.00';
    }

    try {
      final double? parsed = double.tryParse(priceString.trim());
      if (parsed != null) {
        return _inrFormatter.format(parsed);
      }
    } catch (_) {}

    return '₹$priceString';
  }
}
