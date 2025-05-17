import 'package:flutter/material.dart';

class DrawerHeaderWidget extends StatelessWidget {
  const DrawerHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get the current theme

    return Container(
      height: 120, // Adjust height as needed
      width: double.infinity,
      // Use theme color for the drawer header background
      color: theme.drawerTheme.backgroundColor ?? theme.cardColor,
      padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          'QCUIckBot',
          // Use theme color for the text
          style: TextStyle(
            color: theme.textTheme.titleLarge?.color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
