import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../services/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/favorit.dart';
import '../widgets/menu_row.dart';
import '../widgets/state_views.dart';

// FavoritePage: daftar menu favorit user (DESIGN.md 3.3b)
// Sumber: users/{uid}.favorit ([productId]) × products (realtime).
// Ketuk hati di sini → menu langsung hilang dari daftar.
class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  // State: _produk = stream produk; dibuat ulang saat "Coba lagi"
  Stream<List<Produk>> _produk = ProductRepository.stream();

  // _muatUlang: berlangganan ulang ke produk setelah error
  void _muatUlang() => setState(() => _produk = ProductRepository.stream());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // AppBar: sama dengan NotificationPage (latar bg, judul 18/800, titleSpacing 0)
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleSpacing: 0,
        title: Text('Favorit', style: ts(18, 800, ls: -0.3)),
      ),
      body: FavoritBuilder(
        builder: (context, favorit, siap) => StreamBuilder<List<Produk>>(
          stream: _produk,
          builder: (context, snap) => _isi(snap, favorit, siap),
        ),
      ),
    );
  }

  // _isi: memuat / error / kosong / daftar favorit
  Widget _isi(AsyncSnapshot<List<Produk>> snap, Set<String> favorit, bool siap) {
    // Tunggu daftar favorit pertama agar tidak sempat tampil "kosong"
    if (!siap && !snap.hasError) return const LoadingView();

    final keadaan = keadaanStream<List<Produk>>(
      snap,
      onCoba: _muatUlang,
      kosong: (d) => !d.any((p) => favorit.contains(p.id)),
      tampilanKosong: const EmptyView(
        icon: Icons.favorite_border_rounded,
        judul: 'Belum ada favorit',
        pesan: 'Ketuk ikon hati pada menu untuk menyimpannya di sini.',
      ),
    );
    if (keadaan != null) return keadaan;

    // Urutan mengikuti urutan produk di katalog
    final daftar = snap.requireData.where((p) => favorit.contains(p.id));
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        for (final p in daftar) BarisMenu(produk: p, favorit: true),
      ],
    );
  }
}
