import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/app_settings_repository.dart';
import '../data/local/cart_local_repository.dart';
import '../data/local/database_service.dart';
import '../data/local/product_cache_repository.dart';
import '../data/repositories/auth_repository_firebase.dart';
import '../data/repositories/favorit_repository_firestore.dart';
import '../data/repositories/foto_repository_cloudinary.dart';
import '../data/repositories/menu_config_repository_firestore.dart';
import '../data/repositories/notifikasi_repository_firestore.dart';
import '../data/repositories/order_repository_firestore.dart';
import '../data/repositories/perangkat_asli.dart';
import '../data/repositories/product_repository_firestore.dart';
import '../data/repositories/profil_repository_firestore.dart';
import '../data/repositories/push_repository_fcm.dart';
import '../data/repositories/voucher_repository_firestore.dart';
import '../domain/repositories/app_settings_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/favorit_repository.dart';
import '../domain/repositories/foto_repository.dart';
import '../domain/repositories/menu_config_repository.dart';
import '../domain/repositories/notifikasi_repository.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/repositories/perangkat_repository.dart';
import '../domain/repositories/product_repository.dart';
import '../domain/repositories/profil_repository.dart';
import '../domain/repositories/push_repository.dart';
import '../domain/repositories/voucher_repository.dart';
import '../domain/use_cases/batalkan_pesanan.dart';
import '../domain/use_cases/buat_pesanan.dart';
import '../domain/use_cases/pantau_status_pesanan.dart';
import '../domain/use_cases/ubah_profil.dart';
import '../viewmodels/auth_view_model.dart';
import '../viewmodels/cart_view_model.dart';
import '../viewmodels/favorit_view_model.dart';
import '../viewmodels/jarak_kedai_view_model.dart';
import '../viewmodels/notifikasi_view_model.dart';
import '../viewmodels/pesanan_view_model.dart';
import '../viewmodels/produk_view_model.dart';
import '../viewmodels/profil_view_model.dart';
import '../viewmodels/settings_view_model.dart';
import '../viewmodels/voucher_saya_view_model.dart';

// AKAR KOMPOSISI (composition root): SATU-SATUNYA tempat yang tahu
// implementasi mana yang dipakai. Jenis yang dititipkan ditulis sebagai
// KONTRAK (mis. ProductRepository), bukan implementasinya. Untuk beralih ke
// data palsu cukup ganti di sini (atau di tes: Provider<...>.value(value: palsu)).
//
//   View (screens/, widgets/) ──watch/read──▶ ViewModel (viewmodels/)
//   ViewModel ──▶ use case / kontrak repository (domain/)
//   data/ ──implements──▶ kontrak domain/

