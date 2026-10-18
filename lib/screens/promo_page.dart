import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/voucher.dart';
import '../models/voucher_rules.dart';
import '../services/user_repo.dart';
import '../services/voucher_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/voucher_card.dart';

// PromoPage: Promo & Voucher — semua voucher milik user beserta status berlakunya.
// Sumber: users/{uid}.voucher × vouchers/{kode} (realtime). Ketuk kartu = salin kode.
class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  // _muatUlang: bangun ulang StreamBuilder setelah error
  void _muatUlang() => setState(() {});

  String _tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

  // _catatan: ringkasan syarat/status untuk satu voucher
  String _catatan(Voucher v) {
    if (!v.aktif) return 'Tidak aktif.';
    if (v.kedaluwarsa()) return 'Sudah kedaluwarsa.';
    final bagian = <String>[
      if (v.minBelanja > 0) 'Min. belanja ${rp(v.minBelanja)}',
      if (v.berlakuSampai != null) 'Berlaku s.d. ${_tanggal(v.berlakuSampai!)}',
    ];
    return bagian.join(' · ');
  }

  Future<void> _salin(Voucher v) async {
    await Clipboard.setData(ClipboardData(text: v.kode));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Kode ${v.kode} disalin.')));
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
        title: Text('Promo & Voucher', style: ts(18, 800, ls: -0.3)),
      ),
      body: StreamBuilder(
        stream: UserRepo.stream(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting &&
              !userSnap.hasData) {
            return const LoadingView();
          }
          final kode = UserRepo.voucherDari(userSnap.data?.data());
          return StreamBuilder<List<Voucher>>(
            stream: VoucherRepository.streamKode(kode),
            builder: (context, snap) {
              final keadaan = keadaanStream<List<Voucher>>(
                snap,
                onCoba: _muatUlang,
                kosong: (d) => d.isEmpty,
                tampilanKosong: const EmptyView(
                  icon: Icons.sell_outlined,
                  judul: 'Belum ada voucher',
                  pesan: 'Voucher yang kamu dapat akan muncul di sini.',
                ),
              );
              if (keadaan != null) return keadaan;

              // Voucher yang masih berlaku di atas, yang tidak berlaku di bawah
              final daftar = [...snap.requireData]..sort((a, b) {
                  final ba = a.aktif && !a.kedaluwarsa() ? 0 : 1;
                  final bb = b.aktif && !b.kedaluwarsa() ? 0 : 1;
                  return ba.compareTo(bb);
                });

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: daftar.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final v = daftar[i];
                  final berlaku = v.aktif && !v.kedaluwarsa();
                  return KartuVoucherItem(
                    voucher: v,
                    catatan: _catatan(v),
                    onTap: berlaku ? () => _salin(v) : null,
                    trailing: berlaku
                        ? const Icon(Icons.copy_rounded,
                            size: 18, color: AppColors.muted)
                        : null,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}