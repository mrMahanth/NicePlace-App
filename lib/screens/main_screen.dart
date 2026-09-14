import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'post_property_type_screen.dart';
import '../widgets/quick_links_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostPropertyTypeScreen()),
      );
      return;
    }
    if (index == 2) {
      showQuickLinksSheet(context);
      return;
    }
    // index == 0 (Home) - already showing, nothing to switch.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeScreen(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.apps), label: "Quick Links"),
        ],
      ),
    );
  }
}