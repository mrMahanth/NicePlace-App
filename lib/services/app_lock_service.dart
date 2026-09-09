import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = "app_lock_enabled";

  // Check karta hai ki phone mein koi lock (fingerprint/PIN/pattern) set hai ya nahi
  static Future<bool> isDeviceLockAvailable() async {
    final bool canCheck = await _auth.canCheckBiometrics;
    final bool isSupported = await _auth.isDeviceSupported();
    return canCheck || isSupported;
  }

  // Actual mein lock screen dikhata hai (fingerprint/face/PIN/pattern - jo bhi phone mein set hai)
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'NicePlace app kholne ke liye verify karo',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  // ---------- NAYA: App Lock ON/OFF state ----------
  static Future<bool> isAppLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false; // default OFF
  }

  static Future<void> setAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, enabled);
  }
}