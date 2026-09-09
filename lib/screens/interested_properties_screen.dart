import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Placeholder screen - wire this up to real "interested" property data later.
class InterestedPropertiesScreen extends StatelessWidget {
  const InterestedPropertiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Interested')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thumb_up_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No interests marked yet.\nProperties you show interest in will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}