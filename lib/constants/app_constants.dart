import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'TickerTracker';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseApiUrl = 'https://api.kite.trade';
  static const String newsApiUrl = 'https://newsapi.org/v2';
  static const String yahooFinanceUrl = 'https://query1.finance.yahoo.com/v8/finance/chart';
  
  // Alpha Vantage API Configuration
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';
  static const String alphaVantageQuoteKey = 'O1K93M1NMHZUGREK';
  static const String alphaVantageDailyKey = 'RKZXNABF2IAFF4F8';
  static const String alphaVantageSmaKey = 'TBXS8NCE0OYT1PTC';
  static const String alphaVantageNewsKey = 'XEFIINM1A52PLDXE';
  
  // Paper Trading
  static const double initialBalance = 1000000.0; // ₹10,00,000
  static const double minTradeAmount = 1000.0;
  static const int maxWatchlistItems = 50;
  
  // Club Settings
  static const int maxClubMembers = 50;
  static const int votingTimeoutHours = 24;
  static const double minVotePercentage = 60.0; // 60% majority
  
  // Popular Indian Stocks
  static const List<String> popularStocks = [
    'RELIANCE.NS',
    'TCS.NS',
    'HDFCBANK.NS',
    'INFY.NS',
    'HINDUNILVR.NS',
    'ICICIBANK.NS',
    'KOTAKBANK.NS',
    'BHARTIARTL.NS',
    'ITC.NS',
    'SBIN.NS',
    'LT.NS',
    'ASIANPAINT.NS',
    'MARUTI.NS',
    'AXISBANK.NS',
    'WIPRO.NS',
    'ULTRACEMCO.NS',
    'TITAN.NS',
    'NESTLEIND.NS',
    'POWERGRID.NS',
    'NTPC.NS',
    'ZOMATO.NS',
    'PAYTM.NS',
    'NYKAA.NS',
    'POLICYBZR.NS',
  ];
}

class AppColors {
  // Modern Primary Colors - Professional Blue-Green palette
  static const Color primary = Color(0xFF0F4C75); // Deep professional blue
  static const Color primaryLight = Color(0xFF3282B8); // Lighter blue
  static const Color primaryDark = Color(0xFF0B3A5D); // Darker blue
  static const Color secondary = Color(0xFF1BAA6B); // Modern green
  static const Color accent = Color(0xFFFFE066); // Warm accent
  
  // Status Colors
  static const Color success = Color(0xFF10B981); // Modern green
  static const Color error = Color(0xFFEF4444); // Modern red
  static const Color warning = Color(0xFFF59E0B); // Modern amber
  static const Color info = Color(0xFF3B82F6); // Modern blue
  
  // Light Theme Background Colors
  static const Color background = Color(0xFFFAFAFA); // Very light gray
  static const Color surface = Color(0xFFFFFFFF); // Pure white
  static const Color surfaceVariant = Color(0xFFF8F9FA); // Slightly off-white
  static const Color onSurface = Color(0xFF1F2937); // Dark gray text
  static const Color onBackground = Color(0xFF6B7280); // Medium gray text
  
  // Additional Light Theme Colors
  static const Color border = Color(0xFFE5E7EB); // Light border
  static const Color borderLight = Color(0xFFF3F4F6); // Very light border
  static const Color shadow = Color(0x1A000000); // Subtle shadow
  static const Color overlay = Color(0x80000000); // Modal overlay
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF8FAFC);
  static const Color darkOnBackground = Color(0xFFCBD5E1);
  
  // Trading Colors - Modern Finance App Colors
  static const Color bullish = Color(0xFF10B981); // Modern green
  static const Color bearish = Color(0xFFEF4444); // Modern red
  static const Color neutral = Color(0xFF8B5CF6); // Modern purple for neutral
  
  // Sentiment Colors
  static const Color sentimentPositive = Color(0xFF10B981);
  static const Color sentimentNegative = Color(0xFFEF4444);
  static const Color sentimentNeutral = Color(0xFFF59E0B);
  
  // Gradient Colors for Modern UI
  static const Color gradientStart = Color(0xFF0F4C75);
  static const Color gradientEnd = Color(0xFF3282B8);
  static const Color accentGradientStart = Color(0xFF1BAA6B);
  static const Color accentGradientEnd = Color(0xFF16A085);
}

class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.onSurface,
  );
  
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  
  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );
  
  static const TextStyle body1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.onSurface,
  );
  
  static const TextStyle body2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.onBackground,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.onBackground,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  // Price Text Styles
  static const TextStyle pricePositive = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.bullish,
  );
  
  static const TextStyle priceNegative = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.bearish,
  );
  
  static const TextStyle priceNeutral = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.neutral,
  );
}

class AppSizes {
  static const double padding = 16.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  static const double borderRadius = 12.0;
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  static const double elevation = 4.0;
  static const double elevationLow = 2.0;
  static const double elevationHigh = 8.0;
  
  static const double iconSize = 24.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeLarge = 32.0;
}

class AppDurations {
  static const Duration animationShort = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 400);
  static const Duration animationLong = Duration(milliseconds: 600);
  
  // Real-time stock data intervals
  static const Duration refreshInterval = Duration(seconds: 5); // More frequent updates
  static const Duration fastRefreshInterval = Duration(seconds: 2); // For active trading
  static const Duration slowRefreshInterval = Duration(seconds: 30); // For background updates
  static const Duration apiTimeout = Duration(seconds: 10);
  
  // Market hours specific intervals
  static const Duration marketHoursInterval = Duration(seconds: 2);
  static const Duration afterHoursInterval = Duration(seconds: 60);
}
