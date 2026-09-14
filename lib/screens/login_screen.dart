import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import '../widgets/phone_input_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _mode = 'otp'; // 'otp' or 'password' - OTP is the default/primary path

  // Password login fields
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // OTP login fields
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;

  bool _isLoading = false;
  String? _errorMessage;

  // ---------- PASSWORD LOGIN ----------
  Future<void> _handlePasswordLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result["success"] == true) {
      if (mounted) Navigator.pop(context, true);
    } else {
      setState(() {
        _errorMessage = result["error"] ??
            "Login failed. Please check your username and password.";
      });
    }
  }

  // ---------- OTP: SEND ----------
  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = "Please enter your phone number.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.requestOtp(phone);

    setState(() => _isLoading = false);

    if (result["success"] == true) {
      setState(() => _otpSent = true);

      // DEV MODE ONLY: backend returns the OTP directly since there's no
      // real SMS gateway yet. Remove this once SMS sending is live.
      final debugOtp = result["data"]?["debug_otp"];
      if (debugOtp != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Dev mode - your OTP is: $debugOtp")),
        );
      }
    } else {
      setState(() => _errorMessage = result["error"]);
    }
  }

  // ---------- OTP: VERIFY ----------
  Future<void> _handleVerifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.verifyOtp(
      _phoneController.text.trim(),
      _otpController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result["success"] == true) {
      final isNewUser = result["data"]?["is_new_user"] ?? false;

      if (isNewUser) {
        // Naya user - pehle unka profile complete karwao (push karo, pop nahi
        // karo abhi), phir hi is LoginScreen ka kaam khatam hoga.
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EditProfileScreen(isNewUserFlow: true),
            ),
          );
        }
      }

      // Ab poora flow (naye user ke liye profile+applock, ya existing user
      // ke liye seedha) khatam ho chuka hai - LoginScreen band karo.
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _errorMessage = result["error"]);
    }
  }

  void _switchMode(String mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
      _otpSent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NicePlace Login")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Log in or Create Account",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // ---------- MODE TOGGLE ----------
            // OTP first (primary/default path), Password second.
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'otp', label: Text("OTP")),
                  ButtonSegment(value: 'password', label: Text("Password")),
                ],
                selected: {_mode},
                onSelectionChanged: (selected) => _switchMode(selected.first),
              ),
            ),
            const SizedBox(height: 24),

            if (_mode == 'password') _buildPasswordForm(),
            if (_mode == 'otp') _buildOtpForm(),

            const SizedBox(height: 16),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 8),
            // "Register" is just the phone+OTP flow above, which already
            // detects new users and routes them into EditProfileScreen ->
            // lock prompt -> Home. Only shown from the Password tab, since
            // OTP is already the default/active tab otherwise.
            if (_mode != 'otp')
              TextButton(
                onPressed: () => _switchMode('otp'),
                child: const Text("New user? Register here"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Column(
      children: [
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: "Username or Mobile Number",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: "Password",
            border: OutlineInputBorder(),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => _switchMode('otp'),
            child: const Text("Forgot Password?"),
          ),
        ),
        const SizedBox(height: 8),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _handlePasswordLogin,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Login"),
              ),
      ],
    );
  }

  Widget _buildOtpForm() {
    return Column(
      children: [
        PhoneInputField(
          controller: _phoneController,
          enabled: !_otpSent,
        ),
        const SizedBox(height: 16),
        if (_otpSent) ...[
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Enter OTP",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => setState(() => _otpSent = false),
                child: const Text("Change phone number"),
              ),
              TextButton(
                onPressed: _isLoading ? null : _handleSendOtp,
                child: const Text("Resend OTP"),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _otpSent ? _handleVerifyOtp : _handleSendOtp,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(_otpSent ? "Verify & Login" : "Send OTP"),
              ),
      ],
    );
  }
}