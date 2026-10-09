import 'package:flutter/material.dart';
import '../models/property_model.dart';
import '../theme/price_styles.dart';
import '../utils/price_formatter.dart';

/// Detail screen ka poora price section (headline + details box).
class PropertyPriceBlock extends StatelessWidget {
  final Property property;

  const PropertyPriceBlock({super.key, required this.property});

  Widget _negotiableBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: PriceStyles.negotiableBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Negotiable',
        style: TextStyle(
          fontSize: PriceStyles.negotiableFontSize,
          fontWeight: FontWeight.w700,
          color: PriceStyles.negotiableText,
        ),
      ),
    );
  }

  Widget _headline(String caption, String value, bool negotiable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption.toUpperCase(), style: PriceStyles.caption),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(child: Text(value, style: PriceStyles.headline)),
            if (negotiable) _negotiableBadge(),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool negotiable = false, bool accent = false}) {
    return Padding(
      padding: PriceStyles.rowPadding,
      child: Row(
        children: [
          Expanded(child: Text(label, style: PriceStyles.rowLabel)),
          Text(value, style: accent ? PriceStyles.rowValueAccent : PriceStyles.rowValue),
          if (negotiable) _negotiableBadge(),
        ],
      ),
    );
  }

  Widget _box(List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    for (int i = 0; i < rows.length; i++) {
      children.add(rows[i]);
      if (i != rows.length - 1) {
        children.add(Divider(height: 1, color: PriceStyles.boxBorder));
      }
    }
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: PriceStyles.boxPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(PriceStyles.boxRadius),
        border: Border.all(color: PriceStyles.boxBorder),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = property;

    if (p.listingType == 'sale') {
      final total = p.totalPrice ?? double.tryParse(p.price);
      final rate = p.ratePerUnit;
      final hasTotal = total != null && total > 0;
      final hasRate = rate != null && rate > 0;
      final rows = <Widget>[];

      if (hasTotal && hasRate) {
        rows.add(_row('Rate', '${formatIndianPrice(rate)}/${rateUnitLabel(p)}',
            negotiable: p.ratePerUnitNegotiable));
      }
      if (p.bookingPrice != null && p.bookingPrice! > 0) {
        rows.add(_row('Booking Amount', formatIndianPrice(p.bookingPrice!),
            negotiable: p.bookingPriceNegotiable, accent: true));
      }

      Widget headline;
      if (hasTotal) {
        headline = _headline('Total Price', formatIndianPrice(total), p.totalPriceNegotiable);
      } else if (hasRate) {
        headline = _headline('Rate', '${formatIndianPrice(rate)}/${rateUnitLabel(p)}', p.ratePerUnitNegotiable);
      } else {
        headline = _headline('Price', 'Price on request', false);
      }

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [headline, _box(rows)]);
    }

    // ---- Rent ----
    final rent = p.rentAmount ?? double.tryParse(p.price);
    final hasRent = rent != null && rent > 0;
    final rows = <Widget>[];
    if (p.securityDeposit != null && p.securityDeposit! > 0) {
      rows.add(_row('Security Deposit', formatIndianPrice(p.securityDeposit!),
          negotiable: p.securityDepositNegotiable));
    }
    if (p.maintenanceAmount != null && p.maintenanceAmount! > 0) {
      rows.add(_row('Maintenance', formatIndianPrice(p.maintenanceAmount!),
          negotiable: p.maintenanceNegotiable));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headline(
          'Rent',
          hasRent ? '${formatIndianPrice(rent)}/${rentUnitLabel(p)}' : 'Price on request',
          p.rentNegotiable,
        ),
        _box(rows),
      ],
    );
  }
}