import 'package:flutter/material.dart';

import '../data/datasource/product_local_datasource.dart';

/// Holds light/dark mode and remembers the choice in Hive.
class ThemeProvider extends ChangeNotifier {
  final ProductLocalDataSource _local;
  bool _isDarkMode;

  ThemeProvider(this._local) : _isDarkMode = _local.getDarkMode();

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _local.saveDarkMode(_isDarkMode);
  }
}
