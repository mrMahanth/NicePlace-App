import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'theme/app_theme.dart';

// App-wide RouteObserver - screens jo "wapas top par aane par refresh" chahti hain,
// isko subscribe karke didPopNext() implement karte hain (RouteAware).
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const NicePlaceApp());
}

class NicePlaceApp extends StatelessWidget {
  const NicePlaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NicePlace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorObservers: [routeObserver],
      home: const SplashScreen(),
    );
  }
}