import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DrawerHeaderWidget extends StatelessWidget {
  const DrawerHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120, // Adjust height as needed
      width: double.infinity,
      color: AppColors.sidebarCard, // Use theme color
      padding: const EdgeInsets.only(top: 40.0, left: 16.0, right: 16.0, bottom: 16.0),
      child: const Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          'QCUIckBot',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
