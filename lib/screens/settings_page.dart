import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/settings_view_model.dart';
import '../theme/app_theme.dart';

/// SettingsPage: halaman pengaturan aplikasi (tema, metode pesan, dll.)
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Pengaturan', style: ts(18, 800, ls: -0.3)),
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, vm, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(judul: 'Tampilan'),
            _ThemeTile(vm: vm),
            const Divider(height: 24),
            _SectionHeader(judul: 'Pesan'),
            _Tile(
              ikon: Icons.shopping_bag_outlined,
              judul: 'Metode pesan default',
              subtitle: vm.defaultOrderMethod ? 'Makan di Tempat' : 'Ambil Sendiri',
              trailing: Switch(
                value: vm.defaultOrderMethod,
                onChanged: (v) => vm.setDefaultOrderMethod(v),
              ),
            ),
            _Tile(
              ikon: Icons.visibility_outlined,
              judul: 'Tampilkan menu habis',
              subtitle: 'Sembunyikan item yang stoknya habis',
              trailing: Switch(
                value: vm.showOutOfStock,
                onChanged: (v) => vm.setShowOutOfStock(v),
              ),
            ),
            const Divider(height: 24),
            _SectionHeader(judul: 'Umum'),
            _Tile(
              ikon: Icons.straighten_rounded,
              judul: 'Satuan jarak',
              subtitle: vm.useKilometer ? 'Kilometer (km)' : 'Meter (m)',
              trailing: Switch(
                value: vm.useKilometer,
                onChanged: (v) => vm.setUseKilometer(v),
              ),
            ),
            const Divider(height: 24),
            _Tile(
              ikon: Icons.restore_rounded,
              judul: 'Reset ke default',
              subtitle: 'Kembalikan semua pengaturan ke bawaan',
              trailing: TextButton(
                onPressed: () => _confirmReset(context, vm),
                child: Text('Reset', style: ts(14, 700, color: AppColors.danger)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset pengaturan?'),
        content: Text('Semua pengaturan akan kembali ke bawaan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          FilledButton(
            onPressed: () {
              vm.resetToDefaults();
              Navigator.pop(context);
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String judul;
  const _SectionHeader({required this.judul});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(judul, style: ts(12, 800, color: AppColors.muted, ls: 0.5)),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final String subtitle;
  final Widget trailing;

  const _Tile({
    required this.ikon,
    required this.judul,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(ikon, color: AppColors.primary, size: 24),
      title: Text(judul, style: ts(16, 700)),
      subtitle: Text(subtitle, style: ts(13, 500, color: AppColors.muted)),
      trailing: trailing,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final SettingsViewModel vm;
  const _ThemeTile({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.brightness_6_rounded, color: AppColors.primary, size: 24),
      title: Text('Tema', style: ts(16, 700)),
      subtitle: Text(_themeLabel(vm.themeMode), style: ts(13, 500, color: AppColors.muted)),
      trailing: _ThemeChips(vm: vm),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'Terang',
    ThemeMode.dark => 'Gelap',
    ThemeMode.system => 'Ikuti sistem',
  };
}

class _ThemeChips extends StatelessWidget {
  final SettingsViewModel vm;
  const _ThemeChips({required this.vm});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 6,
        runSpacing: 6,
        children: [
          _ThemeChip(label: 'Sistem', mode: ThemeMode.system, vm: vm),
          _ThemeChip(label: 'Terang', mode: ThemeMode.light, vm: vm),
          _ThemeChip(label: 'Gelap', mode: ThemeMode.dark, vm: vm),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final SettingsViewModel vm;

  const _ThemeChip({required this.label, required this.mode, required this.vm});

  @override
  Widget build(BuildContext context) {
    final dipilih = vm.themeMode == mode;
    return ChoiceChip(
      label: Text(label, style: ts(12, 700)),
      selected: dipilih,
      onSelected: (_) => vm.setThemeMode(mode),
      selectedColor: AppColors.tint,
      labelStyle: ts(12, 700, color: dipilih ? AppColors.ink : AppColors.textSecondary),
      side: BorderSide(color: dipilih ? AppColors.primary : AppColors.dividerList),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}