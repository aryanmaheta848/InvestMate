import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class Utils {
  // Private constructor to prevent instantiation
  Utils._();

  // Format currency values
  static String formatCurrency(double value, {String symbol = '₹', int decimalPlaces = 2}) {
    if (value.abs() >= 1e12) {
      return '$symbol${(value / 1e12).toStringAsFixed(2)}T';
    } else if (value.abs() >= 1e9) {
      return '$symbol${(value / 1e9).toStringAsFixed(2)}B';
    } else if (value.abs() >= 1e7) {
      return '$symbol${(value / 1e7).toStringAsFixed(2)}Cr';
    } else if (value.abs() >= 1e5) {
      return '$symbol${(value / 1e5).toStringAsFixed(2)}L';
    } else if (value.abs() >= 1000) {
      return '$symbol${(value / 1000).toStringAsFixed(2)}K';
    } else {
      return '$symbol${value.toStringAsFixed(decimalPlaces)}';
    }
  }

  // Format percentage values
  static String formatPercentage(double value, {int decimalPlaces = 2, bool showSign = true}) {
    String sign = '';
    if (showSign) {
      sign = value >= 0 ? '+' : '';
    }
    return '$sign${value.toStringAsFixed(decimalPlaces)}%';
  }

  // Format volume values
  static String formatVolume(int volume) {
    if (volume >= 1e7) {
      return '${(volume / 1e7).toStringAsFixed(1)}Cr';
    } else if (volume >= 1e5) {
      return '${(volume / 1e5).toStringAsFixed(1)}L';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(1)}K';
    } else {
      return volume.toString();
    }
  }

  // Format date and time
  static String formatDateTime(DateTime dateTime, {String format = 'MMM dd, yyyy HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  // Format date only
  static String formatDate(DateTime dateTime, {String format = 'MMM dd, yyyy'}) {
    return DateFormat(format).format(dateTime);
  }

  // Format time only
  static String formatTime(DateTime dateTime, {String format = 'HH:mm'}) {
    return DateFormat(format).format(dateTime);
  }

  // Get time ago string
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Validate email
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validate password
  static bool isValidPassword(String password) {
    // At least 6 characters, contains letters and numbers
    return password.length >= 6 && RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(password);
  }

  // Get color for price change
  static Color getPriceChangeColor(double change) {
    if (change > 0) {
      return const Color(0xFF4CAF50); // Green
    } else if (change < 0) {
      return const Color(0xFFF44336); // Red
    } else {
      return const Color(0xFF9E9E9E); // Grey
    }
  }

  // Get icon for price change
  static IconData getPriceChangeIcon(double change) {
    if (change > 0) {
      return Icons.arrow_upward;
    } else if (change < 0) {
      return Icons.arrow_downward;
    } else {
      return Icons.remove;
    }
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // Generate random color based on string
  static Color generateColor(String text) {
    int hash = text.hashCode;
    return Color((hash & 0xFFFFFF) | 0xFF000000);
  }

  // Get initials from name
  static String getInitials(String name) {
    List<String> names = name.trim().split(' ');
    String initials = '';
    int count = 0;
    for (String name in names) {
      if (count < 2 && name.isNotEmpty) {
        initials += name[0].toUpperCase();
        count++;
      }
    }
    return initials;
  }

  // Show snackbar
  static void showSnackbar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        action: action,
      ),
    );
  }

  // Show success snackbar
  static void showSuccessSnackbar(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: const Color(0xFF4CAF50),
    );
  }

  // Show error snackbar
  static void showErrorSnackbar(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: const Color(0xFFF44336),
    );
  }

  // Show warning snackbar
  static void showWarningSnackbar(BuildContext context, String message) {
    showSnackbar(
      context,
      message,
      backgroundColor: const Color(0xFFFF9800),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Loading...'),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message, {
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  // Parse double safely
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Parse int safely
  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  // Launch URL
  static Future<void> launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // Get file size string
  static String getFileSizeString(int bytes, {int decimals = 2}) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    if (bytes == 0) return '0 B';
    int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // Generate UUID (simple version)
  static String generateUUID() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000000 + Random().nextInt(9000000)).toString();
  }

  // Check if dark mode is enabled
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) {
      return desktop ?? tablet ?? mobile;
    } else if (screenWidth >= 600) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Check if device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1200;
  }

  // Check if device is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1200;
  }
}
