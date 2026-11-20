import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';

/// Screen ko apne aap refresh karta hai (website ke usePolling jaisa).
/// - Screen dikh rahi ho aur app khula ho tabhi har [seconds] second mein refresh
/// - Doosri screen se wapas aane par aur app resume par turant refresh
class AutoRefresher with WidgetsBindingObserver implements RouteAware {
  final Future<void> Function() onRefresh;
  final int seconds;

  AutoRefresher({required this.onRefresh, this.seconds = 10});

  Timer? _timer;
  bool _busy = false;
  bool _visible = false;
  bool _appActive = true;
  bool _disposed = false;
  bool _started = false;

  /// didChangeDependencies() mein call karna
  void start(BuildContext context) {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    } else {
      _visible = true;
      _startTimer();
    }
  }

  /// dispose() mein call karna
  void dispose() {
    _disposed = true;
    _stopTimer();
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(Duration(seconds: seconds), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (_disposed || _busy || !_visible || !_appActive) return;
    _busy = true;
    try {
      await onRefresh();
    } catch (_) {
      // silent refresh: error par user ko disturb nahi karna
    } finally {
      _busy = false;
    }
  }

  // ---- RouteAware ----
  @override
  void didPush() {
    _visible = true;
    _startTimer();
  }

  @override
  void didPopNext() {
    // upar wali screen band hui, hum wapas top par aaye
    _visible = true;
    _tick();
    _startTimer();
  }

  @override
  void didPushNext() {
    // hamare upar nayi screen khuli
    _visible = false;
    _stopTimer();
  }

  @override
  void didPop() {
    _visible = false;
    _stopTimer();
  }

  // ---- App background / foreground ----
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appActive = true;
      if (_visible) {
        _tick();
        _startTimer();
      }
    } else {
      _appActive = false;
      _stopTimer();
    }
  }
}