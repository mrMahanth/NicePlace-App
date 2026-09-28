// Shared helpers for handling prices/amounts coming from the Django backend.
//
// WHY THIS EXISTS:
// DRF's DecimalField serializes to JSON as a STRING (e.g. "15000.00"), not a
// number - by design, to avoid floating-point precision loss on money values.
// Any Dart code that blindly does `(json['field'] as num?)` on a Decimal-backed
// field will crash at runtime with a type error that's easy to miss inside a
// try/catch (it silently swallows and shows a generic "could not load" instead).
//
// RULE GOING FORWARD: Use parseFlexibleDouble() for EVERY price/amount field
// read from the API. Use formatPrice() whenever a parsed value is shown to the
// user or put into a text field, so we never show "15000.0" or "15000.00" -
// only "15000" (no decimals) or "15000.5" (decimals trimmed of trailing zeros).
class NumberUtils {
  NumberUtils._();

  /// Safely converts a JSON value that might be a String (DRF Decimal),
  /// a num (plain JSON number), or null, into a double.
  static double? parseFlexibleDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Formats a price/amount for display or for populating a text field:
  /// whole numbers show with no decimal point at all, and any decimal
  /// part is trimmed of trailing zeros (never "15000.00" or "15000.0").
  static String formatPrice(num? value) {
    if (value == null) return '';
    final d = value.toDouble();
    if (d == d.roundToDouble()) {
      return d.toInt().toString();
    }
    String s = d.toString();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}