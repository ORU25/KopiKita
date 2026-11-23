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

// bukaVoucherSaya: sheet daftar voucher milik user dari halaman Akun.
Future<void> bukaVoucherSaya(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _VoucherSayaSheet(),
  );
}

class _VoucherSayaSheet extends StatefulWidget {
  const _VoucherSayaSheet();

  @override
  State<_VoucherSayaSheet> createState() => _VoucherSayaSheetState();
}

class _VoucherSayaSheetState extends State<_VoucherSayaSheet> {
  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  void _muatUlang() => setState(() {});

  String _tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

  bool _berlaku(Voucher v) => v.aktif && !v.kedaluwarsa();

  String _catatan(Voucher v) {
    if (!v.aktif) return 'Voucher tidak aktif';
    if (v.kedaluwarsa()) return 'Voucher telah kedaluwarsa';

    final bagian = <String>[
      if (v.minBelanja > 0) 'Min. belanja ${rp(v.minBelanja)}',
      if (v.berlakuSampai != null) 'Berlaku s.d. ${_tanggal(v.berlakuSampai!)}',
    ];

    return bagian.isEmpty ? 'Gunakan voucher untuk pesananmu' : bagian.join(' · ');
  }

  // _salin: sheet ditutup dulu, SnackBar dari root tertutup barrier kalau sheet masih terbuka
  Future<void> _salin(Voucher v) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: v.kode));
    if (!mounted) return;
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Kode ${v.kode} berhasil disalin'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text('Voucher Saya', style: ts(18, 800, ls: -0.3)),
        ),
        Flexible(
          child: StreamBuilder(
            stream: UserRepo.stream(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting &&
                  !userSnap.hasData) {
                return _loading(context);
              }

              if (userSnap.hasError) {
                return _tampilanError();
              }

              final kode = UserRepo.voucherDari(userSnap.data?.data());

              return StreamBuilder<List<Voucher>>(
                stream: VoucherRepository.streamKode(kode),
                builder: (context, snap) {
                  final keadaan = keadaanStream<List<Voucher>>(
                    snap,
                    onCoba: _muatUlang,
                    kosong: (data) => data.isEmpty,
                    tampilanKosong: const EmptyView(
                      icon: Icons.local_offer_outlined,
                      judul: 'Belum ada voucher',
                      pesan: 'Voucher yang kamu dapatkan akan muncul di sini.',
                    ),
                  );

                  if (!snap.hasData && !snap.hasError) return _loading(context);
                  if (keadaan != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: keadaan,
                    );
                  }

                  final aktif = snap.requireData.where(_berlaku).toList();
                  final lainnya =
                      snap.requireData.where((v) => !_berlaku(v)).toList();

                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      // VOUCHER AKTIF
                      if (aktif.isNotEmpty) ...[
                        _judulBagian('Bisa digunakan', aktif.length),
                        const SizedBox(height: 13),
                        ...aktif.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: KartuVoucherItem(
                              voucher: v,
                              catatan: _catatan(v),
                              onTap: () => _salin(v),
                              trailing: const Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],

                      // VOUCHER KEDALUWARSA / TIDAK AKTIF
                      if (lainnya.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _judulBagian('Voucher lainnya', lainnya.length),
                        const SizedBox(height: 13),
                        ...lainnya.map(
                          (v) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: KartuVoucherItem(
                              voucher: v,
                              catatan: _catatan(v),
                              onTap: null,
                              trailing: const Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (aktif.isNotEmpty)
                        Text(
                          'Ketuk voucher untuk menyalin kodenya.',
                          textAlign: TextAlign.center,
                          style: ts(12, 400, color: AppColors.muted),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // _loading: setinggi setengah layar agar sheet tidak terlalu tinggi saat memuat
  Widget _loading(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: const LoadingView(),
      );

  Widget _judulBagian(String judul, int jumlah) {
    return Row(
      children: [
        Expanded(
          child: Text(judul, style: ts(15, 700)),
        ),
        Text(
          '$jumlah voucher',
          style: ts(12, 500, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _tampilanError() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 42,
            color: AppColors.muted,
          ),
          const SizedBox(height: 14),
          Text('Voucher gagal dimuat', style: ts(17, 700)),
          const SizedBox(height: 6),
          Text(
            'Periksa koneksi internet dan coba lagi.',
            textAlign: TextAlign.center,
            style: ts(13, 400, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _muatUlang,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}
