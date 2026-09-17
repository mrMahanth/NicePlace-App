import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/api_service.dart';
import '../services/user_profile_service.dart';

enum _UsernameStatus { idle, checking, available, taken, unknown }

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _otpSent = false;
  String? _errorMessage;

  String _phone = '';
  String _originalUsername = '';
  bool _usernameEditable = false;
  _UsernameStatus _usernameStatus = _UsernameStatus.idle;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _otpController = TextEditingController();
  final _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) _checkUsername();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _otpController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final result = await UserProfileService.fetchMyProfile();
    if (result['success'] == true) {
      final profile = result['data'] as UserProfileModel;
      _phone = profile.phone;
      _originalUsername = profile.username;
      _usernameController.text = profile.username;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkUsername() async {
    final value = _usernameController.text.trim();
    if (!_usernameEditable || value.isEmpty || value == _originalUsername) {
      setState(() => _usernameStatus = _UsernameStatus.idle);
      return;
    }
    setState(() => _usernameStatus = _UsernameStatus.checking);
    final available = await UserProfileService.checkUsernameAvailable(value);
    if (!mounted) return;
    setState(() {
      if (available == null) {
        _usernameStatus = _UsernameStatus.unknown;
      } else {
        _usernameStatus = available ? _UsernameStatus.available : _UsernameStatus.taken;
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (_passwordController.text.isEmpty || _password2Controller.text.isEmpty) {
      setState(() => _errorMessage = "Please enter and confirm your new password.");
      return;
    }
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = "Password must be at least 8 characters.");
      return;
    }
    if (_passwordController.text != _password2Controller.text) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }
    if (_usernameStatus == _UsernameStatus.taken) {
      setState(() => _errorMessage = "That username is already taken. Please choose another.");
      return;
    }
    if (_phone.isEmpty) {
      setState(() => _errorMessage = "No registered phone number found for this account.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ApiService.requestOtp(_phone);

    setState(() => _isSubmitting = false);

    if (result["success"] == true) {
      setState(() => _otpSent = true);
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

  Future<void> _handleVerifyAndSave() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter the OTP.");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await UserProfileService.changePasswordWithOtp(
      username: _usernameEditable ? _usernameController.text.trim() : '',
      password: _passwordController.text,
      password2: _password2Controller.text,
      otpCode: _otpController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully!")),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              enabled: _usernameEditable && !_otpSent,
              decoration: InputDecoration(
                labelText: "Username",
                border: const OutlineInputBorder(),
                suffixIcon: _usernameStatus == _UsernameStatus.checking
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_usernameStatus == _UsernameStatus.available
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (_usernameStatus == _UsernameStatus.taken
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : null)),
              ),
              onChanged: (_) {
                if (_usernameStatus != _UsernameStatus.idle) {
                  setState(() => _usernameStatus = _UsernameStatus.idle);
                }
              },
            ),
            if (_usernameStatus == _UsernameStatus.taken)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  "UserName not available, Please try another one.",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            if (!_usernameEditable && !_otpSent)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _usernameEditable = true),
                  child: const Text("Change User Name"),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_otpSent,
              decoration: const InputDecoration(
                labelText: "New Password",
                helperText: "At least 8 characters.",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password2Controller,
              obscureText: true,
              enabled: !_otpSent,
              decoration: const InputDecoration(
                labelText: "Confirm Password",
                border: OutlineInputBorder(),
              ),
            ),
            if (_otpSent) ...[
              const SizedBox(height: 16),
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
                    child: const Text("Edit details"),
                  ),
                  TextButton(
                    onPressed: _isSubmitting ? null : _handleSendOtp,
                    child: const Text("Resend OTP"),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _otpSent ? _handleVerifyAndSave : _handleSendOtp,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text(_otpSent ? "Verify & Change Password" : "Change Password"),
                  ),
          ],
        ),
      ),
    );
  }
}