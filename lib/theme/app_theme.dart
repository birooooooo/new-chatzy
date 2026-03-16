import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure Black & Glass - "iOS 26" Style
  static const Color primaryDark = Color(0xFF000000);  // Pure Black
  static const Color primary = Color(0xFF000000);       // Pure Black
  static const Color primaryLight = Color(0xFF1C1C1E);  // Dark Gray for contrast if needed
  
  // Secondary / Accent Colors
  static const Color secondary = Color(0xFF2997FF);     // Vivid iOS Blue (Electric)
  static const Color secondaryLight = Color(0xFF64D2FF); // Light Blue
  static const Color accent = Color(0xFFBF5AF2);        // Vibrant Purple
  static const Color accentAlt = Color(0xFFFF375F);     // Vibrant Red/Pink
  
  // Neutral Colors
  static const Color background = Color(0xFF000000);    // Pure Black
  static const Color surface = Colors.transparent;      // Glass usually
  static const Color surfaceGlass = Color(0x1AFFFFFF);  // White with low opacity (10%)
  
  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFEBEBF5); // iOS Light Gray (60%)
  static const Color textLight = Color(0xFF8E8E93);     // iOS Gray
  
  // Status Colors
  static const Color success = Color(0xFF30D158);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF0A84FF);
  
  // Online Status
  static const Color online = Color(0xFF30D158);
  static const Color offline = Color(0xFF8E8E93);
  static const Color away = Color(0xFFFF9F0A);
  
  // Chat Bubble Colors
  static const Color myMessageBubble = Color(0xFF0A84FF);
  static const Color partnerMessageBubble = Color(0xFF262626); // Dark Gray

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A84FF), Color(0xFF5E5CE6)], // Blue to Purple
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)], // 15% to 5% White
  );

  static const LinearGradient liquidGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF818CF8), // Indigo
      Color(0xFF94A3B8), // Sage
      Color(0xFFFCD34D), // Gold
    ],
  );

  // Shadows needed for depth on black
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.5),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  // Legacy/Alias Support for older screens not yet refactored
  static const LinearGradient blueGradient = primaryGradient;
  static List<BoxShadow> cardShadow = softShadow;

  // Border Radius
  static BorderRadius borderRadiusSmall = BorderRadius.circular(12);
  static BorderRadius borderRadiusMedium = BorderRadius.circular(20);
  static BorderRadius borderRadiusLarge = BorderRadius.circular(32);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: secondary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      
      colorScheme: const ColorScheme.dark(
        primary: secondary,
        secondary: accent,
        surface: background,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      
      textTheme: TextTheme(
        bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: textPrimary),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal, color: textSecondary),
        bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.normal, color: textLight),
        displaySmall: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        labelLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
      ),
    );
  }

  // Light text colors for the white theme
  static const Color lightTextPrimary   = Color(0xFF1C1C1E);   // Near black
  static const Color lightTextSecondary = Color(0xFF3A3A3C);   // Dark gray
  static const Color lightTextLight     = Color(0xFF6E6E73);   // Medium gray

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: secondary,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      canvasColor: const Color(0xFFFFFFFF),

      colorScheme: const ColorScheme.light(
        primary: secondary,
        secondary: accent,
        surface: Color(0xFFF2F2F7),
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: lightTextPrimary),
      ),

      textTheme: TextTheme(
        bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: lightTextPrimary),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal, color: lightTextSecondary),
        bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.normal, color: lightTextLight),
        displaySmall: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
        headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: lightTextPrimary),
        labelLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: lightTextPrimary),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: lightTextPrimary,
        textColor: lightTextPrimary,
      ),

      iconTheme: const IconThemeData(color: lightTextPrimary),

      dividerColor: Color(0xFFD1D1D6),
    );
  }
}

// Screen Size Helper for Responsive Design
class ScreenSize {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double blockSizeHorizontal;
  static late double blockSizeVertical;
  static late double safeAreaHorizontal;
  static late double safeAreaVertical;
  static late double safeBlockHorizontal;
  static late double safeBlockVertical;
  static late bool isMobile;
  static late bool isTablet;
  static late bool isDesktop;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
    
    safeAreaHorizontal = _mediaQueryData.padding.left + _mediaQueryData.padding.right;
    safeAreaVertical = _mediaQueryData.padding.top + _mediaQueryData.padding.bottom;
    safeBlockHorizontal = (screenWidth - safeAreaHorizontal) / 100;
    safeBlockVertical = (screenHeight - safeAreaVertical) / 100;
    
    isMobile = screenWidth < 600;
    isTablet = screenWidth >= 600 && screenWidth < 1024;
    isDesktop = screenWidth >= 1024;
  }
  
  static double getResponsiveWidth(double percentage) {
    return screenWidth * (percentage / 100);
  }
  
  static double getResponsiveHeight(double percentage) {
    return screenHeight * (percentage / 100);
  }
  
  static double getResponsiveFontSize(double size) {
    if (isMobile) return size;
    if (isTablet) return size * 1.2;
    return size * 1.4;
  }
}
