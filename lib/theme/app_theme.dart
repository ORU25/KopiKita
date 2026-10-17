import 'package:flutter/material.dart';

// AppColors: token warna dari kopikita-design/design/DESIGN.md bagian 1
// Semua widget WAJIB memakai token ini, jangan menulis hex langsung di widget
class AppColors {
  static const primary = Color(0xFF6B3216); // Tombol utama, harga, ikon aktif
  static const primaryDeco = Color(0xFF8A4720); // Lingkaran dekoratif kartu promo cokelat
  static const caramel = Color(0xFFC47A3A); // Aksen sekunder, status "sedang berjalan"
  static const caramelDeco = Color(0xFFD9954F); // Lingkaran dekoratif kartu promo karamel
  static const tintDeco = Color(0xFFE6D0B6); // Lingkaran dekoratif kartu promo krem
  static const promoLabel = Color(0xFF9A5A1C); // Link "Lihat semua", hati favorit aktif
  static const ink = Color(0xFF2B1810); // Teks utama
  static const textSecondary = Color(0xFF5A4436); // Label sekunder
  static const muted = Color(0xFF7A6355); // Teks deskripsi/meta, ikon tidak aktif
  static const disabled = Color(0xFFB9A89B); // Tombol + untuk menu habis
  static const bg = Color(0xFFFFFFFF); // Latar halaman (putih)
  static const surface = Color(0xFFFCF9F5); // Card, sheet, navbar (cokelat muda)
  static const fill = Color(0xFFF3EADF); // Isi input, segmented, stepper
  static const tint = Color(0xFFF1E4D4); // Indikator navbar, thumbnail placeholder, avatar
  static const cartStrip = Color(0xFFF6ECE0); // Latar strip keranjang
  static const cream = Color(0xFFFBEFE0); // Teks terang di atas latar cokelat tua
  static const divider = Color(0xFFEDE3D8); // Garis pemisah umum
  static const dividerSoft = Color(0xFFF0E7DC); // Pemisah di dalam card
  static const dividerList = Color(0xFFE9DED2); // Pemisah baris daftar menu
  static const outline = Color(0xFFE6D9CB); // Border tombol stepper, tombol Google
  static const danger = Color(0xFFB3261E); // Aksi berbahaya: Keluar
  static const pending = Color(0xFFD9CABB); // Titik status belum tercapai, dot slider
}

// AppShadows: bayangan lembut bernuansa cokelat (DESIGN.md bagian 1 "Bayangan")
class AppShadows {
  // card: bayangan card biasa
  static const card = [
    BoxShadow(color: Color(0x0D3C1E0A), blurRadius: 10, offset: Offset(0, 2)),
  ];
  // float: bayangan card melayang di Beranda & Login
  static const float = [
    BoxShadow(color: Color(0x122B1810), blurRadius: 20, offset: Offset(0, 6)),
  ];
  // navSheet: bayangan sheet navbar (mengarah ke atas)
  static const navSheet = [
    BoxShadow(color: Color(0x143C1E0A), blurRadius: 24, offset: Offset(0, -6)),
  ];
  // chip: bayangan tombol bulat putih (header Menu)
  static const chip = [
    BoxShadow(color: Color(0x0D3C1E0A), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

// ts: helper membuat TextStyle Plus Jakarta Sans
// Parameter:
//   size  = ukuran font (minimal 12 sesuai desain)
//   w     = tebal font (400–800)
//   color = warna teks (default ink)
//   ls    = letter-spacing (opsional)
//   height= line-height (opsional)
// fontVariations dipakai karena font yang dipakai adalah font VARIABEL,
// sehingga sumbu 'wght' harus diatur agar tebal font benar-benar berubah
TextStyle ts(
  double size,
  int w, {
  Color color = AppColors.ink,
  double? ls,
  double? height,
}) {
  return TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: size,
    fontWeight: FontWeight.values[(w ~/ 100) - 1], // 700 → FontWeight.w700
    fontVariations: [FontVariation('wght', w.toDouble())],
    color: color,
    letterSpacing: ls,
    height: height,
  );
}

// buildAppTheme: ThemeData global aplikasi (DESIGN.md bagian 4)
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true, // Mengaktifkan Material 3
    fontFamily: 'PlusJakartaSans', // Font default aplikasi
    scaffoldBackgroundColor: AppColors.bg, // Latar semua halaman
    dividerColor: AppColors.divider, // Warna garis pemisah default
    // ColorScheme: skema warna sesuai token desain
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.caramel,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
      outline: AppColors.outline,
    ),
    // InputDecorationTheme: input tinggi 52, radius 14, latar fill,
    // saat fokus latar putih (bg) + border 1.5 primary (lihat Login)
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // WidgetStateColor: warna isi berubah sesuai state (fokus/tidak)
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? AppColors.bg
            : AppColors.fill,
      ),
      hintStyle: ts(14, 500, color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    // NavigationBarThemeData: navbar M3 (DESIGN.md bagian 2)
    navigationBarTheme: NavigationBarThemeData(
      height: 84, // Tinggi baris navbar
      backgroundColor: AppColors.surface, // Latar cokelat muda
      surfaceTintColor: Colors.transparent, // Tanpa surface tint agar warna bersih
      elevation: 0,
      // Indikator M3 disembunyikan; lingkaran aktif 40 digambar oleh _ikonNav
      // (lib/widgets/common.dart). Bentuk lingkaran tetap dipakai untuk ripple.
      indicatorColor: Colors.transparent,
      indicatorShape: const CircleBorder(),
      // overlayColor: ripple lembut bernuansa cokelat saat tab ditekan
      overlayColor: WidgetStatePropertyAll(
        AppColors.primary.withValues(alpha: .08),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      // labelTextStyle: aktif = primary 700, tidak aktif = muted 600
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? ts(12, 700, color: AppColors.primary)
            : ts(12, 600, color: AppColors.muted),
      ),
      // iconTheme: ikon 24, aktif putih (di atas pill cokelat), tidak aktif muted
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? Colors.white
              : AppColors.muted,
        ),
      ),
    ),
    // SnackBarThemeData: snackbar mengambang berwarna ink
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: ts(13, 600, color: AppColors.cream),
    ),
  );
}
