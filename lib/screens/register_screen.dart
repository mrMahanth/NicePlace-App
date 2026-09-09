import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/phone_input_field.dart';
import 'enable_lock_prompt_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService.register({
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "username": _usernameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "password": _passwordController.text.trim(),
      "password2": _password2Controller.text.trim(),
    });

    setState(() {
      _isLoading = false;
    });

    if (result["success"] == true) {
      // Register hote hi automatically login bhi kar do (taaki dobara na maangna pade)
      final loginResult = await ApiService.login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        if (loginResult["success"] == true) {
          // Lock-prompt screen "push" karo (naya replace nahi) - iska result
          // wapas milega jab woh apna kaam khatam karke pop(true) karegi.
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EnableLockPromptScreen()),
          );

          // Ab is RegisterScreen ka bhi kaam khatam - LoginScreen ko batao
          // "sab successful raha" taaki wo bhi aage pop(true) kare.
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          // Auto-login fail hua kisi wajah se - user ko batao manually login
          // karna hoga, aur bina success flag ke wapas Login screen par bhej do
          // (jo already stack mein neeche maujood hai, dobara push nahi karna).
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Registration ho gaya, lekin auto-login fail hua. Please login karein.")),
            );
            Navigator.pop(context, false);
          }
        }
      }
    } else {
      setState(() {
        _errorMessage = "Registration failed: ${result["error"]}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Account")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "First Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Last Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: "Username", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            PhoneInputField(controller: _phoneController),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password2Controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _handleRegister,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text("Register"),
                  ),
          ],
        ),
      ),
    );
  }
}