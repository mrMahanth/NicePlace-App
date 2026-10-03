import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import '../models/rental_agreement_model.dart';

class TenancyService {
  // ---------- Step 1: Phone check ----------
  static Future<Map<String, dynamic>> checkPhone(String phone) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/rental-agreements/check_phone/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({"phone": phone}),
        );
      });
      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      }
      return {"success": false, "error": "Something went wrong. Please try again."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/rental-agreements/send_otp/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({"phone": phone}),
        );
      });
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "error": "Could not send verification code."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> verifyAndCreate({
    required String phone,
    required String otp,
    required int propertyId,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/rental-agreements/verify_and_create/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({"phone": phone, "otp": otp, "property": propertyId}),
        );
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true};
      }
      return {"success": false, "error": "Invalid or expired code. Please try again."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> createUnverified({
    required int propertyId,
    required String renterName,
    required String renterPhone,
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/rental-agreements/create_unverified/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({
            "property": propertyId,
            "renter_name": renterName,
            "renter_phone": renterPhone,
          }),
        );
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {"success": true};
      }
      return {"success": false, "error": "Could not save. Please try again."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  // ---------- Rent Tracking screen ----------
  static Future<Map<String, dynamic>> fetchCurrentAgreement(int propertyId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse(
            "${ApiService.baseUrl}/rental-agreements/current_for_property/?property=$propertyId");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });
      if (response.statusCode == 200) {
        return {"success": true, "data": RentalAgreement.fromJson(jsonDecode(response.body))};
      } else if (response.statusCode == 404) {
        return {"success": false, "notFound": true, "error": "No active tenancy found."};
      }
      return {"success": false, "error": "Could not load tenancy info."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> fetchPropertyHistory(int propertyId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse(
            "${ApiService.baseUrl}/rental-agreements/property_history/?property=$propertyId");
        return http.get(url, headers: {"Authorization": "Bearer $token"});
      });
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return {"success": true, "data": list.map((a) => RentalAgreement.fromJson(a)).toList()};
      }
      return {"success": false, "error": "Could not load history."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> markPayment({
    required int agreementId,
    required int month,
    required int year,
    required double amount,
    required String paymentMode,
    String remarks = '',
  }) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/rental-agreements/$agreementId/mark_payment/");
        return http.post(
          url,
          headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
          body: jsonEncode({
            "month": month,
            "year": year,
            "amount": amount,
            "payment_mode": paymentMode,
            "remarks": remarks,
          }),
        );
      });
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "error": "Could not mark payment. Please try again."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }

  static Future<Map<String, dynamic>> endTenancy(int agreementId) async {
    try {
      final response = await ApiService.authorizedRequest((token) {
        final url = Uri.parse("${ApiService.baseUrl}/rental-agreements/$agreementId/end_tenancy/");
        return http.post(url, headers: {"Authorization": "Bearer $token"});
      });
      if (response.statusCode == 200) {
        return {"success": true};
      }
      return {"success": false, "error": "Could not end tenancy."};
    } catch (e) {
      return {"success": false, "error": "Login required"};
    }
  }
}