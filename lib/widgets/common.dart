// Widget bersama yang dipakai di banyak layar (DESIGN.md bagian 2)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_page.dart';
import '../theme/app_theme.dart';

// segeraHadir: menampilkan SnackBar untuk fitur yang belum didesain
void segeraHadir(BuildContext context, String fitur) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar() // Tutup snackbar sebelumnya agar tidak menumpuk
    ..showSnackBar(SnackBar(content: Text('$fitur segera hadir')));
}

// rp: singkatan formatRupiah agar kode UI lebih ringkas
String rp(int v) => CartProvider.formatRupiah(v);

// PrimaryButton: tombol utama tinggi 52, radius 16, latar primary, teks putih 15/700
class PrimaryButton extends StatelessWidget {
  final String label; // Teks tombol
  final VoidCallback? onPressed; // Aksi saat ditekan (null = nonaktif)
  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    // SizedBox: memaksa tinggi 52 dan lebar penuh
    return SizedBox(
      height: 52,
      width: double.infinity,
      // FilledButton: tombol Material 3 dengan latar penuh
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.disabled,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: ts(15, 700, color: Colors.white)),
      ),
    );
  }
}

// RoundIconButton: tombol ikon bulat 44 (target sentuh minimum 44×44)
class RoundIconButton extends StatelessWidget {
  final IconData icon; // Ikon tombol
  final VoidCallback onTap; // Aksi saat ditekan
  final String tooltip; // Label aksesibilitas
  final Color background; // Warna latar (default putih)
  final Color foreground; // Warna ikon (default ink)
  final bool shadow; // true = pakai bayangan chip
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.background = AppColors.surface,
    this.foreground = AppColors.ink,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    // Container: lingkaran 44 dengan bayangan lembut
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: shadow ? AppShadows.chip : null,
      ),
      // IconButton: menangani tap + efek ripple + tooltip
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 22, color: foreground),
      ),
    );
  }
}

