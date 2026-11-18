import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/property_model.dart';
import '../services/public_profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/property_card_list.dart';
import 'property_detail_screen.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;

  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final result = await PublicProfileService.fetchPublicProfile(widget.username);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _profile = result['data'] as Map<String, dynamic>;
      } else {
        _error = result['error'] as String?;
      }
    });
  }

  Future<void> _launch(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open this link.")),
      );
    }
  }

  Widget _buildBody() {
    final p = _profile!;
    final firstName = (p['first_name'] ?? '').toString();
    final lastName = (p['last_name'] ?? '').toString();
    final fullName = '$firstName $lastName'.trim();
    final displayName = fullName.isNotEmpty ? fullName : (p['username'] ?? widget.username).toString();
    final photo = p['profile_photo'] as String?;
    final phone = (p['phone'] ?? '').toString();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final agencyName = (p['agency_name'] ?? '').toString();
    final verified = p['registration_verified'] == true;
    final regLabel = (p['registration_label'] ?? '').toString();
    final regNumber = (p['registration_number'] ?? '').toString();
    final isAgent = p['is_agent'] == true;
    final listings = (p['listings'] as List<dynamic>? ?? []).map((l) => Property.fromJson(l)).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary,
                  backgroundImage: (photo != null && photo.isNotEmpty) ? CachedNetworkImageProvider(photo) : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(displayName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      if (verified) ...[
                        if (agencyName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(agencyName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified, size: 18, color: AppColors.success),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [regLabel, regNumber].where((s) => s.isNotEmpty).join(' · '),
                                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ] else if (isAgent)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Agent',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                        onPressed: () => _launch(Uri(scheme: 'tel', path: phone)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        onPressed: () => _launch(Uri.parse('https://wa.me/91$digits')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              listings.isEmpty ? "$displayName's Listings" : "$displayName's Listings (${listings.length})",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          if (listings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('No live listings yet.', style: TextStyle(color: AppColors.textMuted)),
            ),
          ...listings.map((property) => PropertyCardList(
                property: property,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PropertyDetailScreen(property: property)),
                ),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Try Again')),
                      ],
                    ),
                  ),
                )
              : _buildBody(),
    );
  }
}