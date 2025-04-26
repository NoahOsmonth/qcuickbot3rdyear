import 'package:flutter/material.dart';

class AppColors {
  // Sidebar and backgrounds
  static const Color sidebar = Color(0xFF282F39);
  static const Color sidebarCard = Color(0xFF36404B);
  static const Color sidebarCardActive = Color(0xFF4D5A6A);
  static const Color sidebarText = Color(0xFFE5E5E5);
  static const Color sidebarAccent = Color(0xFF4D5A6A);

  // Main area
  static const Color mainBackground = Color(0xFF181A20); // true dark background
  static const Color welcomeText = Color(0xFFFFFFFF);
  static const Color welcomeSubText = Color(0xFFEEEEEE);

  // Chat bubbles
  static const Color userBubble = Color(
    0xFF23272F,
  ); // slightly lighter dark for user
  static const Color botBubble = Color(0xFF282F39); // dark bubble for bot/other
  static const Color bubbleText = Color(0xFFE5E5E5); // light text for bubbles

  // Accent
  static const Color accentYellow = Color.fromARGB(255, 115, 168, 228);
  static const Color accentRed = Color(0xFFFF5A5F);
  static const Color accentBlue = Color.fromARGB(255, 46, 67, 114);

  // Removed gradients: using only plain bubble colors now.
  static const Color backgroundStart = sidebar;
  static const Color backgroundEnd = mainBackground;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.mainBackground,
      primaryColor: AppColors.accentBlue,
      cardColor: AppColors.sidebarCard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sidebar,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.accentYellow),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.userBubble,
        hintStyle: TextStyle(color: Colors.grey[400]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.accentYellow),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.accentYellow,
      ),
    );
  }

  static ThemeData get lightTheme {
    // For now, use darkTheme for both for consistency with screenshot
    return darkTheme;
  }
}
