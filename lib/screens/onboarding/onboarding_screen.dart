import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Track Your Investments',
      description: 'Stay updated with real-time stock prices, market trends, and personalized watchlists',
      icon: Icons.trending_up_rounded,
      color: AppColors.primary,
    ),
    OnboardingPage(
      title: 'Get Smart Insights',
      description: 'AI-powered sentiment analysis and news aggregation to make informed decisions',
      icon: Icons.psychology_rounded,
      color: AppColors.accent,
    ),
    OnboardingPage(
      title: 'Invest Together',
      description: 'Join investment clubs, collaborate with friends, and learn from experienced investors',
      icon: Icons.groups_rounded,
      color: AppColors.secondary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    Get.offAll(() => const LoginScreen());
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppDurations.animationMedium,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDurations.animationMedium,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 60), // Placeholder for centering
                  Text(
                    AppConstants.appName,
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(page: _pages[index]);
                },
              ),
            ),

            // Page Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: AppDurations.animationShort,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous Button
                  _currentPage > 0
                      ? TextButton.icon(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back_ios),
                          label: const Text('Previous'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.onBackground,
                          ),
                        )
                      : const SizedBox(width: 100),

                  // Next/Get Started Button
                  ElevatedButton.icon(
                    onPressed: _nextPage,
                    icon: Icon(
                      _currentPage == _pages.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_ios,
                    ),
                    label: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.paddingLarge,
                        vertical: AppSizes.padding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingPageWidget extends StatefulWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({
    super.key,
    required this.page,
  });

  @override
  State<OnboardingPageWidget> createState() => _OnboardingPageWidgetState();
}

class _OnboardingPageWidgetState extends State<OnboardingPageWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _iconAnimation;
  late Animation<double> _textAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animation
          AnimatedBuilder(
            animation: _iconAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _iconAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: widget.page.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.page.color.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.page.icon,
                    size: 80,
                    color: widget.page.color,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSizes.paddingLarge * 2),

          // Title
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: Opacity(
                  opacity: _textAnimation.value,
                  child: Text(
                    widget.page.title,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSizes.padding),

          // Description
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: Opacity(
                  opacity: _textAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                    child: Text(
                      widget.page.description,
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.onBackground,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSizes.paddingLarge),

          // Feature bullets based on page
          AnimatedBuilder(
            animation: _textAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: Opacity(
                  opacity: _textAnimation.value,
                  child: _buildFeatureBullets(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBullets() {
    List<String> features = [];
    
    switch (widget.page.title) {
      case 'Track Your Investments':
        features = [
          'Real-time stock prices',
          'Personalized watchlists',
          'Market trends & analysis',
          'Portfolio performance tracking',
        ];
        break;
      case 'Get Smart Insights':
        features = [
          'AI-powered sentiment analysis',
          'Curated financial news',
          'Stock recommendations',
          'Market insights & alerts',
        ];
        break;
      case 'Invest Together':
        features = [
          'Create investment clubs',
          'Collaborative decision making',
          'Group portfolio management',
          'Social learning experience',
        ];
        break;
    }

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 20,
              color: widget.page.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                feature,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.onBackground,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
