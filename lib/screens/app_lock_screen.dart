import 'package:flutter/material.dart';
import '../services/app_lock_service.dart';
import 'main_screen.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Screen khulte hi automatically lock prompt dikhao
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryUnlock());
  }

  Future<void> _tryUnlock() async {
    setState(() => _isChecking = true);

    final bool isAvailable = await AppLockService.isDeviceLockAvailable();

    if (!isAvailable) {
      // Agar phone mein koi lock hi set nahi hai, seedha andar jaane do
      _goToApp();
      return;
    }

    final bool success = await AppLockService.authenticate();

    setState(() => _isChecking = false);

    if (success) {
      _goToApp();
    }
    // Agar fail ho, user isi screen par rahega, "Try Again" button dabana padega
  }

  void _goToApp() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              "NicePlace",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _isChecking
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text("Unlock"),
                    onPressed: _tryUnlock,
                  ),
          ],
        ),
      ),
    );
  }
}