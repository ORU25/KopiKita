import 'package:flutter/material.dart';

import '../services/user_repo.dart';
import '../theme/app_theme.dart';

// NotificationPage: preferensi notifikasi status pesanan (DESIGN.md 3.8, bagian 5)
// Tulis langsung ke users/{uid}.notifikasi via UserRepo.update.
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _aktif = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final data = await UserRepo.ambil();
    if (!mounted) return;
    setState(() {
      _aktif = UserRepo.notifikasiDari(data);
      _loading = false;
    });
  }

  Future<void> _ubah(bool v) async {
    setState(() => _aktif = v); // Optimistic: UI langsung berubah
    try {
      await UserRepo.update({'notifikasi': v});
    } catch (e) {
      if (!mounted) return;
      setState(() => _aktif = !v); // Rollback bila gagal
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Notifikasi', style: ts(18, 800, ls: -0.3)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                SwitchListTile(
                  value: _aktif,
                  onChanged: _ubah,
                  activeThumbColor: AppColors.primary,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  title: Text('Notifikasi pesanan', style: ts(14, 700)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Dapatkan pemberitahuan saat status pesananmu berubah.',
                      style: ts(12, 500, color: AppColors.muted),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}