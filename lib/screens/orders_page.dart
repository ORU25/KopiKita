import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/cart_item.dart';
import '../models/pesanan.dart';
import '../models/produk.dart';
import '../providers/cart_provider.dart';
import '../services/order_repository.dart';
import '../services/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'cart_page.dart';

// OrdersPage: layar Pesanan (DESIGN.md 3.6 Aktif & 3.7 Riwayat)
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  // Permintaan pindah sub-tab. `gen` naik tiap request agar notifier
  // tetap memicu listener walau sub-tab tujuan sama.
  static final ValueNotifier<(int gen, int tab)> _minta =
      ValueNotifier<(int, int)>((0, 0));

  static void mintaAktif() => _minta.value = (_minta.value.$1 + 1, 0);
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

// _TabAktif: daftar pesanan aktif sebagai accordion baris datar.
// Tepat satu yang terbuka; baris yang terbuka tidak bisa ditutup.
class _TabAktif extends StatefulWidget {
  const _TabAktif();

  @override
  State<_TabAktif> createState() => _TabAktifState();
}

class _TabAktifState extends State<_TabAktif> {
  late Stream<List<Pesanan>> _stream = OrderRepository.streamAktif();

  // ID pesanan yang sedang terbuka (null → pesanan pertama)
  String? _terbuka;

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

