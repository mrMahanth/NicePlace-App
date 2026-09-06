import 'package:shared_preferences/shared_preferences.dart';

class RecentSearchesHelper {
  static const _key = 'recent_searches';
  static const _maxEntries = 2; // per spec: "last 1-2 areas the user viewed"

  static Future<List<String>> getRecent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> addRecent(String value) async {
    if (value.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? [];
    current.remove(value); // avoid duplicates, keep most-recent-first
    current.insert(0, value);
    final trimmed = current.take(_maxEntries).toList();
    await prefs.setStringList(_key, trimmed);
  }
}