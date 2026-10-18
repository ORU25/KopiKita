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

// _TabAktif: stream pesanan aktif user. Mendukung LEBIH DARI SATU pesanan
// (misal user checkout 2 kali). Ditampilkan sebagai daftar kartu modern.
class _TabAktif extends StatefulWidget {
  const _TabAktif();

  @override
  State<_TabAktif> createState() => _TabAktifState();
}

class _TabAktifState extends State<_TabAktif> {
  late Stream<List<Pesanan>> _stream = OrderRepository.streamAktif();

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

        final daftarPesanan = snap.requireData;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 170),
          itemCount: daftarPesanan.length,
          itemBuilder: (context, index) {
            final pesanan = daftarPesanan[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == daftarPesanan.length - 1 ? 0 : 24,
              ),
              child: _KartuPesananAktif(
                pesanan: pesanan,
                onBatalkan: () => _konfirmasiBatalkan(context, pesanan),
              ),
            );
          },
        );
      },
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

// _KartuPesananAktif: Desain modern mengadopsi referensi HTML (kartu gradasi
// cokelat, badge putih, stepper horizontal ikon).
class _KartuPesananAktif extends StatelessWidget {
  final Pesanan pesanan;
  final VoidCallback onBatalkan;

  const _KartuPesananAktif({required this.pesanan, required this.onBatalkan});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- 1. KARTU UTAMA (Gradasi & Stepper) ---
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF683315), // Cokelat gelap
                Color(0xFF87451F), // Cokelat medium
                Color(0xFFB35F28), // Cokelat terang
              ],
            ),
            boxShadow:
                AppShadows.float, // Pakai shadow float agar lebih melayang
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Ornamen Lingkaran (seperti di HTML)
                Positioned(
                  right: -40,
                  top: -40,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: -60,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.caramel.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Konten Kartu
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baris Atas: Nomor Antrean & Badge Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOMOR ANTREAN',
                                  style: ts(
                                    11,
                                    800,
                                    color: AppColors.cream.withValues(
                                      alpha: 0.9,
                                    ),
                                    ls: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pesanan.nomor,
                                  style: ts(
                                    40,
                                    800,
                                    color: Colors.white,
                                    ls: -1,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge Status Putih (seperti HTML)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  pesanan.status == 0
                                      ? Icons.schedule_rounded
                                      : pesanan.status == 3
                                      ? Icons.notifications_active_rounded
                                      : Icons.coffee_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  statusPesanan[pesanan.status][0],
                                  style: ts(12, 800, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Garis Pembatas
                      Divider(
                        color: Colors.white.withValues(alpha: 0.15),
                        height: 1,
                      ),
                      const SizedBox(height: 12),
                      // Metode Pesanan (Ambil Sendiri / Makan di Tempat)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 14,
                                  color: AppColors.cream,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  pesanan.makanDiTempat
                                      ? 'Makan di Tempat (Meja ${pesanan.nomorMeja})'
                                      : 'Ambil Sendiri',
                                  style: ts(11, 600, color: AppColors.cream),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Stepper Status Horizontal (Gaya HTML)
                      _StepperHorizontal(status: pesanan.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // --- 2. RINGKASAN ITEM & TOTAL
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outline, width: 1),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ProductThumb(
                    size: 48,
                    url: pesanan.items.isNotEmpty
                        ? pesanan.items.first.gambarUrl
                        : null,
                    nama: pesanan.items.isNotEmpty
                        ? pesanan.items.first.nama
                        : null,
                    makanan: pesanan.items.isNotEmpty
                        ? pesanan.items.first.makanan
                        : false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pesanan.items.isNotEmpty
                              ? pesanan.items.first.nama
                              : 'Pesanan',
                          style: ts(14, 700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          pesanan.items.length > 1
                              ? '+ ${pesanan.items.length - 1} item lainnya'
                              : '${pesanan.items.fold(0, (s, e) => s + e.jumlah)} item',
                          style: ts(12, 500, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    rp(pesanan.total),
                    style: ts(15, 800, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),

        // --- 3. TOMBOL BATALKAN
        if (pesanan.status == 0) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: onBatalkan,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  'Batalkan pesanan',
                  style: ts(12, 700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger, // Latar merah
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 38),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// _StepperHorizontal: indikator progres horizontal bergaya UI HTML.
// Titik yang sudah lewat pakai centang, titik aktif pakai ikon spesifik,
// titik belum pakai outline kosong.
class _StepperHorizontal extends StatelessWidget {
  final int status;
  const _StepperHorizontal({required this.status});

  @override
  Widget build(BuildContext context) {
    // Label untuk di bawah ikon
    const label = ['Menunggu', 'Dibayar', 'Proses', 'Siap', 'Selesai'];

    return Row(
      children: List.generate(statusPesanan.length, (index) {
        final selesai = index < status;
        final aktif = index == status;
        final warna = selesai || aktif
            ? Colors.white
            : Colors.white.withValues(alpha: 0.3);

        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  // Lingkaran Ikon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selesai
                          ? Colors
                                .white // Putih penuh jika selesai
                          : aktif
                          ? Colors.white.withValues(
                              alpha: 0.2,
                            ) // Transparan jika aktif
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selesai
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      selesai
                          ? Icons.check_rounded
                          : aktif
                          ? (index == 0
                                ? Icons.payments_rounded
                                : index == 1
                                ? Icons.verified_rounded
                                : index == 2
                                ? Icons.coffee_maker_rounded
                                : index == 3
                                ? Icons.notifications_active_rounded
                                : Icons.check_circle_rounded)
                          : null,
                      size: 16,
                      color: selesai
                          ? AppColors
                                .primary // Ikon cokelat jika latar putih
                          : Colors.white, // Ikon putih jika transparan
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Teks Label Kecil
                  Text(
                    label[index],
                    textAlign: TextAlign.center,
                    style: ts(
                      10,
                      aktif ? 700 : 500,
                      color: aktif || selesai
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              // Garis Penghubung (jika bukan index terakhir)
              if (index < statusPesanan.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(
                      bottom: 20,
                    ), // Naikkan sedikit agar sejajar tengah ikon
                    color: warna,
                  ),
                ),
            ],
          ),
        );
      }),
    );
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
