import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: const Color.fromARGB(255, 64, 140, 255)),
        ),
      ),
      body: Container(
        color: AppColors.mainBackground,
        child: Center(
          child: Text(
            'Settings Page',
            style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 64, 140, 255)),
          ),
        ),
      ),
    );
  }
}
