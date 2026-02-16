import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _useDynamicColors = true;
  ThemeMode _themeMode = ThemeMode.system;

  bool get useDynamicColors => _useDynamicColors;
  ThemeMode get themeMode => _themeMode;

  void setUseDynamicColors(bool value) {
    _useDynamicColors = value;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