        // Pesanan terbuka sudah selesai/batal (hilang dari stream) → buka yang pertama
        final terbuka = daftarPesanan.any((p) => p.id == _terbuka)
            ? _terbuka
            : daftarPesanan.first.id;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 170),
          itemCount: daftarPesanan.length,
          itemBuilder: (context, index) {
            final pesanan = daftarPesanan[index];
            return _KartuPesananAktif(
              pesanan: pesanan,
              isExpanded: pesanan.id == terbuka,
              onToggle: () => setState(() => _terbuka = pesanan.id),
              onBatalkan: () => _konfirmasiBatalkan(context, pesanan),
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

// _KartuPesananAktif: header baris datar (seperti Riwayat); saat terbuka
// menampilkan kartu antrean, stepper, detail item (AnimatedSize).
class _KartuPesananAktif extends StatelessWidget {
  final Pesanan pesanan;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onBatalkan;

  const _KartuPesananAktif({
    required this.pesanan,
    required this.isExpanded,
    required this.onToggle,
    required this.onBatalkan,
  });

  @override
  Widget build(BuildContext context) {
    final item = pesanan.items.isNotEmpty ? pesanan.items.first : null;
    final metode = pesanan.makanDiTempat
        ? 'Meja ${pesanan.nomorMeja}'
        : 'Ambil sendiri';

    // Header baris datar; yang terbuka tidak bisa ditutup (onTap null)
    final header = InkWell(
      onTap: isExpanded ? null : onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            ProductThumb(
              size: 48,
              nama: item?.nama,
              url: item?.gambarUrl,
              makanan: item?.makanan ?? false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Antrean ${pesanan.nomor}', style: ts(14, 700)),
                  Text(
                    '${statusPesanan[pesanan.status][0]} · $metode',
                    style: ts(12, 500, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(rp(pesanan.total), style: ts(14, 800)),
            const SizedBox(width: 4),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        header,
        // Detail pesanan (hanya tampil kalau di-expand)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 16),
                  child: Column(
                    children: [
                      // 1. Kartu Antrean Cokelat
                      _kartuAntrean(pesanan),
                      const SizedBox(height: 12),
                      // 2. Stepper Vertikal (Desain Awal)
                      _kartuStatus(pesanan.status),
                      const SizedBox(height: 12),
                      // 3. Rincian Item (Desain Awal)
                      _kartuDetail(pesanan),
                      // 4. Tombol Batalkan (Desain Awal, Full Width)
                      if (pesanan.status == 0) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 52,
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onBatalkan,
                            icon: const Icon(Icons.close_rounded, size: 20),
                            label: Text('Batalkan pesanan', style: ts(14, 700)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(
                                color: AppColors.danger,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
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
}

// _TabRiwayat: riwayat pesanan dari Firestore, dikelompokkan per bulan.
class _TabRiwayat extends StatefulWidget {
  const _TabRiwayat();

  @override
  State<_TabRiwayat> createState() => _TabRiwayatState();
}

class _TabRiwayatState extends State<_TabRiwayat> {
  late Stream<List<Pesanan>> _stream = OrderRepository.streamRiwayat();
  // Stream produk: status Habis diperbarui realtime (toggle dari web Staf/Admin)
  late final Stream<List<Produk>> _produk = ProductRepository.stream();

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

        // Ketersediaan menu. Katalog belum termuat / gagal / kosong → null,
        // artinya semua menu dianggap tersedia (tidak memblokir Riwayat).
        return StreamBuilder<List<Produk>>(
          stream: _produk,
          builder: (context, produkSnap) {
            final data = produkSnap.data;
            final katalog = data == null || data.isEmpty
                ? null
                : {for (final pr in data) pr.id: pr};

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
                  for (final p in bulan.value) _baris(context, p, katalog),
                ],
              ],
            );
          },
        );
      },
    );
  }

  // _baris: satu baris riwayat (thumbnail 48 · ringkasan · total · Pesan lagi)
  // Menu yang sekarang habis ditandai lencana "Habis"; bila semua menu habis,
  // tombol Pesan lagi dinonaktifkan.
  Widget _baris(BuildContext context, Pesanan p, Map<String, Produk>? katalog) {
    final habis = menuTidakTersedia(p, katalog);
    final semuaHabis = p.items.isNotEmpty && habis.length == p.items.length;
    final ringkasan = p.items.map((i) => i.nama).join(', ');
    final tgl = p.createdAt == null
        ? ''
        : DateFormat('d MMM', 'id_ID').format(p.createdAt!);
    final statusTeks = p.batal ? 'Dibatalkan' : 'Selesai';
    final warnaStatus = p.batal ? AppColors.danger : AppColors.muted;

    return Opacity(
      opacity: semuaHabis
          ? 0.6
          : 1, // abu-abu seperti Menu bila semua menu habis
      child: Container(
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
                  if (habis.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const HabisBadge(),
                        // Nama hanya ditampilkan bila sebagian menu yang habis
                        if (!semuaHabis) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              habis.map((i) => i.nama).toSet().join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ts(12, 500, color: AppColors.muted),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
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
                    // Menu habis tidak ikut; semua habis → tombol nonaktif
                    onPressed: semuaHabis
                        ? null
                        : () => pesanLagi(
                            context,
                            p,
                            tidakTersedia: {for (final i in habis) i.productId},
                          ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text('Pesan lagi', style: ts(12, 700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      disabledForegroundColor: AppColors.muted,
                      side: BorderSide(
                        color: semuaHabis
                            ? AppColors.outline
                            : AppColors.primary,
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
      ),
    );
  }
}

/// menuTidakTersedia: item pesanan yang sekarang habis atau sudah dihapus dari
/// menu. [katalog] null (belum termuat / gagal) → semua dianggap tersedia.
/// Item data lama tanpa productId tidak bisa dicek → dianggap tersedia.
List<CartItem> menuTidakTersedia(Pesanan p, Map<String, Produk>? katalog) {
  if (katalog == null) return const [];
  return [
    for (final i in p.items)
      if (i.productId.isNotEmpty && (katalog[i.productId]?.habis ?? true)) i,
  ];
}

/// pesanLagi: membuka Keranjang TERPISAH yang hanya berisi menu dari pesanan
/// lama — tidak digabung dengan keranjang utama. Keranjang ini punya
/// CartProvider sendiri (metode pesanan, voucher, total, checkout) dan dibuang
/// saat halamannya ditutup. Menu yang habis ([tidakTersedia] = productId) tidak
/// ikut dimasukkan. Fungsi publik agar bisa dipakai P3 di Beranda (#7).
void pesanLagi(
  BuildContext context,
  Pesanan p, {
  Set<String> tidakTersedia = const {},
}) {
  final items = [
    for (final i in p.items)
      if (!tidakTersedia.contains(i.productId)) i,
  ];
  if (items.isEmpty) return;

  final cart = CartProvider();
  for (final item in items) {
    cart.addItem(item);
  }

  final messenger = ScaffoldMessenger.of(context);
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ChangeNotifierProvider<CartProvider>(
        create: (_) => cart,
        child: const CartPage(),
      ),
    ),
  );

  final dilewati = p.items.length - items.length;
  messenger.hideCurrentSnackBar();
  if (dilewati > 0) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('$dilewati menu yang habis tidak ikut ditambahkan.'),
      ),
    );
  }
}
