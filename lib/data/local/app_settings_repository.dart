import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../domain/repositories/app_settings_repository.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  AppSettingsRepositoryImpl(this._prefs) {
    // Inisialisasi nilai awal dari cache
    _themeModeCtrl = StreamController<ThemeMode>.broadcast()
      ..add(getThemeMode());
    _defaultOrderMethodCtrl = StreamController<bool>.broadcast()
      ..add(getDefaultOrderMethod());
    _showOutOfStockCtrl = StreamController<bool>.broadcast()
      ..add(getShowOutOfStock());
    _useKilometerCtrl = StreamController<bool>.broadcast()
      ..add(getUseKilometer());
  }

  final SharedPreferencesWithCache _prefs;

  late final StreamController<ThemeMode> _themeModeCtrl;
  late final StreamController<bool> _defaultOrderMethodCtrl;
  late final StreamController<bool> _showOutOfStockCtrl;
  late final StreamController<bool> _useKilometerCtrl;

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDefaultOrderMethod = 'default_order_method';
  static const String _keyShowOutOfStock = 'show_out_of_stock';
  static const String _keyUseKilometer = 'use_kilometer';

  // ---- Sinkron (dari cache) ----

  @override
  ThemeMode getThemeMode() {
    final String? nama = _prefs.getString(_keyThemeMode);
    return ThemeMode.values.asNameMap()[nama] ?? ThemeMode.system;
  }

  @override
  bool getDefaultOrderMethod() =>
      _prefs.getBool(_keyDefaultOrderMethod) ?? false;

  @override
  bool getShowOutOfStock() => _prefs.getBool(_keyShowOutOfStock) ?? true;

  @override
  bool getUseKilometer() => _prefs.getBool(_keyUseKilometer) ?? true;

  // ---- Async (simpan ke perangkat) ----

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
    _themeModeCtrl.add(mode);
  }

  @override
  Future<void> setDefaultOrderMethod(bool makanDiTempat) async {
    await _prefs.setBool(_keyDefaultOrderMethod, makanDiTempat);
    _defaultOrderMethodCtrl.add(makanDiTempat);
  }

  @override
  Future<void> setShowOutOfStock(bool show) async {
    await _prefs.setBool(_keyShowOutOfStock, show);
    _showOutOfStockCtrl.add(show);
  }

  @override
  Future<void> setUseKilometer(bool useKm) async {
    await _prefs.setBool(_keyUseKilometer, useKm);
    _useKilometerCtrl.add(useKm);
  }

  @override
  Future<void> resetToDefaults() async {
    await Future.wait([
      _prefs.remove(_keyThemeMode),
      _prefs.remove(_keyDefaultOrderMethod),
      _prefs.remove(_keyShowOutOfStock),
      _prefs.remove(_keyUseKilometer),
    ]);
    // Pancarkan nilai default
    _themeModeCtrl.add(ThemeMode.system);
    _defaultOrderMethodCtrl.add(false);
    _showOutOfStockCtrl.add(true);
    _useKilometerCtrl.add(true);
  }

  // ---- Stream (benar-benar mendengarkan perubahan) ----

  @override
  Stream<ThemeMode> themeModeStream() => _themeModeCtrl.stream;

  @override
  Stream<bool> defaultOrderMethodStream() => _defaultOrderMethodCtrl.stream;

  @override
  Stream<bool> showOutOfStockStream() => _showOutOfStockCtrl.stream;

  @override
  Stream<bool> useKilometerStream() => _useKilometerCtrl.stream;

  void dispose() {
    _themeModeCtrl.close();
    _defaultOrderMethodCtrl.close();
    _showOutOfStockCtrl.close();
    _useKilometerCtrl.close();
  }
}