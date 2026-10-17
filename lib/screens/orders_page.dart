import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../main.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// OrdersPage: layar Pesanan (DESIGN.md 3.6 Aktif & 3.7 Riwayat)
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  // Counter yang naik saat ada permintaan "buka tab Riwayat".
  static final ValueNotifier<int> _mintaRiwayat = ValueNotifier<int>(0);

  // mintaRiwayat: dipanggil dari luar (mis. tombol "Pesan Lagi" di Home)
  // agar OrdersPage landing di tab Riwayat, bukan tab Aktif default.
  static void mintaRiwayat() => _mintaRiwayat.value++;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _mintaRiwayat,
      builder: (context, gen, _) {
        return DefaultTabController(
          key: ValueKey(gen),
          length: 2,
          initialIndex: gen == 0 ? 0 : 1, // gen>0 → langsung tab Riwayat
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text('Pesanan Saya', style: ts(24, 800, ls: -0.4)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TabBar(
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 2,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: AppColors.divider,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.muted,
                    labelStyle: ts(14, 700),
                    unselectedLabelStyle: ts(14, 600),
                    tabs: const [
                      Tab(height: 44, text: 'Aktif'),
                      Tab(height: 44, text: 'Riwayat'),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(children: [_TabAktif(), _TabRiwayat()]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// _TabAktif: kartu antrean + stepper status + detail pesanan
class _TabAktif extends StatelessWidget {
  const _TabAktif();

  @override
  Widget build(BuildContext context) {
    final pesanan = context.watch<CartProvider>().pesananAktif;
    if (pesanan == null) {
      return Center(
        child: Text('Belum ada pesanan aktif.',
            style: ts(14, 600, color: AppColors.muted)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
      children: [
        _kartuAntrean(pesanan),
        const SizedBox(height: 16),
        _kartuStatus(pesanan.status),
        const SizedBox(height: 16),
        _kartuDetail(pesanan),
      ],
    );
  }

  Widget _kartuAntrean(Pesanan p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.primary,
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -20,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: AppColors.caramel.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nomor antrean',
                            style: ts(12, 600, color: AppColors.cream)),
                        Text(p.nomor,
                            style: ts(48, 800,
                                color: AppColors.cream, ls: -1, height: 1.1)),
                        Text(
                          p.makanDiTempat
                              ? 'Makan di tempat · Meja ${p.nomorMeja}'
                              : 'Ambil sendiri',
                          style: ts(13, 500, color: AppColors.cream),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(statusPesanan[p.status][0],
                        style: ts(13, 800, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartuStatus(int sekarang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < statusPesanan.length; i++)
            _langkah(i, sekarang, terakhir: i == statusPesanan.length - 1),
        ],
      ),
    );
  }

  Widget _langkah(int i, int sekarang, {required bool terakhir}) {
    final selesai = i < sekarang;
    final kini = i == sekarang;
    final catatan = selesai ? 'Selesai' : statusPesanan[i][1];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selesai
                        ? AppColors.primary
                        : kini
                            ? AppColors.caramel
                            : AppColors.surface,
                    border: selesai || kini
                        ? null
                        : Border.all(color: AppColors.pending, width: 2),
                  ),
                  child: selesai
                      ? const Icon(Icons.check_rounded,
                          size: 16, color: Colors.white)
                      : null,
                ),
                if (!terakhir)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: selesai ? AppColors.primary : AppColors.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusPesanan[i][0],
                    style: ts(14, kini ? 800 : 600,
                        color: selesai || kini
                            ? AppColors.ink
                            : AppColors.muted),
                  ),
                  Text(catatan, style: ts(12, 500, color: AppColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartuDetail(Pesanan p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (final item in p.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${item.jumlah}× ${item.labelSingkat}',
                        style: ts(14, 600)),
                  ),
                  Text(rp(item.totalHarga),
                      style: ts(14, 500, color: AppColors.muted)),
                ],
              ),
            ),
          const Divider(height: 20, color: AppColors.divider),
          Row(
            children: [
              Expanded(child: Text('Total dibayar', style: ts(14, 700))),
              Text(rp(p.total), style: ts(16, 800, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// _TabRiwayat: riwayat pesanan dikelompokkan per bulan
class _TabRiwayat extends StatelessWidget {
  const _TabRiwayat();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 170),
      children: [
        for (final bulan in riwayatPerBulan.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(bulan.key,
                style: ts(13, 700, color: AppColors.muted)),
          ),
          for (final r in bulan.value) _baris(context, r),
        ],
      ],
    );
  }

  Widget _baris(BuildContext context, RiwayatPesanan r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          ProductThumb(
              size: 48,
              nama: r.ringkasan.split(RegExp(r',| ×')).first),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ringkasan,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ts(14, 700)),
                Text('${r.tanggal} · ${r.status}',
                    style: ts(12, 500, color: AppColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rp(r.total), style: ts(14, 800)),
              GestureDetector(
                onTap: () =>
                    NavigationPage.tab.value = NavigationPage.tabMenu,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text('Pesan lagi',
                      style: ts(12, 700, color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}