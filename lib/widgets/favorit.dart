// Widget favorit: pembaca daftar favorit + tombol hati (DESIGN.md 3.3)
import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../services/favorit_repository.dart';
import '../theme/app_theme.dart';

// FavoritBuilder: berlangganan ke users/{uid}.favorit dan membangun ulang
// anaknya saat daftar berubah. `siap` = false sampai data pertama datang
// (agar layar Favorit tidak sempat menampilkan "kosong" sesaat).
class FavoritBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, Set<String> favorit, bool siap)
      builder;
  const FavoritBuilder({super.key, required this.builder});

  @override
  State<FavoritBuilder> createState() => _FavoritBuilderState();
}

class _FavoritBuilderState extends State<FavoritBuilder> {
  // Stream dibuat sekali di State (bukan di build) agar tidak berlangganan ulang
  final Stream<Set<String>> _stream = FavoritRepository.stream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Set<String>>(
      stream: _stream,
      builder: (context, snap) =>
          widget.builder(context, snap.data ?? const <String>{}, snap.hasData),
    );
  }
}

// TombolFavorit: ikon hati 44×44; aktif terisi promoLabel, tidak aktif garis muted.
// Ketuk → simpan/hapus dari users.favorit. Gagal → SnackBar.
class TombolFavorit extends StatelessWidget {
  final Produk produk; // Produk yang ditandai
  final bool aktif; // true = sudah favorit
  const TombolFavorit({super.key, required this.produk, required this.aktif});

  Future<void> _ubah(BuildContext context) async {
    try {
      await FavoritRepository.set(produk.id, favorit: !aktif);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan favorit. Coba lagi.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        tooltip: aktif ? 'Hapus dari favorit' : 'Tambah ke favorit',
        onPressed: () => _ubah(context),
        icon: Icon(
          aktif ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 22,
          color: aktif ? AppColors.promoLabel : AppColors.muted,
        ),
      ),
    );
  }
}
