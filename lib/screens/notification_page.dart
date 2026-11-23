import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../viewmodels/notifikasi_view_model.dart';
import '../widgets/state_views.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Tandai semua sudah dibaca saat layar dibuka (titik merah hilang)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotifikasiViewModel>().tandaiSemuaDibaca();
    });
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
      // Langsung tampilkan daftar notifikasi
      body: Consumer<NotifikasiViewModel>(
        builder: (context, vm, _) {
          final snap = vm.keadaan;
          final keadaan = keadaanStream(
            snap,
            onCoba: vm.muatUlang,
            kosong: (d) => d.isEmpty,
            tampilanKosong: const EmptyView(
              icon: Icons.notifications_none_rounded,
              judul: 'Belum ada notifikasi',
              pesan: 'Pemberitahuan tentang pesananmu akan muncul di sini.',
            ),
          );
          if (keadaan != null) return keadaan;

          final daftar = snap.requireData;
          return ListView.separated(
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              color: AppColors.divider,
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, i) {
              final n = daftar[i];
              final waktu = n.waktu;
              final tglStr = waktu == null
                  ? ''
                  : DateFormat('d MMM, HH:mm', 'id_ID').format(waktu);

              return Container(
                color: n.dibaca
                    ? Colors.transparent
                    : AppColors.primary.withValues(alpha: 0.05),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.tint,
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(n.judul, style: ts(14, 700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(n.pesan, style: ts(13, 500)),
                      const SizedBox(height: 4),
                      Text(tglStr, style: ts(11, 500, color: AppColors.muted)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
