import 'dart:async';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// Poore app ka ek badge counter. Koi bhi screen isko sun sakti hai.
class BadgeStore {
  static final ValueNotifier<int> unread = ValueNotifier<int>(0);
  static Timer? _timer;

  static Future<void> refresh() async {
    unread.value = await NotificationService.fetchUnreadCount();
  }

  /// Home/main screen khulte hi ek baar call karo
  static void start({int seconds = 20}) {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => refresh());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}