// BarisMenu: baris datar satu menu (DESIGN.md 3.3), dipakai Menu, Cari, dan Favorit
import 'package:flutter/material.dart';

import '../models/produk.dart';
import '../screens/customize_page.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'favorit.dart';

// BarisMenu: thumbnail 84 · nama/deskripsi/harga · hati + tombol +
// Menu habis: opacity 0.6, badge "Habis", ketuk & tombol + dinonaktifkan.
class BarisMenu extends StatelessWidget {
  final Produk produk; // Data menu
  final bool favorit; // true = sudah ditandai favorit
  const BarisMenu({super.key, required this.produk, required this.favorit});

  @override
  Widget build(BuildContext context) {
    final p = produk;
    // Opacity: menu habis tampil 0.6
    return Opacity(
      opacity: p.habis ? 0.6 : 1,
      // InkWell selebar layar: highlight punya ruang 20 di kiri-kanan konten
      child: InkWell(
        onTap: p.habis ? null : () => bukaKustomisasi(context, p),
        // Padding 20 di dalam InkWell: konten & garis pemisah tetap inset 20
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.dividerList)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stack: thumbnail 84 + badge "Habis" di pojok kiri atas
                Stack(
                  children: [
                    ProductThumb(
                      size: 84,
                      makanan: p.makanan,
                      nama: p.nama,
                      url: p.gambarUrl,
                    ),
                    if (p.habis)
                      const Positioned(left: 6, top: 6, child: HabisBadge()),
                  ],
                ),
                const SizedBox(width: 14),
                // Expanded: nama, deskripsi, dan harga
                Expanded(
                  child: SizedBox(
                    height: 84,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nama, style: ts(14, 700)),
                        const SizedBox(height: 2),
                        Text(
                          p.deskripsi,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: ts(
                            12,
                            500,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          rp(p.harga),
                          style: ts(14, 800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                // Kolom kanan: tombol hati di atas, tombol + di bawah
                Column(
                  children: [
                    TombolFavorit(produk: p, aktif: favorit),
                    AddButton(
                      onTap: p.habis ? null : () => bukaKustomisasi(context, p),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
