import 'package:flutter/material.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.settings_outlined),
      title: const Text('Settings'),
      onTap: () {
        Navigator.pop(context); // Close drawer first
        Navigator.pushNamed(context, '/settings');
      },
    );
  }
}
