import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

// CartPage: layar Keranjang (DESIGN.md 3.5), tanpa navbar
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  // _pesan: buat pesanan, kembali ke halaman utama, buka tab Pesanan
  void _pesan(BuildContext context, CartProvider cart) {
    cart.checkout(); // Status awal: menunggu_bayar
    NavigationPage.tab.value = NavigationPage.tabPesanan;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // context.watch: rebuild setiap isi keranjang berubah
    final cart = context.watch<CartProvider>();

    // Scaffold: kerangka halaman Keranjang
    return Scaffold(
      body: SafeArea(
        // ListView: konten bisa di-scroll, padding 24 20
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // Header: tombol kembali · judul · jumlah item
            Row(
              children: [
                IconButton(
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left_rounded,
                      size: 28, color: AppColors.ink),
                ),
                const SizedBox(width: 4),
                Expanded(child: Text('Keranjang', style: ts(22, 700, ls: -0.3))),
                Text('${cart.totalItems} item',
                    style: ts(13, 600, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented tipe pesanan (terpilih tint/primary)
            SegmentedPill(
              options: const ['Makan di tempat', 'Ambil sendiri'],
              selected: cart.makanDiTempat ? 0 : 1,
              onChanged: (i) => cart.setMakanDiTempat(i == 0),
              background: AppColors.surface,
              selectedBackground: AppColors.tint,
              selectedForeground: AppColors.primary,
              foreground: AppColors.muted,
            ),

            // Baris nomor meja (hanya bila makan di tempat)
            if (cart.makanDiTempat)
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.divider)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Nomor meja',
                          style: ts(14, 500, color: AppColors.muted)),
                    ),
                    Text('${cart.nomorMeja}', style: ts(14, 700)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Keadaan kosong
            if (cart.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Text('Keranjang masih kosong.',
                    textAlign: TextAlign.center,
                    style: ts(14, 600, color: AppColors.muted)),
              )
            else ...[
              // Card putih radius 20 berisi item + voucher
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    for (final item in cart.items) _barisItem(cart, item),
                    _barisVoucher(context, cart),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Ringkasan datar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    _barisRingkasan('Subtotal', rp(cart.subtotal)),
                    if (cart.diskon > 0)
                      _barisRingkasan('Diskon', '−${rp(cart.diskon)}'),
                    _barisRingkasan('Pajak 10%', rp(cart.pajak)),
                    const Divider(height: 24, color: AppColors.divider),
                    Row(
                      children: [
                        Expanded(child: Text('Total', style: ts(14, 700))),
                        Text(rp(cart.total), style: ts(18, 800)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bayar di kasir dengan tunai atau QRIS.',
                          style: ts(12, 500, color: AppColors.muted)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      // Tombol utama tetap di bawah (left/right 20, bottom 24)
      bottomNavigationBar: cart.items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: PrimaryButton(
                  label: 'Pesan · ${rp(cart.total)}',
                  onPressed: () => _pesan(context, cart),
                ),
              ),
            ),
    );
  }

  // _barisItem: thumbnail 56 · nama · opsi · harga · stepper
  Widget _barisItem(CartProvider cart, CartItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.dividerSoft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumb(size: 56, makanan: item.makanan, nama: item.nama),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.nama, style: ts(14, 700)),
                if (item.labelOpsi.isNotEmpty)
                  Text(item.labelOpsi, style: ts(12, 500, color: AppColors.muted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: Text(rp(item.totalHarga), style: ts(14, 700))),
                    // Stepper bulat − n +
                    _tombolStepper(Icons.remove_rounded, 'Kurangi',
                        () => cart.changeQuantity(item.kunci, item.jumlah - 1)),
                    SizedBox(
                      width: 28,
                      child: Text('${item.jumlah}',
                          textAlign: TextAlign.center, style: ts(14, 700)),
                    ),
                    _tombolStepper(Icons.add_rounded, 'Tambah',
                        () => cart.changeQuantity(item.kunci, item.jumlah + 1)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // _tombolStepper: lingkaran 32 border outline, hit area 44
  Widget _tombolStepper(IconData icon, String tooltip, VoidCallback onTap) {
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
          border: Border.all(color: AppColors.outline),
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }

  // _barisVoucher: "KOPIKITA20 diterapkan" + link "Ganti"
  Widget _barisVoucher(BuildContext context, CartProvider cart) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const Icon(Icons.sell_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cart.voucher == null ? 'Belum ada voucher' : '${cart.voucher} diterapkan',
              style: ts(14, 600),
            ),
          ),
          TextButton(
            onPressed: () => segeraHadir(context, 'Ganti voucher'),
            child: Text('Ganti', style: ts(14, 700, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  // _barisRingkasan: label muted kiri, nilai kanan (13)
  Widget _barisRingkasan(String label, String nilai) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ts(13, 500, color: AppColors.muted))),
          Text(nilai, style: ts(13, 600)),
        ],
      ),
    );
  }
}
