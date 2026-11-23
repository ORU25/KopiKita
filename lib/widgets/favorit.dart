// Widget favorit: pembaca daftar favorit + tombol hati (DESIGN.md 3.3)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/entities/produk.dart';
import '../theme/app_theme.dart';
import '../viewmodels/favorit_view_model.dart';

// FavoritBuilder: membangun ulang anaknya saat daftar favorit (ViewModel)
// berubah. `siap` = false sampai data pertama datang (agar layar Favorit
// tidak sempat menampilkan "kosong" sesaat).
class FavoritBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Set<String> favorit, bool siap)
  builder;
  const FavoritBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoritViewModel>(
      builder: (context, vm, _) => builder(context, vm.ids, vm.siap),
    );
  }
}

// TombolFavorit: ikon hati 44×44; aktif terisi promoLabel, tidak aktif garis muted.
// Ketuk → FavoritViewModel.toggle. Gagal → SnackBar.
class TombolFavorit extends StatelessWidget {
  final Produk produk; // Produk yang ditandai
  final bool aktif; // true = sudah favorit
  const TombolFavorit({super.key, required this.produk, required this.aktif});

  Future<void> _ubah(BuildContext context) async {
    final galat = await context.read<FavoritViewModel>().toggle(produk.id);
    if (galat == null || !context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(galat)));
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
