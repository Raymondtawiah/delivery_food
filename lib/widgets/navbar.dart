import 'package:flutter/material.dart';
import '../main.dart' show AppColors;

class Navbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? userName;
  final bool isLoggedIn;

  const Navbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.userName,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.burntOrange,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu_outlined),
          activeIcon: Icon(Icons.restaurant_menu),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(
            userName != null ? Icons.person : Icons.person_outline,
          ),
          activeIcon: Icon(
            userName != null ? Icons.person : Icons.person_outline,
          ),
          label: userName ?? 'Sign In',
        ),
      ],
    );
  }
}