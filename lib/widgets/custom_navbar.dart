import 'package:flutter/material.dart';
import '../main.dart' show AppColors;

class CustomNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;
  final String? userName;

  const CustomNavbar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
    this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.burntOrange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onItemTapped,
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
      ),
    );
  }
}