/// buatPenyedia: repository, use case, dan AuthViewModel (seumur aplikasi).
List<SingleChildWidget> buatPenyedia() {
  return [
    // ---------- Local Storage Services ----------
    Provider<DatabaseService>(
      create: (_) => DatabaseService(),
      dispose: (_, db) => db.tutup(),
    ),
    // SharedPreferencesWithCache dibuat di main() sebelum runApp
    // dan dititipkan ke sini via Provider.value (lihat main.dart)

    // ---------- Lapisan data (di balik kontrak domain) ----------
    Provider<AuthRepository>(create: (_) => AuthRepositoryFirebase()),
    Provider<ProfilRepository>(create: (_) => ProfilRepositoryFirestore()),
    Provider<ProductRepository>(create: (_) => ProductRepositoryFirestore()),
    Provider<OrderRepository>(create: (_) => OrderRepositoryFirestore()),
    Provider<FavoritRepository>(create: (_) => FavoritRepositoryFirestore()),
    Provider<VoucherRepository>(create: (_) => VoucherRepositoryFirestore()),
    Provider<NotifikasiRepository>(
      create: (_) => NotifikasiRepositoryFirestore(),
    ),
    Provider<MenuConfigRepository>(
      create: (_) => MenuConfigRepositoryFirestore(),
    ),
    Provider<FotoRepository>(create: (_) => FotoRepositoryCloudinary()),
    Provider<PushRepository>(create: (_) => PushRepositoryFcm()),
    // Fitur perangkat (Pertemuan 13): lokasi, kamera/galeri, Pengaturan
    Provider<LayananLokasi>(create: (_) => const LayananLokasiGeolocator()),
    Provider<PemilihFoto>(create: (_) => PemilihFotoImagePicker()),
    Provider<PengaturanPerangkat>(
      create: (_) => const PengaturanPerangkatAsli(),
    ),

    // ---------- Local Repositories ----------
    Provider<AppSettingsRepository>(
      create: (c) => AppSettingsRepositoryImpl(c.read<SharedPreferencesWithCache>()),
    ),
    Provider<CartLocalRepository>(
      create: (c) => CartLocalRepository(c.read<DatabaseService>()),
    ),
    Provider<ProductCacheRepository>(
      create: (c) => ProductCacheRepository(c.read<DatabaseService>()),
    ),

    // ---------- Use case (domain) ----------
    Provider(create: (c) => BatalkanPesanan(c.read<OrderRepository>())),
    Provider(create: (c) => BuatPesanan(c.read<OrderRepository>())),
    Provider(
      create: (c) =>
          UbahProfil(c.read<ProfilRepository>(), c.read<FotoRepository>()),
    ),
    Provider(
      create: (c) => PantauStatusPesanan(
        c.read<OrderRepository>(),
        c.read<NotifikasiRepository>(),
      ),
    ),

    // ---------- ViewModel seumur aplikasi ----------
    ChangeNotifierProvider(
      lazy: false,
      create: (c) => AuthViewModel(
        c.read<AuthRepository>(),
        c.read<PushRepository>(),
        c.read<PantauStatusPesanan>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => SettingsViewModel(c.read<AppSettingsRepository>()),
    ),
  ];
}

/// buatPenyediaSesi: ViewModel milik SATU sesi login. Dibuat ulang setiap
/// user berganti (lihat MainApp) sehingga data akun lama tidak terbawa.
List<SingleChildWidget> buatPenyediaSesi() {
  return [
    ChangeNotifierProvider(create: buatCartViewModel),
    ChangeNotifierProvider(
      create: (c) => JarakKedaiViewModel(
        c.read<LayananLokasi>(),
        c.read<PengaturanPerangkat>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => ProdukViewModel(
        c.read<ProductRepository>(),
        c.read<ProductCacheRepository>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => FavoritViewModel(c.read<FavoritRepository>()),
    ),
    ChangeNotifierProvider(
      create: (c) => ProfilViewModel(
        c.read<ProfilRepository>(),
        c.read<UbahProfil>(),
        c.read<PushRepository>(),
        c.read<PemilihFoto>(),
        c.read<PengaturanPerangkat>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => NotifikasiViewModel(c.read<NotifikasiRepository>()),
    ),
    ChangeNotifierProvider(
      create: (c) => PesananAktifViewModel(
        c.read<OrderRepository>(),
        c.read<BatalkanPesanan>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (c) => RiwayatPesananViewModel(c.read<OrderRepository>()),
    ),
    ChangeNotifierProvider(
      create: (c) => VoucherSayaViewModel(
        c.read<ProfilRepository>(),
        c.read<VoucherRepository>(),
      ),
    ),
  ];
}

/// buatCartViewModel: dipakai juga Keranjang "Pesan lagi" (keranjang terpisah).
CartViewModel buatCartViewModel(BuildContext c) => CartViewModel(
  c.read<VoucherRepository>(),
  c.read<MenuConfigRepository>(),
  c.read<BuatPesanan>(),
  c.read<CartLocalRepository>(),
  c.read<ProductCacheRepository>(),
);