// AddButton: tombol bulat tambah (+) 36 visual, hit area 44
// Saat menu habis: latar disabled dan tidak bisa ditekan
class AddButton extends StatelessWidget {
  final VoidCallback? onTap; // null = menu habis
  const AddButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Semantics: label aksesibilitas untuk pembaca layar
    return Semantics(
      button: true,
      label: 'Tambah',
      // GestureDetector: area sentuh 44×44 di sekitar lingkaran 36
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque, // Area transparan tetap bisa ditekan
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            // Container: lingkaran 36 dengan ikon + putih
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: onTap == null ? AppColors.disabled : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

// ProductThumb: thumbnail produk radius 10 (sengaja tidak terlalu bulat)
// Foto sementara dari gambarMenu (assets/images) berdasarkan nama produk;
// bila tidak ada foto: placeholder tint + ikon. Nanti diganti foto Cloudinary
class ProductThumb extends StatelessWidget {
  final double size; // Ukuran sisi thumbnail
  final bool makanan; // true = ikon makanan, false = ikon cangkir
  final String? nama; // Nama produk untuk mencari foto di gambarMenu
  const ProductThumb({
    super.key,
    required this.size,
    this.makanan = false,
    this.nama,
  });

  @override
  Widget build(BuildContext context) {
    final gambar = gambarMenu[nama];
    if (gambar != null) {
      // ClipRRect: foto cover radius 10
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(gambar, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(10),
      ),
      // Icon: ikon placeholder berwarna primary, ukuran ~40% thumbnail
      child: Icon(
        makanan ? Icons.bakery_dining_outlined : Icons.coffee_outlined,
        color: AppColors.primary,
        size: size * 0.4,
      ),
    );
  }
}

// SegmentedPill: segmented control dengan wadah padding 4
// Dipakai di header Menu, Kustomisasi, dan Keranjang dengan warna berbeda
class SegmentedPill extends StatelessWidget {
  final List<String> options; // Label tiap pilihan
  final int selected; // Index pilihan aktif
  final ValueChanged<int> onChanged; // Callback saat pilihan diganti
  final Color background; // Latar wadah
  final Color selectedBackground; // Latar item terpilih
  final Color selectedForeground; // Warna teks item terpilih
  final Color foreground; // Warna teks item tidak terpilih
  final double itemHeight; // Tinggi item (36–40)
  final bool shadow; // Bayangan wadah
  const SegmentedPill({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.background,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.foreground,
    this.itemHeight = 40,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    // Container: wadah luar radius 16
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadow ? AppShadows.chip : null,
      ),
      // Row: item sama lebar (Expanded)
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              // GestureDetector: memilih item saat ditekan
              child: GestureDetector(
                onTap: () => onChanged(i),
                // AnimatedContainer: transisi halus saat warna latar berubah
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: BoxConstraints(minHeight: itemHeight),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == selected ? selectedBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    // Bayangan tipis: item terpilih tetap terpisah dari wadah
                    // walau warnanya dekat (mis. surface di atas fill)
                    boxShadow: i == selected ? AppShadows.chip : null,
                  ),
                  // FittedBox: perkecil teks sedikit bila tidak muat (mis. "Large +Rp4.000")
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      options[i],
                      textAlign: TextAlign.center,
                      style: ts(
                        13,
                        700,
                        color: i == selected ? selectedForeground : foreground,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// AppBottomBar: satu sheet putih berisi strip keranjang + navbar 4 tab
// Strip keranjang hanya tampil bila keranjang berisi
class AppBottomBar extends StatelessWidget {
  final int index; // Tab aktif
  final ValueChanged<int> onTap; // Callback saat tab ditekan
  const AppBottomBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // context.watch: rebuild saat isi keranjang berubah
    final cart = context.watch<CartProvider>();
    // Container: sheet putih radius atas 28 dengan bayangan navSheet
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppShadows.navSheet,
      ),
      // ClipRRect: memotong strip keranjang agar mengikuti radius atas
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Tinggi mengikuti isi
          children: [
            // Kondisi: strip keranjang hanya bila keranjang tidak kosong
            if (cart.totalItems > 0) _CartStrip(cart: cart),
            // NavigationBar: navbar M3 (gaya diatur di navigationBarTheme)
            NavigationBar(
              selectedIndex: index,
              onDestinationSelected: onTap,
              destinations: [
                NavigationDestination(
                  icon: _ikonNav(Icons.home_outlined),
                  selectedIcon: _ikonNav(Icons.home_rounded, aktif: true),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: _ikonNav(Icons.coffee_outlined),
                  selectedIcon: _ikonNav(Icons.coffee_rounded, aktif: true),
                  label: 'Menu',
                ),
                NavigationDestination(
                  icon: _ikonNav(Icons.receipt_long_outlined),
                  selectedIcon:
                      _ikonNav(Icons.receipt_long_rounded, aktif: true),
                  label: 'Pesanan',
                ),
                NavigationDestination(
                  icon: _ikonNav(Icons.person_outline_rounded),
                  selectedIcon: _ikonNav(Icons.person_rounded, aktif: true),
                  label: 'Akun',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// _ikonNav: ikon navbar 24 di dalam kotak 40×40.
// Aktif = lingkaran 40 primary + ikon putih (pengganti indikator M3 yang
// tingginya terkunci 32). Tidak aktif tetap 40×40 agar label tidak melompat.
Widget _ikonNav(IconData ikon, {bool aktif = false}) {
  return Container(
    width: 40,
    height: 40,
    decoration: aktif
        ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
        : null,
    child: Icon(ikon),
  );
}

// _CartStrip: strip keranjang tinggi 56 di atas navbar
// Ketuk → halaman Keranjang (keranjang BUKAN tab navbar)
class _CartStrip extends StatelessWidget {
  final CartProvider cart; // Data keranjang
  const _CartStrip({required this.cart});

  @override
  Widget build(BuildContext context) {
    // Material + InkWell: efek ripple saat strip ditekan
    return Material(
      color: AppColors.cartStrip,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage()),
        ),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // Container: kotak ikon troli 36×36 putih radius 12
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              // Text.rich: "3 item · Rp76.560" (total tebal ink)
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${cart.totalItems} item · ',
                    style: ts(13, 500, color: AppColors.muted),
                    children: [
                      TextSpan(text: rp(cart.total), style: ts(13, 800)),
                    ],
                  ),
                ),
              ),
              // Text: link "Lihat keranjang ›"
              Text('Lihat keranjang',
                  style: ts(13, 700, color: AppColors.primary)),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
