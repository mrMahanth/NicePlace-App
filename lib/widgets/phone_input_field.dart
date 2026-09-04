import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// A reusable phone number input field with a fixed +91 (India) prefix.
// The controller always holds just the 10-digit number (no +91) -
// that's what gets sent to the backend, matching existing phone formats.
class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.labelText = "Mobile Number",
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          width: 90,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("🇮🇳", style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text("+91", style: TextStyle(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}