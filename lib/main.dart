import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/dependensi.dart';
import 'domain/repositories/app_settings_repository.dart';
import 'firebase_options.dart';
import 'viewmodels/auth_view_model.dart';
import 'screens/account_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/menu_page.dart';
import 'screens/orders_page.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- SharedPreferencesWithCache dibuat SEBELUM runApp ---
  // Agar tema dan pengaturan lain langsung benar sejak layar pertama (tanpa berkedip)
  final SharedPreferencesWithCache prefs = await SharedPreferencesWithCache.create(
    cacheOptions: SharedPreferencesWithCacheOptions(
      allowList: AppSettingsRepository.allKeys,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // SharedPreferencesWithCache dititipkan ke provider tree
        Provider<SharedPreferencesWithCache>.value(value: prefs),
        // Repository, use case & AuthViewModel (lihat config/dependensi.dart)
        ...buatPenyedia(),
      ],
      child: const MainApp(),
    ),
  );
}

// MainApp: widget root aplikasi yang mengatur MaterialApp dan tema
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.select<AuthViewModel, String?>((vm) => vm.uid);
    return MaterialApp(
      title: 'KopiKita',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // ViewModel milik sesi dipasang DI ATAS Navigator agar semua route
      // (Keranjang, Kustomisasi, dll.) bisa membacanya. Key = uid: ganti akun
      // → ViewModel & tumpukan halaman dibuat ulang (keranjang tidak terbawa).
      builder: (context, child) => uid == null
          ? child!
          : MultiProvider(
              key: ValueKey(uid),
              providers: buatPenyediaSesi(),
              child: child!,
            ),
      home: FutureBuilder(
        future: _splashSelesai,
        builder: (context, snap) => snap.connectionState == ConnectionState.done
            ? const AuthGate()
            : const SplashScreen(),
      ),
    );
  }
}

// Dibuat sekali (top-level final = lazy, satu kali) agar rebuild tidak mengulang splash.
final _splashSelesai = Future<void>.delayed(const Duration(seconds: 2));

// SplashScreen: gambar penuh layar (sudah berisi logo + "Loading...").
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SizedBox.expand(
        child: Image.asset('assets/splashScreen.png', fit: BoxFit.cover),
      ),
    );
  }
}

// AuthGate: menentukan layar awal dari AuthViewModel.
// Belum login → LoginPage. Sudah login → NavigationPage (Beranda).
// Pemantau status pesanan & push dinyalakan oleh AuthViewModel, bukan di sini.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return switch (context.watch<AuthViewModel>().status) {
      StatusAuth.memeriksa => const SplashScreen(),
      StatusAuth.keluar => const LoginPage(),
      StatusAuth.masuk => const _BerandaSetelahMasuk(),
    };
  }
}

// _BerandaSetelahMasuk: NavigationPage yang selalu dibuka di tab Beranda.
class _BerandaSetelahMasuk extends StatefulWidget {
  const _BerandaSetelahMasuk();

  @override
  State<_BerandaSetelahMasuk> createState() => _BerandaSetelahMasukState();
}

class _BerandaSetelahMasukState extends State<_BerandaSetelahMasuk> {
  @override
  void initState() {
    super.initState();
    NavigationPage.tab.value = NavigationPage.tabBeranda;
  }

  @override
  Widget build(BuildContext context) => const NavigationPage();
}

// NavigationPage = PEMBUNGKUS BOTTOM NAVIGATION
// 4 tab: Beranda, Menu, Pesanan, Akun (Keranjang tampil sebagai strip, bukan tab)
class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  // State: tab menyimpan indeks tab yang sedang aktif
  // ValueNotifier<int> membuat state reaktif tanpa perlu StatefulWidget
  // Dibuat publik agar halaman lain bisa pindah tab (mis. Beranda → Menu)
  static final ValueNotifier<int> tab = ValueNotifier<int>(0);

  // Konstanta indeks tab agar tidak memakai angka "ajaib"
  static const tabBeranda = 0;
  static const tabMenu = 1;
  static const tabPesanan = 2;
  static const tabAkun = 3;

  // State: _halaman menyimpan daftar halaman yang akan ditampilkan
  static const List<Widget> _halaman = [
    HomePage(), // Halaman Beranda
    MenuPage(), // Halaman Menu
    OrdersPage(), // Halaman Pesanan (Aktif & Riwayat)
    AccountPage(), // Halaman Akun
  ];

  void _pindahTab(int i) {
    if (i == tabPesanan && tab.value != tabPesanan) {
      OrdersPage.mintaAktif();
    }
    tab.value = i;
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder: membangun ulang ketika tab berubah
    return ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, index, _) {
        // Scaffold: kerangka dasar halaman dengan body dan bottomNavigationBar
        return Scaffold(
          extendBody: true, // Konten berada di belakang sheet navbar
          // IndexedStack: menampilkan satu halaman berdasarkan index,
          // tetapi tetap menjaga state semua halaman di dalamnya
          body: IndexedStack(index: index, children: _halaman),
          // AppBottomBar: strip keranjang + navbar (lib/widgets/common.dart)
          bottomNavigationBar: AppBottomBar(index: index, onTap: _pindahTab),
        );
      },
    );
  }
}
