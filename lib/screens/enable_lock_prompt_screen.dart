import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';

class EnableLockPromptScreen extends StatefulWidget {
  const EnableLockPromptScreen({super.key});

  @override
  State<EnableLockPromptScreen> createState() => _EnableLockPromptScreenState();
}

class _EnableLockPromptScreenState extends State<EnableLockPromptScreen> {
  bool _isProcessing = false;

  Future<void> _enableLock() async {
    setState(() => _isProcessing = true);

    final bool available = await AppLockService.isDeviceLockAvailable();

    if (!available) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aapke phone mein koi lock (PIN/Pattern/Fingerprint) set nahi hai. Pehle phone settings mein lock set karein.")),
        );
      }
      return;
    }

    final bool success = await AppLockService.authenticate();

    setState(() => _isProcessing = false);

    if (success) {
      await AppLockService.setAppLockEnabled(true);
      _finish();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verification fail hua, dobara try karein.")),
        );
      }
    }
  }

  void _skip() {
    _finish();
  }

  // Is screen ka kaam khatam - upar wali screen (Register/Login) ko batao
  // "registration process poora hua" (true) taaki wo bhi apni stack neeche
  // tak yehi result pop karte hue bhej de.
  void _finish() {
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fingerprint, size: 90, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              "Enable App Lock?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Secure the app using your phone's fingerprint, face, PIN or pattern. You won't need to log in every time — just verify when opening the app.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _enableLock,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Enable App Lock"),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isProcessing ? null : _skip,
              child: const Text("Skip for now"),
            ),
          ],
        ),
      ),
    );
  }
}