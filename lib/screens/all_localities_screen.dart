import 'dart:async';
import 'package:flutter/material.dart';
import '../services/locality_service.dart';
import '../theme/app_theme.dart';

/// Opened when the user taps "See all" in the location bottom sheet.
/// Shows every locality with active properties, with a search box on top
/// to filter the list. Tapping a locality pops with its name, same as
/// tapping a tile in the bottom sheet.
class AllLocalitiesScreen extends StatefulWidget {
  final String? currentCity;

  const AllLocalitiesScreen({super.key, this.currentCity});

  @override
  State<AllLocalitiesScreen> createState() => _AllLocalitiesScreenState();
}

class _AllLocalitiesScreenState extends State<AllLocalitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<String> _localities = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await LocalityService.fetchLocalitiesWithProperties(
        city: widget.currentCity ?? 'Patna',
        query: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _localities = results;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('All Localities')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search localities...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _localities.isEmpty
                    ? const Center(child: Text('No localities found.'))
                    : ListView.separated(
                        itemCount: _localities.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final locality = _localities[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                            title: Text(locality),
                            onTap: () => Navigator.pop(context, locality),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}