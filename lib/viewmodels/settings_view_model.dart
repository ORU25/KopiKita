import 'package:flutter/material.dart';

import '../domain/repositories/app_settings_repository.dart';
import 'stream_view_model.dart';

/// SettingsViewModel: mengelola pengaturan aplikasi (tema, metode pesan, dll.)
/// dan menyediakannya sebagai stream untuk UI.
class SettingsViewModel extends StreamViewModel<SettingsState> {
  SettingsViewModel(this._repo) {
    muatUlang();
  }

  final AppSettingsRepository _repo;

  @override
  Stream<SettingsState> buatStream() {
    return Stream.periodic(const Duration(milliseconds: 300)).asyncMap((_) async {
      return SettingsState(
        themeMode: _repo.getThemeMode(),
        defaultOrderMethod: _repo.getDefaultOrderMethod(),
        showOutOfStock: _repo.getShowOutOfStock(),
        useKilometer: _repo.getUseKilometer(),
      );
    });
  }

  SettingsState get state => data ?? SettingsState(
    themeMode: _repo.getThemeMode(),
    defaultOrderMethod: _repo.getDefaultOrderMethod(),
    showOutOfStock: _repo.getShowOutOfStock(),
    useKilometer: _repo.getUseKilometer(),
  );

  ThemeMode get themeMode => state.themeMode;
  bool get defaultOrderMethod => state.defaultOrderMethod;
  bool get showOutOfStock => state.showOutOfStock;
  bool get useKilometer => state.useKilometer;

  Future<String?> setThemeMode(ThemeMode mode) async {
    try {
      await _repo.setThemeMode(mode);
      muatUlang();
      return null;
    } catch (e) {
      return 'Gagal mengubah tema.';
    }
  }

  Future<String?> setDefaultOrderMethod(bool makanDiTempat) async {
    try {
      await _repo.setDefaultOrderMethod(makanDiTempat);
      muatUlang();
      return null;
    } catch (e) {
      return 'Gagal mengubah metode pesan default.';
    }
  }

  Future<String?> setShowOutOfStock(bool show) async {
    try {
      await _repo.setShowOutOfStock(show);
      muatUlang();
      return null;
    } catch (e) {
      return 'Gagal mengubah preferensi tampilan.';
    }
  }

  Future<String?> setUseKilometer(bool useKm) async {
    try {
      await _repo.setUseKilometer(useKm);
      muatUlang();
      return null;
    } catch (e) {
      return 'Gagal mengubah satuan jarak.';
    }
  }

  Future<void> resetToDefaults() async {
    await _repo.resetToDefaults();
    muatUlang();
  }
}

class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.defaultOrderMethod,
    required this.showOutOfStock,
    required this.useKilometer,
  });

  final ThemeMode themeMode;
  final bool defaultOrderMethod;
  final bool showOutOfStock;
  final bool useKilometer;
}