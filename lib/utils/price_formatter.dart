import '../models/property_model.dart';

String formatIndianPrice(double amount) {
  if (amount < 100000) {
    return '₹${_indianCommaFormat(amount)}';
  } else if (amount < 10000000) {
    return '₹${_trimTrailingZero(amount / 100000)} Lakh';
  } else {
    return '₹${_trimTrailingZero(amount / 10000000)} Cr';
  }
}

String _trimTrailingZero(double value) {
  String str = value.toStringAsFixed(2);
  str = str.replaceAll(RegExp(r'0+$'), '');
  str = str.replaceAll(RegExp(r'\.$'), '');
  return str;
}

String _indianCommaFormat(double amount) {
  final intAmount = amount.round();
  final str = intAmount.toString();
  if (str.length <= 3) return str;
  final lastThree = str.substring(str.length - 3);
  final rest = str.substring(0, str.length - 3);
  final regex = RegExp(r'(\d+?)(?=(\d{2})+(?!\d))');
  final restFormatted = rest.replaceAllMapped(regex, (m) => '${m[1]},');
  return '$restFormatted,$lastThree';
}

/// Poori app mein price dikhane ka EK hi tareeka.
String rateUnitLabel(Property p) => p.priceUnit == 'per_katha' ? 'Katha' : 'Sq.Ft.';

String rentUnitLabel(Property p) {
  const units = {'per_day': 'day', 'per_month': 'month', 'per_year': 'year'};
  return units[p.priceUnit] ?? 'month';
}

/// Cards/tiles ka main price: Sale = Total Price, Rent = rent per period.
String propertyPriceLabel(Property p) {
  if (p.listingType == 'sale') {
    final total = p.totalPrice ?? double.tryParse(p.price);
    if (total != null && total > 0) return formatIndianPrice(total);
    final rate = p.ratePerUnit;
    if (rate != null && rate > 0) return '${formatIndianPrice(rate)}/${rateUnitLabel(p)}';
    return 'Price on request';
  }

  final rent = p.rentAmount ?? double.tryParse(p.price);
  if (rent == null || rent <= 0) return 'Price on request';
  return '${formatIndianPrice(rent)}/${rentUnitLabel(p)}';
}

/// Sirf list card ki chhoti line: Sale mein total ke saath rate ho to "₹5,000/Sq.Ft."
String? propertySecondaryPriceLabel(Property p) {
  if (p.listingType != 'sale') return null;
  final rate = p.ratePerUnit;
  final total = p.totalPrice ?? double.tryParse(p.price);
  if (rate != null && rate > 0 && total != null && total > 0) {
    return '${formatIndianPrice(rate)}/${rateUnitLabel(p)}';
  }
  return null;
}