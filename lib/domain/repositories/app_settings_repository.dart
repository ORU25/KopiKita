import 'package:flutter/material.dart';

/// AppSettingsRepository: KONTRAK pengaturan aplikasi (domain layer).
/// Dipakai ViewModel tanpa tahu implementasi (SharedPreferences/SQLite).
abstract class AppSettingsRepository {
  Stream<ThemeMode> themeModeStream();
  Stream<bool> defaultOrderMethodStream();
  Stream<bool> showOutOfStockStream();
  Stream<bool> useKilometerStream();

  Future<void> setThemeMode(ThemeMode mode);
  Future<void> setDefaultOrderMethod(bool makanDiTempat);
  Future<void> setShowOutOfStock(bool show);
  Future<void> setUseKilometer(bool useKm);

  ThemeMode getThemeMode();
  bool getDefaultOrderMethod();
  bool getShowOutOfStock();
  bool getUseKilometer();

  Future<void> resetToDefaults();

  static const Set<String> allKeys = {
    'theme_mode',
    'default_order_method',
    'show_out_of_stock',
    'use_kilometer',
  };
}