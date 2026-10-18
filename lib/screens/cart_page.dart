import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import '../widgets/voucher_sheet.dart';
import 'orders_page.dart';

// CartPage: layar Keranjang (DESIGN.md 3.5), tanpa navbar
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    // Ambil tarif pajak terbaru dari config/menu (main.dart milik P2, tidak diubah)
    context.read<CartProvider>().muatConfig();
  }

  void _snack(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // _pesan: checkout (transaction) → buka tab Pesanan Aktif → tutup Keranjang
  Future<void> _pesan(CartProvider cart) async {
    try {
      await cart.checkout();
      if (!mounted) return;
      OrdersPage.mintaAktif();
      NavigationPage.tab.value = NavigationPage.tabPesanan;
      Navigator.pop(context);
    } on CheckoutException catch (e) {
      if (!mounted) return;
      _snack(e.pesan);
    } catch (_) {
      if (!mounted) return;
      _snack('Gagal membuat pesanan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final kosong = cart.items.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _header(cart),
            const SizedBox(height: 20),
            if (kosong)
              _keadaanKosong()
            else ...[
              Text('Metode pesanan', style: ts(16, 800)),
              const SizedBox(height: 10),
              _metodePesanan(cart),
              const SizedBox(height: 24),
              Text('Pesananmu', style: ts(16, 800)),
              const SizedBox(height: 10),
              _kartuItem(cart),
              const SizedBox(height: 16),
              _kartuVoucher(cart),
              const SizedBox(height: 16),
              _ringkasan(cart),
              const SizedBox(height: 14),
              _catatanBayar(),
            ],
          ],
        ),
      ),
      bottomNavigationBar: kosong ? null : _barBawah(cart),
    );
  }

  // ---------- HEADER ----------
  Widget _header(CartProvider cart) {
    return Row(
      children: [
        RoundIconButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Kembali',
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('Keranjang', style: ts(24, 800, ls: -0.4))),
        if (cart.totalItems > 0)
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.tint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('${cart.totalItems} item',
                    style: ts(12, 700, color: AppColors.primary)),
              ],
            ),
          ),
      ],
    );
  }

  // ---------- KEADAAN KOSONG ----------
  Widget _keadaanKosong() {
    return Column(
      children: [
        const SizedBox(height: 24),
        const EmptyView(
          icon: Icons.shopping_basket_outlined,
          judul: 'Keranjang masih kosong',
          pesan: 'Yuk, pilih menu favoritmu dulu.',
        ),
        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Lihat menu',
          onPressed: () {
            NavigationPage.tab.value = NavigationPage.tabMenu;
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  // ---------- METODE PESANAN ----------
  Widget _metodePesanan(CartProvider cart) {
    return Row(
      children: [
        Expanded(
          child: _KartuMetode(
            label: 'Ambil Sendiri',
            sub: 'Ambil di kasir',
            aset: 'assets/images/ikon-ambil-sendiri.png',
            aktif: !cart.makanDiTempat,
            onTap: () => cart.setMakanDiTempat(false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KartuMetode(
            label: 'Makan di Tempat',
            sub: 'Nikmati di kedai',
            aset: 'assets/images/ikon-makan-di-tempat.png',
            aktif: cart.makanDiTempat,
            onTap: () => cart.setMakanDiTempat(true),
          ),
        ),
      ],
    );
  }

  // ---------- DAFTAR ITEM ----------
  Widget _kartuItem(CartProvider cart) {
    final items = cart.items;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _barisItem(cart, items[i], terakhir: i == items.length - 1),
        ],
      ),
    );
  }

  // _barisItem: thumbnail 64 · nama · opsi · harga · stepper
  Widget _barisItem(CartProvider cart, CartItem item,
      {required bool terakhir}) {
    return Container(
      key: ValueKey(item.kunci), // Key unik agar gambar tidak tertukar
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: terakhir
            ? null
            : const Border(bottom: BorderSide(color: AppColors.dividerSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumb(
            size: 64,
            makanan: item.makanan,
            nama: item.nama,
            url: item.gambarUrl,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama, style: ts(15, 700)),
                if (item.labelOpsi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.labelOpsi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ts(12, 500, color: AppColors.muted),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(rp(item.totalHarga),
                          style: ts(15, 800, color: AppColors.primary)),
                    ),
                    // Jumlah 1: tombol kurang berubah jadi ikon hapus
                    _tombolStepper(
                      item.jumlah <= 1
                          ? Icons.delete_outline_rounded
                          : Icons.remove_rounded,
                      item.jumlah <= 1 ? 'Hapus' : 'Kurangi',
                      () => cart.changeQuantity(item.kunci, item.jumlah - 1),
                      warna: item.jumlah <= 1
                          ? AppColors.danger
                          : AppColors.primary,
                    ),
                    SizedBox(
                      width: 28,
                      child: Text('${item.jumlah}',
                          textAlign: TextAlign.center, style: ts(15, 800)),
                    ),
                    _tombolStepper(
                      Icons.add_rounded,
                      'Tambah',
                      () => cart.changeQuantity(item.kunci, item.jumlah + 1),
                      isi: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _tombolStepper: lingkaran 32 (hit area 44). isi = latar primary + ikon putih.
  Widget _tombolStepper(
    IconData icon,
    String tooltip,
    VoidCallback onTap, {
    bool isi = false,
    Color warna = AppColors.primary,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isi ? AppColors.primary : AppColors.surface,
          border: isi ? null : Border.all(color: AppColors.outline),
        ),
        child: Icon(icon, size: 18, color: isi ? Colors.white : warna),
      ),
    );
  }

  // ---------- VOUCHER ----------
  // Kartu tint: "Pakai voucher" / "KODE diterapkan · Hemat Rp…" + Ganti.
  // Voucher tak lagi memenuhi syarat → "KODE belum berlaku" + alasan.
  Widget _kartuVoucher(CartProvider cart) {
    final alasan = cart.alasanVoucher;
    final ada = cart.voucher != null;

    final judul = !ada
        ? 'Pakai voucher'
        : alasan == null
            ? '${cart.voucher} diterapkan'
            : '${cart.voucher} belum berlaku';
    final sub = !ada
        ? 'Pilih voucher untuk hemat pesananmu'
        : alasan ?? 'Hemat ${rp(cart.diskon)}';

    return Material(
      color: AppColors.tint,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => bukaGantiVoucher(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sell_outlined,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul,
                        style: ts(14, ada ? 800 : 700,
                            color: ada ? AppColors.primary : AppColors.ink)),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: ts(
                        12,
                        ada ? 700 : 500,
                        color: ada ? AppColors.promoLabel : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(ada ? 'Ganti' : 'Pilih',
                  style: ts(13, 700, color: AppColors.primary)),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- RINGKASAN ----------
  Widget _ringkasan(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Ringkasan pembayaran', style: ts(16, 800)),
            ],
          ),
          const SizedBox(height: 12),
          _barisRingkasan('Subtotal', rp(cart.subtotal)),
          if (cart.diskon > 0)
            _barisRingkasan('Diskon', '−${rp(cart.diskon)}',
                warnaNilai: AppColors.promoLabel),
          _barisRingkasan('Pajak ${cart.persenPajak}%', rp(cart.pajak)),
          const Divider(height: 24, color: AppColors.divider),
          Row(
            children: [
              Expanded(child: Text('Total', style: ts(14, 700))),
              Text(rp(cart.total),
                  style: ts(20, 800, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  // _barisRingkasan: label muted kiri, nilai kanan (13)
  Widget _barisRingkasan(String label, String nilai, {Color? warnaNilai}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: ts(13, 500, color: AppColors.muted))),
          Text(nilai, style: ts(13, 600, color: warnaNilai ?? AppColors.ink)),
        ],
      ),
    );
  }

  // _catatanBayar: ikon tint 36 + keterangan pembayaran
  Widget _catatanBayar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.tint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.payments_outlined,
                size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Bayar di kasir dengan tunai atau QRIS.',
                style: ts(13, 600, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  // ---------- BAR BAWAH ----------
  // Sheet surface radius atas 28: total di kiri, tombol Pesan di kanan.
  Widget _barBawah(CartProvider cart) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppShadows.navSheet,
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total', style: ts(12, 600, color: AppColors.muted)),
                Text(rp(cart.total), style: ts(18, 800)),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                label: cart.memproses ? 'Memproses...' : 'Pesan sekarang',
                onPressed: cart.memproses ? null : () => _pesan(cart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// _KartuMetode: pilihan metode pesanan (ilustrasi 48 · judul · keterangan).
// Terpilih: latar tint + border 1.5 primary + centang.
class _KartuMetode extends StatelessWidget {
  final String label;
  final String sub;
  final String aset;
  final bool aktif;
  final VoidCallback onTap;
  const _KartuMetode({
    required this.label,
    required this.sub,
    required this.aset,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: aktif,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          decoration: BoxDecoration(
            color: aktif ? AppColors.tint : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: aktif ? AppColors.primary : AppColors.outline,
              width: aktif ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 48,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      aset,
                      height: 48,
                      errorBuilder: (_, _, _) => const Icon(
                          Icons.coffee_outlined,
                          size: 40,
                          color: AppColors.primary),
                    ),
                    if (aktif)
                      const Positioned(
                        top: 0,
                        right: 0,
                        child: Icon(Icons.check_circle_rounded,
                            size: 20, color: AppColors.primary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: ts(14, 700,
                      color: aktif ? AppColors.primary : AppColors.ink)),
              const SizedBox(height: 2),
              Text(sub,
                  textAlign: TextAlign.center,
                  style: ts(12, 500, color: AppColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}