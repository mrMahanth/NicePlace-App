import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/property_model.dart';
import '../services/api_service.dart';
import '../services/property_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'property_detail_screen.dart';

class SavedPropertiesScreen extends StatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  State<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends State<SavedPropertiesScreen> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  List<Property> _properties = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = await ApiService.getAccessToken();
    if (token == null) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }
    try {
      final properties = await PropertyService.fetchMySaved();
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _properties = properties;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToLogin() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Saved')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (!_isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bookmark_border, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              const Text('Please login to see your saved properties.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _goToLogin, child: const Text('Login')),
            ],
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'Nothing saved yet.\nProperties you save for later will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      itemCount: _properties.length,
      itemBuilder: (context, index) {
        final property = _properties[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: property)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              leading: property.media.any((m) => m.mediaType == 'image')
                  ? CachedNetworkImage(
                      imageUrl: property.media.firstWhere((m) => m.mediaType == 'image').file!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.home, size: 40),
              title: Text(property.title),
              subtitle: Text("${property.locality}, ${property.city}",
                  style: const TextStyle(color: AppColors.textMuted)),
            ),
          ),
        );
      },
    );
  }
}