// Local-only model: ek unit jo abhi tak sirf phone mein compose ho raha hai,
// server pe "Create All Units" dabane tak nahi jaata.
class UnitDraft {
  String unitNumber;
  String listingType; // 'rent' or 'sale'
  String status; // 'draft', 'sold', 'rented'

  double? rentAmount;
  bool rentNegotiable;
  double? securityDeposit;
  bool securityDepositNegotiable;
  double? maintenanceAmount;
  bool maintenanceNegotiable;

  double? totalPrice;
  bool totalPriceNegotiable;
  double? ratePerUnit;
  bool ratePerUnitNegotiable;
  double? bookingPrice;
  bool bookingPriceNegotiable;

  Map<int, dynamic> attributeValues; // attrId -> String ya Set<String>

  UnitDraft({
    this.unitNumber = '',
    this.listingType = 'rent',
    this.status = 'draft',
    this.rentAmount,
    this.rentNegotiable = false,
    this.securityDeposit,
    this.securityDepositNegotiable = false,
    this.maintenanceAmount,
    this.maintenanceNegotiable = false,
    this.totalPrice,
    this.totalPriceNegotiable = false,
    this.ratePerUnit,
    this.ratePerUnitNegotiable = false,
    this.bookingPrice,
    this.bookingPriceNegotiable = false,
    Map<int, dynamic>? attributeValues,
  }) : attributeValues = attributeValues ?? {};

  // "Duplicate copies pricing+attributes into a new blank-numbered unit"
  UnitDraft duplicate() {
    return UnitDraft(
      unitNumber: '',
      listingType: listingType,
      status: status,
      rentAmount: rentAmount,
      rentNegotiable: rentNegotiable,
      securityDeposit: securityDeposit,
      securityDepositNegotiable: securityDepositNegotiable,
      maintenanceAmount: maintenanceAmount,
      maintenanceNegotiable: maintenanceNegotiable,
      totalPrice: totalPrice,
      totalPriceNegotiable: totalPriceNegotiable,
      ratePerUnit: ratePerUnit,
      ratePerUnitNegotiable: ratePerUnitNegotiable,
      bookingPrice: bookingPrice,
      bookingPriceNegotiable: bookingPriceNegotiable,
      attributeValues: Map<int, dynamic>.from(attributeValues),
    );
  }

  String priceSummary() {
    if (listingType == 'rent') {
      return rentAmount != null ? "Rent: ₹${rentAmount!.toStringAsFixed(0)}" : "Rent: not set";
    } else {
      return totalPrice != null ? "Price: ₹${totalPrice!.toStringAsFixed(0)}" : "Price: not set";
    }
  }

  Map<String, dynamic> toApiJson() {
    final Map<String, dynamic> attrs = {};
    attributeValues.forEach((attrId, value) {
      if (value == null) return;
      if (value is Set<String>) {
        if (value.isEmpty) return;
        attrs[attrId.toString()] = value.join(', ');
      } else {
        final s = value.toString().trim();
        if (s.isEmpty) return;
        attrs[attrId.toString()] = s;
      }
    });

    final Map<String, dynamic> json = {
      "unit_number": unitNumber,
      "listing_type": listingType,
      "status": status,
      "attributes": attrs,
    };

    if (listingType == 'rent') {
      json["rent_amount"] = rentAmount;
      json["rent_negotiable"] = rentNegotiable;
      json["security_deposit"] = securityDeposit;
      json["security_deposit_negotiable"] = securityDepositNegotiable;
      json["maintenance_amount"] = maintenanceAmount;
      json["maintenance_negotiable"] = maintenanceNegotiable;
    } else {
      json["total_price"] = totalPrice;
      json["total_price_negotiable"] = totalPriceNegotiable;
      json["rate_per_unit"] = ratePerUnit;
      json["rate_per_unit_negotiable"] = ratePerUnitNegotiable;
      json["booking_price"] = bookingPrice;
      json["booking_price_negotiable"] = bookingPriceNegotiable;
    }

    return json;
  }

  // DRF DecimalField ko JSON mein String bhejta hai (e.g. "1000.00"), number nahi -
  // ye helper dono format (String ya number) ko safely double mein badal deta hai.
  static double? _parseFlexibleDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory UnitDraft.fromExistingUnitJson(
    Map<String, dynamic> json,
    List<int> checkboxAttributeIds,
  ) {
    final draft = UnitDraft(
      unitNumber: '', // blank-numbered, per spec
      listingType: json['listing_type'] ?? 'rent',
      status: 'draft', // duplicate hamesha naya draft hi banta hai
      rentAmount: _parseFlexibleDouble(json['rent_amount']),
      rentNegotiable: json['rent_negotiable'] ?? false,
      securityDeposit: _parseFlexibleDouble(json['security_deposit']),
      securityDepositNegotiable: json['security_deposit_negotiable'] ?? false,
      maintenanceAmount: _parseFlexibleDouble(json['maintenance_amount']),
      maintenanceNegotiable: json['maintenance_negotiable'] ?? false,
      totalPrice: _parseFlexibleDouble(json['total_price']),
      totalPriceNegotiable: json['total_price_negotiable'] ?? false,
      ratePerUnit: _parseFlexibleDouble(json['rate_per_unit']),
      ratePerUnitNegotiable: json['rate_per_unit_negotiable'] ?? false,
      bookingPrice: _parseFlexibleDouble(json['booking_price']),
      bookingPriceNegotiable: json['booking_price_negotiable'] ?? false,
    );

    final attributeValues = json['attribute_values'] as List<dynamic>? ?? [];
    for (final av in attributeValues) {
      final attrId = av['attribute_definition'];
      final value = av['value'];
      if (value == null || value == '') continue;
      if (checkboxAttributeIds.contains(attrId)) {
        draft.attributeValues[attrId] =
            (value as String).split(',').map((e) => e.trim()).toSet();
      } else {
        draft.attributeValues[attrId] = value;
      }
    }

    return draft;
  }
}