import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'post_property_type_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      ProfileScreen(onLoggedOut: _handleLoggedOut),
    ];
  }

  void _handleLoggedOut() {
    setState(() => _selectedIndex = 0); // switch to Home tab
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You are logged out successfully")),
    );
  }

  void _onNavTap(int index) {
    // "Post Property" ek persistent tab nahi hai - ye Home/Profile ki tarah
    // IndexedStack mein switch nahi karta, balki seedha naye screen pe le jaata hai.
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PostPropertyTypeScreen()),
      );
      return;
    }

    // Home = index 0, Profile = index 2 -> _screens list mein 0 aur 1
    setState(() {
      _selectedIndex = index == 2 ? 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex == 1 ? 2 : _selectedIndex,
        onTap: _onNavTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: "Post"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}