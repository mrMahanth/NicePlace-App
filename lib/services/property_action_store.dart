import 'package:flutter/foundation.dart';

/// Ek hi jagah jahan har property ka favourite/save/interested status yaad rehta hai.
/// Card, detail screen, carousel - sab yahin se padhte hain, isliye ek jagah toggle
/// karne par baaki sab jagah turant update ho jaata hai.
class PropertyActionStore extends ChangeNotifier {
  PropertyActionStore._();
  static final PropertyActionStore instance = PropertyActionStore._();

  final Map<int, Map<String, bool>> _overrides = {};

  bool? get(int propertyId, String actionType) => _overrides[propertyId]?[actionType];

  void set(int propertyId, String actionType, bool value) {
    _overrides.putIfAbsent(propertyId, () => {})[actionType] = value;
    notifyListeners();
  }

  void clear() {
    _overrides.clear();
    notifyListeners();
  }
}