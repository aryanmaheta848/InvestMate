import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:invest_mate/constants/app_constants.dart';
import 'package:invest_mate/providers/auth_provider.dart';
import 'package:invest_mate/providers/stock_provider.dart';
import 'package:invest_mate/providers/portfolio_provider.dart';
import 'package:invest_mate/providers/club_provider.dart';
import 'package:invest_mate/screens/auth/splash_screen.dart';
import 'package:invest_mate/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const TickerTrackerApp());
}

class TickerTrackerApp extends StatelessWidget {
  const TickerTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => PortfolioProvider()),
        ChangeNotifierProvider(create: (_) => ClubProvider()),
      ],
      child: GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: MaterialColor(0xFF0F4C75, {
            50: const Color(0xFFE8F1F7),
            100: const Color(0xFFC6DDEC),
            200: const Color(0xFFA0C7E0),
            300: const Color(0xFF79B0D4),
            400: const Color(0xFF5C9FCA),
            500: const Color(0xFF3F8EC1),
            600: const Color(0xFF3986BB),
            700: const Color(0xFF317BB2),
            800: const Color(0xFF2971AA),
            900: const Color(0xFF0F4C75),
          }),
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.light(
            primary: AppColors.primary,
            primaryContainer: AppColors.primaryLight,
            secondary: AppColors.secondary,
            secondaryContainer: AppColors.accent,
            surface: AppColors.surface,
            surfaceContainerHighest: AppColors.surfaceVariant,
            error: AppColors.error,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: AppColors.onSurface,
            onError: Colors.white,
            brightness: Brightness.light,
            outline: AppColors.border,
            shadow: AppColors.shadow,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.onSurface,
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: AppTextStyles.heading3.copyWith(
              color: AppColors.onSurface,
            ),
            iconTheme: IconThemeData(color: AppColors.onSurface),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: AppSizes.elevationLow,
              shadowColor: AppColors.shadow,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingLarge,
                vertical: AppSizes.padding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              ),
              textStyle: AppTextStyles.button,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: AppSizes.elevationLow,
            shadowColor: AppColors.shadow,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              side: BorderSide(
                color: AppColors.borderLight,
                width: 0.5,
              ),
            ),
            color: AppColors.surface,
            margin: EdgeInsets.zero,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            fillColor: AppColors.surfaceVariant,
            filled: true,
            contentPadding: const EdgeInsets.all(AppSizes.padding),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.onBackground,
            type: BottomNavigationBarType.fixed,
            elevation: AppSizes.elevationHigh,
            selectedLabelStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: AppTextStyles.caption,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          primarySwatch: MaterialColor(0xFF1976D2, {
            50: const Color(0xFFE3F2FD),
            100: const Color(0xFFBBDEFB),
            200: const Color(0xFF90CAF9),
            300: const Color(0xFF64B5F6),
            400: const Color(0xFF42A5F5),
            500: const Color(0xFF1976D2),
            600: const Color(0xFF1E88E5),
            700: const Color(0xFF1976D2),
            800: const Color(0xFF1565C0),
            900: const Color(0xFF0D47A1),
          }),
          primaryColor: AppColors.primary,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: AppColors.darkBackground,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.darkSurface,
            foregroundColor: AppColors.darkOnSurface,
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            elevation: AppSizes.elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            ),
            color: AppColors.darkSurface,
          ),
          useMaterial3: true,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
