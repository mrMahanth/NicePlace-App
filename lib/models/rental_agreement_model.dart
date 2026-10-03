double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class RentPayment {
  final int id;
  final int month; // 1-12
  final int year;
  final double amount;
  final String status; // pending, paid
  final String paymentMode;
  final String remarks;
  final String? markedAt;

  RentPayment({
    required this.id,
    required this.month,
    required this.year,
    required this.amount,
    required this.status,
    required this.paymentMode,
    required this.remarks,
    this.markedAt,
  });

  factory RentPayment.fromJson(Map<String, dynamic> json) {
    return RentPayment(
      id: json['id'],
      month: json['month'],
      year: json['year'],
      amount: _parseDouble(json['amount']) ?? 0,
      status: json['status'] ?? 'pending',
      paymentMode: json['payment_mode'] ?? '',
      remarks: json['remarks'] ?? '',
      markedAt: json['marked_at'],
    );
  }
}

class RentalAgreement {
  final int id;
  final int propertyId;
  final String propertyTitle;
  final String renterName;
  final String renterPhone;
  final bool isPhoneVerified;
  final String startDate;
  final bool isActive;
  final List<RentPayment> payments;

  RentalAgreement({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.renterName,
    required this.renterPhone,
    required this.isPhoneVerified,
    required this.startDate,
    required this.isActive,
    required this.payments,
  });

  factory RentalAgreement.fromJson(Map<String, dynamic> json) {
    return RentalAgreement(
      id: json['id'],
      propertyId: json['property'],
      propertyTitle: json['property_title'] ?? '',
      renterName: json['renter_name'] ?? '',
      renterPhone: json['renter_phone'] ?? '',
      isPhoneVerified: json['is_phone_verified'] ?? false,
      startDate: json['start_date'] ?? '',
      isActive: json['is_active'] ?? true,
      payments: (json['payments'] as List<dynamic>? ?? [])
          .map((p) => RentPayment.fromJson(p))
          .toList(),
    );
  }
}