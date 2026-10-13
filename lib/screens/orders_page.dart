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

  @override
  Widget build(BuildContext context) {
    // DefaultTabController: mengatur state tab Aktif | Riwayat
    return DefaultTabController(
      length: 2,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul halaman 24/800
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text('Pesanan Saya', style: ts(24, 800, ls: -0.4)),
            ),
            // TabBar teks: garis bawah 2 primary di tab aktif, garis dasar 1 divider
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
            // TabBarView: isi tab Aktif dan Riwayat
            const Expanded(
              child: TabBarView(children: [_TabAktif(), _TabRiwayat()]),
            ),
          ],
        ),
      ),
    );
  }
}

// _TabAktif: kartu antrean + stepper status + detail pesanan
class _TabAktif extends StatelessWidget {
  const _TabAktif();

  @override
  Widget build(BuildContext context) {
    // context.watch: pesanan aktif berubah setelah checkout
    final pesanan = context.watch<CartProvider>().pesananAktif;
    if (pesanan == null) {
      return Center(
        child: Text('Belum ada pesanan aktif.',
            style: ts(14, 600, color: AppColors.muted)),
      );
    }

    // ponytail: status statis, nanti diganti Firestore stream (realtime)
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

  // _kartuAntrean: kartu primary radius 24 dengan lingkaran deko caramel
  Widget _kartuAntrean(Pesanan p) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: AppColors.primary,
        child: Stack(
          children: [
            // Lingkaran dekoratif caramel opacity 0.45
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
                  // Badge status: tinggi 32, latar cream, teks primary 13/800
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

  // _kartuStatus: stepper vertikal 5 langkah
  Widget _kartuStatus(int sekarang) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

  // _langkah: satu baris stepper (titik 28 + garis penghubung + label & catatan)
  Widget _langkah(int i, int sekarang, {required bool terakhir}) {
    final selesai = i < sekarang; // Langkah sudah dilalui
    final kini = i == sekarang; // Langkah saat ini
    // Catatan: langkah selesai menampilkan "Selesai", sisanya catatan aslinya
    final catatan = selesai ? 'Selesai' : statusPesanan[i][1];

    // IntrinsicHeight: agar garis penghubung setinggi baris
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kolom titik + garis
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
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                // Garis penghubung: primary bila sudah dilalui, outline bila belum
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
          // Label + catatan
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusPesanan[i][0],
                    style: ts(14, kini ? 800 : 600,
                        color: selesai || kini ? AppColors.ink : AppColors.muted),
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

  // _kartuDetail: daftar item + total dibayar
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
          // Header bulan 13/700 muted
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(bulan.key, style: ts(13, 700, color: AppColors.muted)),
          ),
          for (final r in bulan.value) _baris(context, r),
        ],
      ],
    );
  }

  // _baris: baris datar thumbnail 48 · ringkasan · tanggal · total + "Pesan lagi"
  Widget _baris(BuildContext context, RiwayatPesanan r) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Foto dari item pertama di ringkasan ("Americano, Croissant" → Americano)
          ProductThumb(size: 48, nama: r.ringkasan.split(RegExp(r',| ×')).first),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.ringkasan,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(14, 700)),
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
              // GestureDetector: "Pesan lagi" → buka tab Menu
              GestureDetector(
                onTap: () => NavigationPage.tab.value = NavigationPage.tabMenu,
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
