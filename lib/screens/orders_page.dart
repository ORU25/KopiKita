import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/pesanan.dart';
import '../providers/cart_provider.dart';
import '../services/order_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

// OrdersPage: layar Pesanan (DESIGN.md 3.6 Aktif & 3.7 Riwayat)
// Sumber data: orders/{id} via OrderRepository (realtime) — bukan dummy lagi.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  // Permintaan pindah sub-tab. `gen` naik tiap request agar notifier
  // tetap memicu listener walau sub-tab tujuan sama.
  static final ValueNotifier<(int gen, int tab)> _minta =
      ValueNotifier<(int, int)>((0, 0));

  /// Pindah ke sub-tab Aktif (dipanggil dari bottom nav "Pesanan").
  static void mintaAktif() => _minta.value = (_minta.value.$1 + 1, 0);

  /// Pindah ke sub-tab Riwayat (dipanggil dari "Pesan Lagi" di Beranda).
  static void mintaRiwayat() => _minta.value = (_minta.value.$1 + 1, 1);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _genTerakhir = 0;

  @override
  void initState() {
    super.initState();
    final (gen, tab) = OrdersPage._minta.value;
    _genTerakhir = gen;
    _tab = TabController(length: 2, vsync: this, initialIndex: tab);
    OrdersPage._minta.addListener(_onMinta);
  }

  void _onMinta() {
    final (gen, tab) = OrdersPage._minta.value;
    if (gen <= _genTerakhir) return;
    _genTerakhir = gen;
    _tab.animateTo(tab);
  }

  @override
  void dispose() {
    OrdersPage._minta.removeListener(_onMinta);
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
              controller: _tab,
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
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [_TabAktif(), _TabRiwayat()],
            ),
          ),
        ],
      ),
    );
  }
}

// _TabAktif: stream pesanan aktif user + kartu antrean + stepper status.
// Realtime: perubahan status dari web Staf langsung sampai ke sini.
class _TabAktif extends StatefulWidget {
  const _TabAktif();

  @override
  State<_TabAktif> createState() => _TabAktifState();
}

class _TabAktifState extends State<_TabAktif> {
  // State: stream dibuat sekali di State (bukan di build) agar tidak berlangganan ulang
  late Stream<List<Pesanan>> _stream = OrderRepository.streamAktif();

