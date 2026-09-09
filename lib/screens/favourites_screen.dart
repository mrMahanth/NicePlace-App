import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// Placeholder screen - wire this up to real favourited-property data later.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Favourites')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'No favourites yet.\nProperties you mark as favourite will show up here.',
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