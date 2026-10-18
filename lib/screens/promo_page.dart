import 'dart:async';
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

  final PageController _pageController = PageController();
  int _halamanAktif = 0;
  Timer? _timerBanner;

  final List<String> _daftarBanner = [
    'assets/images/banner-promo-1.png',
    'assets/images/banner-promo-2.png',
    'assets/images/banner-promo-3.png',
  ];

  @override
  void initState() {
    super.initState();
    _mulaiAutoScroll();
  }

  void _mulaiAutoScroll() {
    _timerBanner = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        int halamanBerikutnya = (_halamanAktif + 1) % _daftarBanner.length;
        _pageController.animateToPage(
          halamanBerikutnya,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timerBanner?.cancel();
    _pageController.dispose();
    super.dispose();
  }

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

  Future<void> _salin(Voucher v) async {
    await Clipboard.setData(ClipboardData(text: v.kode));

    if (!mounted) return;

    ScaffoldMessenger.of(context)
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'Promo & Voucher',
          style: ts(19, 800, ls: -0.4),
        ),
      ),
      body: StreamBuilder(
        stream: UserRepo.stream(),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting &&
              !userSnap.hasData) {
            return const LoadingView();
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

              if (keadaan != null) return keadaan;

              final semua = [...snap.requireData];

              semua.sort((a, b) {
                final statusA = _berlaku(a) ? 0 : 1;
                final statusB = _berlaku(b) ? 0 : 1;
                return statusA.compareTo(statusB);
              });

              final aktif = semua.where(_berlaku).toList();
              final lainnya = semua.where((v) => !_berlaku(v)).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // CAROUSEL BANNER PROMOSI (3 Banner)
                  SizedBox(
                    height: 165,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _halamanAktif = index;
                        });
                      },
                      itemCount: _daftarBanner.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              _daftarBanner[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFEDE2D7),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 40,
                                    color: Color(0xFF8B6A52),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // INDIKATOR TITIK (DOTS)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _daftarBanner.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _halamanAktif == index ? 20 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _halamanAktif == index
                              ? AppColors.ink
                              : Colors.brown.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // JUDUL DAFTAR
                  Text(
                    'Voucher Saya',
                    style: ts(21, 800, ls: -0.6),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Pilih promo yang ingin kamu gunakan.',
                    style: ts(13, 400, color: AppColors.muted),
                  ),

                  const SizedBox(height: 20),

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

                  const SizedBox(height: 8),

                  if (aktif.isNotEmpty)
                    Text(
                      'Ketuk voucher yang tersedia untuk menyalin kodenya.',
                      textAlign: TextAlign.center,
                      style: ts(11, 400, color: AppColors.muted),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

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
    return Center(
      child: Padding(
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
      ),
    );
  }
}