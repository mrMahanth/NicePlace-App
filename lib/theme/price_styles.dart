import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Detail screen ke price block ke saare styles yahin se control hote hain.
/// Size, weight ya color badalna ho to sirf is file mein badlein.
class PriceStyles {
  // ---- Headline (Total Price / Rent) ----
  static final TextStyle headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  // Headline ke upar chhota caption ("Total Price", "Rent")
  static final TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    color: AppColors.textMuted,
  );

  // ---- Neeche ke rows (Rate, Booking, Security, Maintenance) ----
  static final TextStyle rowLabel = TextStyle(
    fontSize: 13,
    color: AppColors.textMuted,
  );

  static final TextStyle rowValue = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Booking Amount ko alag dikhane ke liye
  static final TextStyle rowValueAccent = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  // ---- Negotiable badge ----
  static final Color negotiableText = AppColors.success;
  static final Color negotiableBackground = AppColors.success.withValues(alpha: 0.12);
  static const double negotiableFontSize = 11;

  // ---- Rows ka box ----
  static final Color boxBorder = AppColors.cardBorder;
  static const double boxRadius = 10;
  static const EdgeInsets boxPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 4);
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 9);
}