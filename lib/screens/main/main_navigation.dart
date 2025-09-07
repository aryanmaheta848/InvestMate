import 'package:flutter/material.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/screens/home/home_screen.dart';
import 'package:invest_mate/screens/portfolio/portfolio_screen.dart';
import 'package:invest_mate/screens/watchlist/watchlist_screen.dart';
import 'package:invest_mate/screens/market/market_screen.dart';
import 'package:invest_mate/screens/profile/profile_screen.dart';
import 'package:flutter/services.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(key: PageStorageKey('home')),
    const MarketScreen(key: PageStorageKey('market')),
    const PortfolioScreen(key: PageStorageKey('portfolio')),
    const WatchlistScreen(key: PageStorageKey('watchlist')),
    const ProfileScreen(key: PageStorageKey('profile')),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      color: AppColors.primary,
    ),
    NavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up_rounded,
      color: AppColors.secondary,
    ),
    NavigationItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      color: AppColors.success,
    ),
    NavigationItem(
      icon: Icons.bookmark_border_outlined,
      activeIcon: Icons.bookmark_rounded,
      color: AppColors.warning,
    ),
    NavigationItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      color: AppColors.info,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: AppColors.shadow.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 60, // slightly taller for icons
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = _currentIndex == index;

                return Flexible(
                  flex: 1,
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? item.color.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? item.color
                              : AppColors.onBackground.withOpacity(0.6),
                          size: 28, // Larger icon for logo effect
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.color,
  });
}

// Navigation helper for external navigation to specific tabs
class MainNavigationHelper {
  static void navigateToTab(BuildContext context, int tabIndex) {
    final mainNavigationState = context.findAncestorStateOfType<_MainNavigationState>();
    if (mainNavigationState != null) {
      mainNavigationState._onItemTapped(tabIndex);
    }
  }

  static const int homeTab = 0;
  static const int marketTab = 1;
  static const int portfolioTab = 2;
  static const int watchlistTab = 3;
  static const int profileTab = 4;
}
