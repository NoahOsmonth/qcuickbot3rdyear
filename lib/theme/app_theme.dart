import 'package:flutter/material.dart';

class AppColors {
  // --- Shared Colors ---
  static const Color primaryBlue = Color(0xFF0D69FF); // Main blue from images
  static const Color lightText = Color(0xFFFFFFFF);
  static const Color darkText = Color(0xFF1D1D1F); // Slightly off-black for light theme text

  // --- Dark Theme Colors ---
  static const Color darkBackground = Color(0xFF181A20); // Dark background
  static const Color darkSurface = Color(0xFF282F39); // Slightly lighter surface (e.g., input fields)
  static const Color darkMutedText = Color(0xFFAAAAAA); // For hints or less important text

  // --- Light Theme Colors ---
  static const Color lightBackground = Color(0xFFF0F2F5); // Light background
  static const Color lightSurface = Color(0xFFFFFFFF); // White surface (e.g., input fields)
  static const Color lightMutedText = Color(0xFF6E6E73); // For hints or less important text
  static const Color lightBorder = Color(0xFFD2D2D7); // Subtle border for light inputs

  // --- Kept from original for potential use elsewhere ---
  static const Color sidebar = Color(0xFF282F39);
  static const Color sidebarCard = Color(0xFF36404B);
  static const Color sidebarCardActive = Color(0xFF4D5A6A);
  static const Color sidebarText = Color(0xFFE5E5E5);
  static const Color sidebarAccent = Color(0xFF4D5A6A);
  static const Color mainBackground = Color(0xFF181A20);
  static const Color welcomeText = Color(0xFFFFFFFF);
  static const Color welcomeSubText = Color(0xFFEEEEEE);
  static const Color userBubble = Color(0xFF23272F);
  static const Color botBubble = Color(0xFF282F39);
  static const Color bubbleText = Color(0xFFE5E5E5);
  static const Color accentYellow = Color.fromARGB(255, 115, 168, 228); // Kept original accent
  static const Color accentRed = Color(0xFFFF5A5F);
  static const Color accentBlue = Color.fromARGB(255, 46, 67, 114); // Kept original accent
  static const Color backgroundStart = sidebar;
  static const Color backgroundEnd = mainBackground;
  static const Color lightSidebar = Color(0xFFF0F2F5);
  static const Color lightSidebarCard = Color(0xFFFFFFFF);
  static const Color lightSidebarCardActive = Color(0xFFE5E9F0);
  static const Color lightSidebarText = Color(0xFF333333);
  static const Color lightSidebarAccent = Color(0xFFD8DEE9);
  static const Color lightMainBackground = Color(0xFFE5E9F0);
  static const Color lightWelcomeText = Color(0xFF2E3440);
  static const Color lightWelcomeSubText = Color(0xFF4C566A);
  static const Color lightUserBubble = Color(0xFFD8DEE9);
  static const Color lightBotBubble = Color(0xFFFFFFFF);
  static const Color lightBubbleText = Color(0xFF2E3440);
  static const Color lightAccentYellow = Color.fromARGB(255, 64, 140, 255);
  static const Color lightAccentRed = Color(0xFFBF616A);
  static const Color lightAccentBlue = Color(0xFF5E81AC);
}

class AppTheme {
  static const double _borderRadius = 12.0; // Consistent border radius

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue, // Can adjust if needed
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.lightText,
        onSecondary: AppColors.lightText,
        onBackground: AppColors.lightText,
        onSurface: AppColors.lightText,
        error: AppColors.accentRed,
        onError: AppColors.lightText,
      ),
      appBarTheme: AppBarTheme( // Keep app bar theme consistent if used elsewhere
        backgroundColor: AppColors.darkSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.lightText),
        titleTextStyle: const TextStyle(
          color: AppColors.lightText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        hintStyle: const TextStyle(color: AppColors.darkMutedText),
        labelStyle: const TextStyle(color: AppColors.darkMutedText), // Style for floating label
        floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue), // Style when focused
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.lightText,
          minimumSize: const Size(double.infinity, 54), // Full width, fixed height
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          elevation: 0, // Flat design
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkMutedText), // Default icon color
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.primaryBlue,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryBlue,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        onPrimary: AppColors.lightText,
        onSecondary: AppColors.lightText,
        onBackground: AppColors.darkText,
        onSurface: AppColors.darkText,
        error: AppColors.accentRed,
        onError: AppColors.lightText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.darkText),
        titleTextStyle: const TextStyle(
          color: AppColors.darkText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        hintStyle: const TextStyle(color: AppColors.lightMutedText),
        labelStyle: const TextStyle(color: AppColors.lightMutedText),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue),
        contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 20.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
         errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_borderRadius),
          borderSide: const BorderSide(color: AppColors.accentRed, width: 1.5),
        ),
      ),
       elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.lightText,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
           elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightMutedText),
      visualDensity: VisualDensity.adaptivePlatformDensity,
       // Define text themes if needed for better contrast
      textTheme: const TextTheme(
         bodyLarge: TextStyle(color: AppColors.darkText), // Default body text
         bodyMedium: TextStyle(color: AppColors.darkText),
         headlineMedium: TextStyle( // For titles like "Welcome to"
            color: AppColors.darkText,
            fontWeight: FontWeight.bold,
            fontSize: 28,
         ),
         headlineSmall: TextStyle( // For titles like "QCUICKBOT!"
            color: AppColors.primaryBlue, // Default to blue, override where needed
            fontWeight: FontWeight.bold,
            fontSize: 28,
         ),
         labelLarge: TextStyle( // For button text
            color: AppColors.lightText,
            fontWeight: FontWeight.w600,
            fontSize: 16,
         ),
         bodySmall: TextStyle( // For small text like "Doesn't have an account?"
            color: AppColors.lightMutedText,
            fontSize: 14,
         ),
         // Add other text styles as needed
      ).apply( // Ensure body color applies correctly in light theme
        bodyColor: AppColors.darkText,
        displayColor: AppColors.darkText,
      ),
    );
  }
}
