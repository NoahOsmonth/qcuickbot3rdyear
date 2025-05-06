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

  // --- Light Theme Colors ---
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

  static const Color lightAccentYellow = Color.fromARGB(255, 64, 140, 255); // Example: Using a blue for light theme accent
  static const Color lightAccentRed = Color(0xFFBF616A);
  static const Color lightAccentBlue = Color(0xFF5E81AC);
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
    // Define light theme based on new colors
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightMainBackground,
      primaryColor: AppColors.lightAccentBlue, // Use a light theme primary color
      primarySwatch: Colors.blue, // Provide a swatch for Material components
      cardColor: AppColors.lightSidebarCard,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightSidebar, // Light app bar
        elevation: 1, // Add slight elevation for light theme
        iconTheme: IconThemeData(color: AppColors.lightAccentBlue), // Use a suitable icon color
        titleTextStyle: TextStyle(
          color: AppColors.lightSidebarText, // Darker text for light app bar
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightUserBubble, // Light input background
        hintStyle: TextStyle(color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.lightSidebarAccent), // Add a subtle border
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.lightSidebarAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.lightAccentBlue, width: 2.0), // Highlight focus
        ),
      ),
      iconTheme: IconThemeData(color: AppColors.lightAccentBlue), // Default icon color
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightAccentBlue,
      ),
      // Define text themes if needed for better contrast
      textTheme: const TextTheme(
         bodyLarge: TextStyle(color: AppColors.lightSidebarText),
         bodyMedium: TextStyle(color: AppColors.lightSidebarText),
         // Add other text styles as needed
      ),
      // Define button themes if needed
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccentBlue, // Button background
          foregroundColor: Colors.white, // Button text color
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.lightAccentBlue, // Color for icons in ListTiles
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: AppColors.lightSidebar, // Drawer background
      ),
      // Add other theme properties as needed
    );
  }
}
