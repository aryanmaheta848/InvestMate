import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/screens/home/home_screen.dart';
import 'package:invest_mate/screens/portfolio/portfolio_screen.dart';
import 'package:invest_mate/screens/market/market_screen.dart';
import 'package:invest_mate/screens/watchlist/watchlist_screen.dart';
import 'package:invest_mate/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<MainScreenTab> _tabs = [
    MainScreenTab(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      screen: const HomeScreen(),
    ),
    MainScreenTab(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up,
      screen: const MarketScreen(),
    ),
    MainScreenTab(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      screen: const PortfolioScreen(),
    ),
    MainScreenTab(
      icon: Icons.bookmark_border_outlined,
      activeIcon: Icons.bookmark,
      screen: const WatchlistScreen(),
    ),
    MainScreenTab(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      screen: const ProfileScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: AppDurations.animationShort,
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _tabs.map((tab) => tab.screen).toList(),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Container(
                height: 56, // For better spacing
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingSmall,
                  vertical: 0, // Remove vertical padding for more vertical space
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _tabs.asMap().entries.map((entry) {
                    int index = entry.key;
                    MainScreenTab tab = entry.value;
                    bool isSelected = index == _currentIndex;

                    return Flexible(
                      flex: 1,
                      child: _buildNavItem(
                        tab: tab,
                        isSelected: isSelected,
                        onTap: () => _onTabTapped(index),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required MainScreenTab tab,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: AppDurations.animationShort,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSmall),
          ),
          child: Icon(
            isSelected ? tab.activeIcon : tab.icon,
            color: isSelected
                ? AppColors.primary
                : AppColors.onBackground,
            size: AppSizes.iconSize + 2,
          ),
        ),
      ),
    );
  }
}

class MainScreenTab {
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  MainScreenTab({
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

// Navigation helper for external navigation to specific tabs
class MainScreenNavigation {
  static void navigateToTab(BuildContext context, int tabIndex) {
    final mainScreenState = context.findAncestorStateOfType<_MainScreenState>();
    if (mainScreenState != null) {
      mainScreenState._onTabTapped(tabIndex);
    }
  }

  static const int homeTab = 0;
  static const int marketTab = 1;
  static const int portfolioTab = 2;
  static const int watchlistTab = 3;
  static const int profileTab = 4;
}
