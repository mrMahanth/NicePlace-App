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