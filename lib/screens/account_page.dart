import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/voucher.dart'; // Ganti import dummy dengan model asli
import '../services/auth_service.dart';
import '../services/user_repo.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'notification_page.dart';

// AccountPage: layar Akun (DESIGN.md 3.8)
// Semua data user diambil langsung dari users/{uid} via StreamBuilder.
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> _keluar() => AuthService.keluar();

  Future<void> _sheetEditProfil(BuildContext context) async {
    // Ambil nilai sekarang untuk prefill.
    final data = await UserRepo.ambil();
    final ctrl = TextEditingController(text: UserRepo.namaDari(data));

    if (!context.mounted) return;
    final simpan = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit profil', style: ts(18, 800, ls: -0.3)),
            const SizedBox(height: 14),
            Text('Nama',
                style: ts(12, 700, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              style: ts(14, 500),
              decoration: const InputDecoration(hintText: 'Nama lengkap'),
              onSubmitted: (_) => Navigator.pop(ctx, true),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Simpan',
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );

    if (simpan != true) return;
    final nama = ctrl.text.trim();
    if (nama.length < 2) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Nama terlalu pendek.')),
        );
      return;
    }

    try {
      await UserRepo.update({'nama': nama});
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Profil diperbarui.')),
        );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: StreamBuilder(
        stream: UserRepo.stream(),
        builder: (context, snap) {
          final data = snap.data?.data();
          final nama = UserRepo.namaDari(data);
          final email = UserRepo.emailDari(data);
          final role = UserRepo.roleDari(data);
          final voucherKode = UserRepo.voucherDari(data);

          final namaTampil = nama.isEmpty ? 'Pengguna' : nama;
          final inisial = namaTampil.trim().isEmpty
              ? '?'
              : namaTampil.trim().substring(0, 1).toUpperCase();

          return ListView(
            padding: const EdgeInsets.fromLTRB(0, 24, 0, 170),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akun', style: ts(24, 800, ls: -0.4)),
                    const SizedBox(height: 16),
                    Material(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _sheetEditProfil(context),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.tint,
                                child: Text(
                                  inisial,
                                  style: ts(16, 800,
                                      color: AppColors.primary),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(namaTampil, style: ts(16, 800)),
                                    Text(
                                      email,
                                      style: ts(12, 500,
                                          color: AppColors.muted),
                                    ),
                                    if (role != 'pelanggan')
                                      Text(
                                        role == 'admin' ? 'Admin' : 'Staf',
                                        style: ts(12, 700,
                                            color: AppColors.primary),
                                      ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.ink,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Voucher saya', style: ts(16, 800)),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // --- PERBAIKAN: StreamBuilder untuk Voucher dari Firestore ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('vouchers').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(height: 76); // Loading state
                  }

                  // 1. Ambil semua voucher yang ada di sistem (Firestore)
                  final semuaVoucher = snapshot.data!.docs
                      .map((d) => Voucher.fromMap(d.id, d.data() as Map<String, dynamic>))
                      .toList();

                  // 2. Cocokkan dengan voucher milik user. 
                  // Jika voucher sudah dihapus dari sistem (tidak ada di semuaVoucher), otomatis dilewati.
                  final voucher = <Voucher>[];
                  for (final kode in voucherKode) {
                    final match = semuaVoucher.where((v) => v.kode == kode && v.aktif);
                    if (match.isNotEmpty) {
                      voucher.add(match.first);
                    }
                  }

                  // 3. Tampilkan
                  return SizedBox(
                    height: 76,
                    child: voucher.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Belum ada voucher.',
                              style: ts(13, 500, color: AppColors.muted),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: voucher.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 10),
                            itemBuilder: (context, i) => _KartuVoucher(voucher[i]),
                          ),
                  );
                },
              ),
              // -------------------------------------------------------------
              
              const SizedBox(height: 12),
              _barisPengaturan(
                'Edit profil',
                () => _sheetEditProfil(context),
              ),
              _barisPengaturan(
                'Notifikasi',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationPage()),
                ),
              ),
              _barisPengaturan('Keluar', _keluar),
            ],
          );
        },
      ),
    );
  }

  Widget _barisPengaturan(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: 52,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: ts(14, 600))),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// _KartuVoucher: kartu 200×76 radius 18, latar tint, border putus-putus caramel
class _KartuVoucher extends StatelessWidget {
  final Voucher v;
  const _KartuVoucher(this.v);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(),
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(v.kode, style: ts(14, 800, color: AppColors.primary)),
            Text(
              v.info,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ts(12, 500, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// _DashedBorderPainter: border 1.5 putus-putus caramel dengan radius 18
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.caramel
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(18),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}