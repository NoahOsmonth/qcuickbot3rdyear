import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: AppColors.accentYellow),
        ),
      ),
      body: Container(
        color: AppColors.mainBackground,
        child: Center(
          child: Text(
            'Settings Page',
            style: TextStyle(fontSize: 18, color: AppColors.accentYellow),
          ),
        ),
      ),
    );
  }
}
