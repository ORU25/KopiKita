// Widget bersama yang dipakai di banyak layar (DESIGN.md bagian 2)
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../providers/cart_provider.dart';
import '../screens/cart_page.dart';
import '../theme/app_theme.dart';

// segeraHadir: menampilkan SnackBar untuk fitur yang belum didesain
void segeraHadir(BuildContext context, String fitur) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$fitur segera hadir')));
}

// rp: singkatan formatRupiah agar kode UI lebih ringkas
String rp(int v) => CartProvider.formatRupiah(v);

// PrimaryButton: tombol utama tinggi 52, radius 16, latar primary, teks putih 15/700
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
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
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color background;
  final Color foreground;
  final bool shadow;
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
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: shadow ? AppShadows.chip : null,
      ),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, size: 22, color: foreground),
      ),
    );
  }
}

// AddButton: tombol bulat tambah (+) 36 visual, hit area 44
class AddButton extends StatelessWidget {
  final VoidCallback? onTap;
  const AddButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tambah',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
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

// HabisBadge: lencana "Habis" (tinggi 22, latar ink, teks putih 12/700)
class HabisBadge extends StatelessWidget {
  const HabisBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text('Habis', style: ts(12, 700, color: Colors.white)),
    );
  }
}

// ProductThumb: thumbnail produk radius 10.
// PERBAIKAN FINAL FLUTTER WEB:
// Menggunakan imageBuilder pada CachedNetworkImage. Ini memastikan gambar
// digambar menggunakan DecorationImage (sama seperti aset lokal) sehingga
// CanvasKit tidak merendernya sebagai kotak hitam saat kembali dari navigasi.
class ProductThumb extends StatelessWidget {
  final double size;
  final bool makanan;
  final String? nama;
  final String? url;
  const ProductThumb({
    super.key,
    required this.size,
    this.makanan = false,
    this.nama,
    this.url,
  });

  Widget _placeholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        makanan ? Icons.bakery_dining_outlined : Icons.coffee_outlined,
        color: AppColors.primary,
        size: size * 0.4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foto = url;

    // Jalur 1: URL Cloudinary (Gambar dari Web Admin)
    if (foto != null && foto.isNotEmpty) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: size,
            height: size,
            color: AppColors.tint, // Latar cadangan
            child: CachedNetworkImage(
              imageUrl: foto,
              width: size,
              height: size,
              // Matikan transisi agar tidak memicu bug layer transparan di Web
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, _) => _placeholder(),
              errorWidget: (_, _, _) => _placeholder(),
              // imageBuilder: Menggambar gambar dengan DecorationImage.
              // Sangat stabil di Flutter Web (tidak jadi hitam).
              imageBuilder: (context, imageProvider) => Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Jalur 2: Asset lokal (Data Dummy)
    final gambar = gambarMenu[nama];
    if (gambar != null) {
      return RepaintBoundary(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.tint,
            borderRadius: BorderRadius.circular(10),
            image: DecorationImage(
              image: AssetImage(gambar),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    // Jalur 3: Tanpa gambar
    return _placeholder();
  }
}

// SegmentedPill: segmented control dengan wadah padding 4
class SegmentedPill extends StatelessWidget {
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;
  final Color background;
  final Color selectedBackground;
  final Color selectedForeground;
  final Color foreground;
  final double itemHeight;
  final bool shadow;
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: shadow ? AppShadows.chip : null,
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  constraints: BoxConstraints(minHeight: itemHeight),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: i == selected ? selectedBackground : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == selected ? AppShadows.chip : null,
                  ),
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
class AppBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const AppBottomBar({super.key, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: AppShadows.navSheet,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cart.totalItems > 0) _CartStrip(cart: cart),
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
                  selectedIcon: _ikonNav(Icons.receipt_long_rounded, aktif: true),
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

class _CartStrip extends StatelessWidget {
  final CartProvider cart;
  const _CartStrip({required this.cart});

  @override
  Widget build(BuildContext context) {
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