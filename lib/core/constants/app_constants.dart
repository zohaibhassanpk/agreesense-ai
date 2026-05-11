import '../extensions/responsive_extension.dart';

class AppConstants {
  // App Info
  static const String appName = 'AgriSenseAI';
  static const String appVersion = '1.0.0';

  // Default Screen Padding
  static double hPadding = 20.w;
  static double vPadding = 16.h;

  // Default Border Radius
  static double borderRadius = 15.r;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Timeouts
  static const int receiveTimeout = 30;
  static const int connectionTimeout = 30;
  static const Duration cacheExpiration = Duration(hours: 24);

  // Auth Token Lifetimes
  static const int accessTokenExpirySeconds = 21600;
  static const int refreshTokenExpiryDays = 7;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String timeFormat = 'hh:mm a';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
}
