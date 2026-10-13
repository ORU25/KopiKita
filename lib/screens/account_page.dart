import 'package:flutter/material.dart';

import '../data/dummy_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'login_page.dart';

// AccountPage: layar Akun (DESIGN.md 3.8)
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // _keluar: kembali ke Login dan hapus semua halaman sebelumnya
  void _keluar(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // SafeArea + ListView: konten bisa di-scroll
    return SafeArea(
      bottom: false,
      child: ListView(
        // Padding horizontal 0: baris pengaturan selebar layar agar
        // highlight InkWell tidak mepet konten; isi lain diberi padding 20 sendiri
        padding: const EdgeInsets.fromLTRB(0, 24, 0, 170),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Akun', style: ts(24, 800, ls: -0.4)),
                const SizedBox(height: 16),

                // Card profil: avatar inisial · nama · email · chevron
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => segeraHadir(context, 'Edit profil'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // CircleAvatar: inisial 48 latar tint
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppColors.tint,
                            child: Text(
                              'R',
                              style: ts(16, 800, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rina', style: ts(16, 800)),
                                Text(
                                  'rina@email.com',
                                  style: ts(12, 500, color: AppColors.muted),
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

                // Voucher saya: daftar horizontal kartu 200×76
                Text('Voucher saya', style: ts(16, 800)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: voucherSaya.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _KartuVoucher(voucherSaya[i]),
            ),
          ),
          const SizedBox(height: 12),

          // Baris pengaturan datar
          _barisPengaturan(
            'Edit profil',
            () => segeraHadir(context, 'Edit profil'),
          ),
          _barisPengaturan(
            'Notifikasi',
            () => segeraHadir(context, 'Notifikasi'),
          ),
          _barisPengaturan('Keluar', () => _keluar(context)),
        ],
      ),
    );
  }

  // _barisPengaturan: baris 52 tinggi, 14/600, chevron muted, garis bawah divider
  Widget _barisPengaturan(String label, VoidCallback onTap) {
    // InkWell selebar layar, padding 20 di dalam: konten & garis tetap inset 20
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
  final Voucher v; // Data voucher
  const _KartuVoucher(this.v);

  @override
  Widget build(BuildContext context) {
    // CustomPaint: menggambar border putus-putus (Flutter tidak punya dashed border bawaan)
    return CustomPaint(
      foregroundPainter: _DashedBorderPainter(), // Digambar di atas latar tint
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
    // Path: persegi bulat seukuran kartu (digeser 0.75 agar garis tidak terpotong)
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
          const Radius.circular(18),
        ),
      );
    // computeMetrics: potong path menjadi segmen 5 px dengan jeda 4 px
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