  // _muatUlang: berlangganan ulang setelah error
  void _muatUlang() => setState(() => _stream = OrderRepository.streamAktif());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pesanan>>(
      stream: _stream,
      builder: (context, snap) {
        final keadaan = keadaanStream<List<Pesanan>>(
          snap,
          onCoba: _muatUlang,
          kosong: (d) => d.isEmpty,
          tampilanKosong: const EmptyView(
            icon: Icons.receipt_long_outlined,
            judul: 'Belum ada pesanan aktif',
            pesan: 'Pesanan yang sedang berjalan akan tampil di sini. Yuk pesan menu favoritmu!',
          ),
        );
        if (keadaan != null) return keadaan;

        final pesanan = snap.requireData.first;
        return _isiAktif(context, pesanan);
      },
    );
  }

  Widget _isiAktif(BuildContext context, Pesanan pesanan) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
      children: [
        _kartuAntrean(pesanan),
        const SizedBox(height: 16),
        _kartuStatus(pesanan.status),
        const SizedBox(height: 16),
        _kartuDetail(pesanan),
        // Tombol Batalkan hanya saat masih menunggu_bayar (index 0).
        if (pesanan.status == 0) ...[
          const SizedBox(height: 16),
          _tombolBatalkan(context, pesanan),
        ],
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
                        Text(
                          'Nomor antrean',
                          style: ts(12, 600, color: AppColors.cream),
                        ),
                        Text(
                          p.nomor,
                          style: ts(
                            48,
                            800,
                            color: AppColors.cream,
                            ls: -1,
                            height: 1.1,
                          ),
                        ),
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
                    child: Text(
                      statusPesanan[p.status][0],
                      style: ts(13, 800, color: AppColors.primary),
                    ),
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
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
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
                    style: ts(
                      14,
                      kini ? 800 : 600,
                      color: selesai || kini ? AppColors.ink : AppColors.muted,
                    ),
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
                    child: Text(
                      '${item.jumlah}× ${item.labelSingkat}',
                      style: ts(14, 600),
                    ),
                  ),
                  Text(
                    rp(item.totalHarga),
                    style: ts(14, 500, color: AppColors.muted),
                  ),
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

  // _tombolBatalkan: hanya untuk status `menunggu_bayar`.
  Widget _tombolBatalkan(BuildContext context, Pesanan p) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _konfirmasiBatalkan(context, p),
        icon: const Icon(Icons.close_rounded, size: 20),
        label: Text('Batalkan pesanan', style: ts(14, 700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _konfirmasiBatalkan(BuildContext context, Pesanan p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Batalkan pesanan?', style: ts(16, 800, ls: -0.3)),
        content: Text(
          'Pesanan ${p.nomor} akan dibatalkan dan tidak bisa dikembalikan.',
          style: ts(13, 500, color: AppColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Tidak', style: ts(13, 700, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Ya, batalkan',
              style: ts(13, 700, color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (yakin != true) return;
    if (!context.mounted) return;
    try {
      await OrderRepository.batalkan(p.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Pesanan dibatalkan.')));
    } catch (e) {
      if (!context.mounted) return;
      final pesan = e is StateError
          ? e.message
          : 'Gagal membatalkan pesanan. Coba lagi.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pesan)));
    }
  }
}

// _TabRiwayat: riwayat pesanan dari Firestore, dikelompokkan per bulan.
class _TabRiwayat extends StatefulWidget {
  const _TabRiwayat();

  @override
  State<_TabRiwayat> createState() => _TabRiwayatState();
}

class _TabRiwayatState extends State<_TabRiwayat> {
  late Stream<List<Pesanan>> _stream = OrderRepository.streamRiwayat();

  void _muatUlang() =>
      setState(() => _stream = OrderRepository.streamRiwayat());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pesanan>>(
      stream: _stream,
      builder: (context, snap) {
        final keadaan = keadaanStream<List<Pesanan>>(
          snap,
          onCoba: _muatUlang,
          kosong: (d) => d.isEmpty,
          tampilanKosong: const EmptyView(
            icon: Icons.history_rounded,
            judul: 'Belum ada riwayat',
            pesan: 'Pesanan yang sudah selesai atau dibatalkan tampil di sini.',
          ),
        );
        if (keadaan != null) return keadaan;

        // Kelompokkan per bulan (kunci: "Oktober 2026")
        final grup = <String, List<Pesanan>>{};
        for (final p in snap.requireData) {
          final tgl = p.createdAt;
          final kunci = tgl == null
              ? 'Tanpa tanggal'
              : DateFormat('MMMM yyyy', 'id_ID').format(tgl);
          grup.putIfAbsent(kunci, () => []).add(p);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 170),
          children: [
            for (final bulan in grup.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(
                  bulan.key,
                  style: ts(13, 700, color: AppColors.muted),
                ),
              ),
              for (final p in bulan.value) _baris(context, p),
            ],
          ],
        );
      },
    );
  }

  // _baris: satu baris riwayat (thumbnail 48 · ringkasan · total · Pesan lagi)
  Widget _baris(BuildContext context, Pesanan p) {
    final ringkasan = p.items.map((i) => i.nama).join(', ');
    final tgl = p.createdAt == null
        ? ''
        : DateFormat('d MMM', 'id_ID').format(p.createdAt!);
    final statusTeks = p.batal ? 'Dibatalkan' : 'Selesai';
    final warnaStatus = p.batal ? AppColors.danger : AppColors.muted;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          ProductThumb(
            size: 48,
            nama: p.items.isNotEmpty ? p.items.first.nama : null,
            url: p.items.isNotEmpty ? p.items.first.gambarUrl : null,
            makanan: p.items.isNotEmpty ? p.items.first.makanan : false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ringkasan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ts(14, 700),
                ),
                Text(
                  '$tgl · $statusTeks',
                  style: ts(12, 500, color: warnaStatus),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rp(p.total), style: ts(14, 800)),
              const SizedBox(height: 6),
              // Tombol "Pesan lagi" outline kecil (target sentuh 44 via padding)
              SizedBox(
                height: 32,
                child: OutlinedButton.icon(
                  onPressed: () => pesanLagi(context, p),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text('Pesan lagi', style: ts(12, 700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// pesanLagi: menambahkan seluruh item pesanan lama ke CartProvider, lalu
/// pindah ke tab Menu. Fungsi publik agar bisa dipakai P3 di Beranda (#7).
void pesanLagi(BuildContext context, Pesanan p) {
  if (p.items.isEmpty) return;
  final cart = context.read<CartProvider>();
  for (final item in p.items) {
    cart.addItem(item);
  }
  NavigationPage.tab.value = NavigationPage.tabMenu;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('${p.items.length} item ditambahkan ke keranjang.'),
      ),
    );
}
