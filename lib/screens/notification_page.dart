import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/notif_repository.dart';
import '../theme/app_theme.dart';
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
      NotifRepository.tandaiSemuaDibaca();
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: NotifRepository.stream(),
        builder: (context, snap) {
          final keadaan = keadaanStream<QuerySnapshot<Map<String, dynamic>>>(
            snap,
            onCoba: () => setState(() {}),
            kosong: (d) => d.docs.isEmpty,
            tampilanKosong: const EmptyView(
              icon: Icons.notifications_none_rounded,
              judul: 'Belum ada notifikasi',
              pesan: 'Pemberitahuan tentang pesananmu akan muncul di sini.',
            ),
          );
          if (keadaan != null) return keadaan;

          return ListView.separated(
            itemCount: snap.data!.docs.length,
            separatorBuilder: (_, _) => const Divider(
              height: 1,
              color: AppColors.divider,
              indent: 20,
              endIndent: 20,
            ),
            itemBuilder: (context, i) {
              final doc = snap.data!.docs[i];
              final data = doc.data();
              final waktu = (data['waktu'] as Timestamp?)?.toDate();
              final tglStr = waktu == null
                  ? ''
                  : DateFormat('d MMM, HH:mm', 'id_ID').format(waktu);
              final dibaca = data['dibaca'] as bool? ?? false;

              return Container(
                color: dibaca
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
                  title: Text(data['judul'] ?? '', style: ts(14, 700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(data['pesan'] ?? '', style: ts(13, 500)),
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
