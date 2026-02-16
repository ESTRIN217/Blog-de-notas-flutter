import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Use Dynamic Colors'),
                value: themeProvider.useDynamicColors,
                onChanged: (value) {
                  themeProvider.setUseDynamicColors(value);
                },
              ),
              const Divider(),
              const ListTile(
                title: Text('Theme Mode'),
              ),
            RadioGroup<ThemeMode>(
  groupValue: themeProvider.themeMode,
  onChanged: (value) {
    if (value != null) {
      themeProvider.setThemeMode(value);
    }
  },
  child: Column(
    children: [
      RadioListTile<ThemeMode>(
        title: const Text('System'),
        value: ThemeMode.system,
      ),
      RadioListTile<ThemeMode>(
        title: const Text('Light'),
        value: ThemeMode.light,
      ),
      RadioListTile<ThemeMode>(
        title: const Text('Dark'),
        value: ThemeMode.dark,
      ),
    ],
  ),
)

            ],
          );
        },
      ),
    );
  }
}
