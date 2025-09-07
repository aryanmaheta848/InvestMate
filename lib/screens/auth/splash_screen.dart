import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/screens/auth/login_screen.dart';
import 'package:invest_mate/screens/home/main_screen.dart';
import 'package:invest_mate/screens/onboarding/onboarding_screen.dart';
import 'package:invest_mate/services/firebase/firebase_service.dart';
import 'dart:math' as math;
import 'dart:ui';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _rotationController;
  late Animation<double> _logoScale;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startSplashSequence();
  }

  void _initializeAnimations() {
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  void _startSplashSequence() async {
    // Use a safer approach with mounted checks
    if (!mounted) return;
    
    // Initialize Firebase services
    await _initializeServices();
    if (!mounted) return;
    
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _logoController.forward();
    
    // Start rotation animation
    _rotationController.repeat();
    
    // Start fade animation
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _fadeController.forward();
    
    // Wait for animations to complete
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // Check authentication state and navigate
    _checkAuthAndNavigate();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize Firebase messaging
      await FirebaseService().initializeMessaging();
      
      // Initialize portfolio provider with default data
      final portfolioProvider = Provider.of<PortfolioProvider>(context, listen: false);
      await portfolioProvider.initializeDefaultPortfolio();
      
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  void _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Check if onboarding is completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    // Listen to auth state changes
    switch (authProvider.state) {
      case AuthState.authenticated:
        // Use Navigator instead of Get for more reliable navigation
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
        break;
      case AuthState.unauthenticated:
        if (mounted) {
          if (onboardingCompleted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        }
        break;
      case AuthState.initial:
      case AuthState.loading:
        // Wait for auth state to be determined
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _checkAuthAndNavigate();
          }
        });
        break;
      case AuthState.error:
        if (mounted) {
          if (onboardingCompleted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        }
        break;
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple animated logo
            AnimatedBuilder(
              animation: _logoScale,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // App name
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Text(
                    AppConstants.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 10),
            
            // Subtitle
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const Text(
                    'Smart Investment Trading',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 50),
            
            // Simple loading indicator
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
