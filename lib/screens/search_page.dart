import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../services/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/favorit.dart';
import '../widgets/menu_row.dart';
import '../widgets/state_views.dart';

// SearchPage: layar Cari menu (DESIGN.md 3.3a)
// Filter nama dilakukan LOKAL dari daftar produk yang sudah dimuat Menu (`awal`),
// lalu tetap mengikuti perubahan realtime (mis. status Habis) dari stream produk.
// Tidak ada query Firestore per ketikan.
class SearchPage extends StatefulWidget {
  final List<Produk>? awal; // Daftar yang sudah dimuat Menu (tampil instan)
  const SearchPage({super.key, this.awal});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // _ctrl: mengontrol isi kolom pencarian
  final TextEditingController _ctrl = TextEditingController();
  // State: _kata = kata kunci (sudah di-trim dan huruf kecil)
  String _kata = '';
  // State: _produk = stream produk; dibuat ulang saat "Coba lagi"
  Stream<List<Produk>> _produk = ProductRepository.stream();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // _muatUlang: berlangganan ulang ke produk setelah error
  void _muatUlang() => setState(() => _produk = ProductRepository.stream());

  // _hapus: kosongkan kolom pencarian
  void _hapus() {
    _ctrl.clear();
    setState(() => _kata = '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      // SafeArea: menghindari status bar; bawah mengikuti keyboard/gesture bar
      body: SafeArea(
        child: Column(
          children: [
            // Header: tombol kembali bulat 44 + kolom cari 52 (radius 14, latar fill)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  RoundIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Kembali',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      style: ts(14, 500),
                      onChanged: (v) =>
                          setState(() => _kata = v.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Cari menu',
                        prefixIcon: const Icon(Icons.search_rounded),
                        // Tombol hapus 44×44 hanya saat ada teks
                        suffixIcon: _kata.isEmpty && _ctrl.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Hapus',
                                onPressed: _hapus,
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hasil: daftar favorit + stream produk (data awal = daftar Menu)
            Expanded(
              child: FavoritBuilder(
                builder: (context, favorit, _) => StreamBuilder<List<Produk>>(
                  stream: _produk,
                  initialData: widget.awal,
                  builder: (context, snap) => _hasil(snap, favorit),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // _hasil: memuat / error / hasil filter nama
  Widget _hasil(AsyncSnapshot<List<Produk>> snap, Set<String> favorit) {
    final keadaan = keadaanStream<List<Produk>>(
      snap,
      onCoba: _muatUlang,
      kosong: (_) => false,
      tampilanKosong: const SizedBox.shrink(),
    );
    if (keadaan != null) return keadaan;

    // Belum mengetik: ajakan mencari
    if (_kata.isEmpty) {
      return const EmptyView(
        icon: Icons.search_rounded,
        judul: 'Cari menu favoritmu',
        pesan: 'Ketik nama menu, misalnya "latte" atau "croissant".',
      );
    }

    // Filter lokal: nama mengandung kata kunci (tanpa membedakan huruf besar/kecil)
    final hasil = snap.requireData
        .where((p) => p.nama.toLowerCase().contains(_kata))
        .toList();
    if (hasil.isEmpty) {
      return const EmptyView(
        icon: Icons.search_off_rounded,
        judul: 'Menu tidak ditemukan',
        pesan: 'Coba kata kunci lain atau periksa ejaannya.',
      );
    }

    return ListView(
      // Tutup keyboard saat daftar digeser
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text(
            '${hasil.length} menu ditemukan',
            style: ts(12, 600, color: AppColors.muted),
          ),
        ),
        for (final p in hasil)
          BarisMenu(produk: p, favorit: favorit.contains(p.id)),
      ],
    );
  }
}
