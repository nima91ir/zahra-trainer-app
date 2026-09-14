import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Material 3 bottom navigation with 3 items:
///   داشبورد  ·  کلاینت‌ها  ·  برنامه‌ها
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppTokens.surface,
      indicatorColor: AppTokens.primary.withValues(alpha: 0.24),
      elevation: 0,
      height: 68,
      labelBehavior:
          NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined, size: 22),
          selectedIcon: Icon(Icons.dashboard, size: 22),
          label: 'داشبورد',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline, size: 22),
          selectedIcon: Icon(Icons.people, size: 22),
          label: 'کلاینت‌ها',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined, size: 22),
          selectedIcon: Icon(Icons.list_alt, size: 22),
          label: 'برنامه‌ها',
        ),
      ],
    );
  }
}