import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/user_profile_service.dart';

enum _UsernameStatus { idle, checking, available, taken, unknown }

class SetUsernameScreen extends StatefulWidget {
  const SetUsernameScreen({super.key});

  @override
  State<SetUsernameScreen> createState() => _SetUsernameScreenState();
}

class _SetUsernameScreenState extends State<SetUsernameScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _usernameFocusNode = FocusNode();

  _UsernameStatus _usernameStatus = _UsernameStatus.idle;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) _checkUsername();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkUsername() async {
    final value = _usernameController.text.trim();
    if (value.isEmpty) {
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

  Future<void> _handleConfirm() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final password2 = _password2Controller.text;

    if (username.isEmpty) {
      setState(() => _errorMessage = "Please enter a username.");
      return;
    }
    if (_usernameStatus == _UsernameStatus.taken) {
      setState(() => _errorMessage = "That username is already taken. Please choose another.");
      return;
    }
    if (password.isEmpty || password2.isEmpty) {
      setState(() => _errorMessage = "Please enter and confirm your password.");
      return;
    }
    if (password != password2) {
      setState(() => _errorMessage = "Passwords do not match.");
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final result = await UserProfileService.setUsername(
      username: username,
      password: password,
      password2: password2,
    );

    setState(() => _isSaving = false);

    if (result["success"] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Username and password set successfully!")),
        );
        Navigator.pop(context, true);
      }
    } else {
      setState(() => _errorMessage = _parseError(result["error"]));
    }
  }

  // The backend returns raw DRF validation-error JSON (e.g. {"username":
  // ["This username is already taken."]}) - pull out the first message so
  // the user sees plain text instead of a JSON blob.
  String _parseError(dynamic error) {
    try {
      final decoded = jsonDecode(error.toString());
      if (decoded is Map && decoded.isNotEmpty) {
        final firstValue = decoded.values.first;
        if (firstValue is List && firstValue.isNotEmpty) {
          return firstValue.first.toString();
        }
        return firstValue.toString();
      }
    } catch (_) {
      // fall through to generic message
    }
    return "Could not set username. Please try again.";
  }

  Widget? _usernameStatusIcon() {
    switch (_usernameStatus) {
      case _UsernameStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _UsernameStatus.available:
        return const Icon(Icons.check_circle, color: Colors.green);
      case _UsernameStatus.taken:
        return const Icon(Icons.cancel, color: Colors.red);
      case _UsernameStatus.unknown:
        return const Icon(Icons.error_outline, color: Colors.orange);
      case _UsernameStatus.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Username")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Set a username and password so you can also log in with your username "
              "or mobile number and password. You can keep using OTP any time - this is optional.",
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              decoration: InputDecoration(
                labelText: "Username",
                border: const OutlineInputBorder(),
                suffixIcon: _usernameStatusIcon(),
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
                child: Text("Already taken - try another.",
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            if (_usernameStatus == _UsernameStatus.available)
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 4),
                child: Text("Available!",
                    style: TextStyle(color: Colors.green, fontSize: 12)),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password2Controller,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: "Confirm Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),

            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text("Back"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _handleConfirm,
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text("Confirm"),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}