import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'screens/account_page.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/menu_page.dart';
import 'screens/orders_page.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        // ChangeNotifierProvider: menyediakan instance CartProvider ke seluruh widget
        // CartProvider akan memberi tahu listener ketika data keranjang berubah
        ChangeNotifierProvider(create: (_) => CartProvider()),
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
    // MaterialApp: widget utama yang menyediakan konfigurasi aplikasi Material
    return MaterialApp(
      title: 'KopiKita', // Judul aplikasi
      debugShowCheckedModeBanner: false, // Menyembunyikan banner debug
      theme: buildAppTheme(), // Tema global dari lib/theme/app_theme.dart
      home: const LoginPage(), // Alur dimulai dari Login
    );
  }
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
          bottomNavigationBar: AppBottomBar(
            index: index,
            onTap: (i) => tab.value = i, // Ubah state tab saat ditekan
          ),
        );
      },
    );
  }
}
