import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../main.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'customize_page.dart';

// MenuPage: layar Menu (DESIGN.md 3.3)
// Header collapsing + bar filter sticky + rekomendasi horizontal + daftar menu datar
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // State: _collapsed = header dalam bentuk ringkas (setelah scroll)
  bool _collapsed = false;
  // State: _kategoriAktif = index chip kategori terpilih
  int _kategoriAktif = 0;
  // State: _favorit = nama menu yang ditandai favorit
  final Set<String> _favorit = {'Caramel Latte'};
  // _kunciSeksi: GlobalKey tiap header kategori untuk scroll ke seksi
  final Map<String, GlobalKey> _kunciSeksi = {
    for (final k in kategoriMenu) k: GlobalKey(),
  };

  // _onScroll: ganti bentuk header berdasarkan offset scroll
  // Histeresis: collapse saat > 60, expand lagi saat < 8 (agar tidak berkedip)
  bool _onScroll(ScrollNotification n) {
    // Abaikan scroll horizontal (chip kategori & rekomendasi)
    if (n.metrics.axis != Axis.vertical) return false;
    final t = n.metrics.pixels;
    if (!_collapsed && t > 60) setState(() => _collapsed = true);
    if (_collapsed && t < 8) setState(() => _collapsed = false);
    return false;
  }

  // _pilihKategori: tandai chip lalu scroll ke seksi kategori tersebut
  void _pilihKategori(int i) {
    setState(() => _kategoriAktif = i);
    final ctx = _kunciSeksi[kategoriMenu[i]]!.currentContext;
    if (ctx != null) {
      // Scrollable.ensureVisible: geser list sampai seksi terlihat di atas
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0,
      );
    }
  }

  // _bukaKustomisasi: buka sheet Kustomisasi untuk produk terpilih
  void _bukaKustomisasi(Produk p) => bukaKustomisasi(context, p);

  @override
  Widget build(BuildContext context) {
    // context.watch: rebuild saat metode pesanan berubah
    final cart = context.watch<CartProvider>();

    // SafeArea: menghindari status bar; bawah dibiarkan (sheet navbar)
    return SafeArea(
      bottom: false,
      // Column: header (tidak ikut scroll) + area scroll
      child: Column(
        children: [
          // Padding: header padding 20 20 10
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            // AnimatedSize + AnimatedSwitcher: transisi halus expanded ↔ collapsed
            child: AnimatedSize(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _collapsed ? _headerRingkas(cart) : _headerLengkap(cart),
              ),
            ),
          ),
          // Expanded: area scroll mengisi sisa layar
          Expanded(
            // NotificationListener: memantau offset scroll untuk header
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: CustomScrollView(
                slivers: [
                  // PinnedHeaderSliver: bar filter tetap di atas saat scroll
                  PinnedHeaderSliver(child: _barFilter()),
                  // Seksi Rekomendasi (horizontal)
                  SliverToBoxAdapter(child: _seksiRekomendasi()),
                  // Daftar menu vertikal per kategori
                  for (final k in kategoriMenu.skip(1))
                    SliverToBoxAdapter(child: _seksiKategori(k)),
                  // Ruang bawah ≥ tinggi sheet navbar agar item terakhir terlihat
                  const SliverToBoxAdapter(child: SizedBox(height: 170)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _tombolKembali: kembali ke tab Beranda
  Widget _tombolKembali() => RoundIconButton(
    icon: Icons.chevron_left_rounded,
    tooltip: 'Kembali',
    onTap: () => NavigationPage.tab.value = NavigationPage.tabBeranda,
  );

  // _headerLengkap: header expanded (judul + segmented metode)
  Widget _headerLengkap(CartProvider cart) {
    return Column(
      key: const ValueKey(
        'lengkap',
      ), // Key berbeda agar AnimatedSwitcher beranimasi
      children: [
        Row(
          children: [
            _tombolKembali(),
            const SizedBox(width: 12),
            Expanded(child: Text('KopiKita', style: ts(20, 800, ls: -0.3))),
            RoundIconButton(
              icon: Icons.info_outline_rounded,
              tooltip: 'Info kedai',
              foreground: AppColors.primary,
              onTap: () => segeraHadir(context, 'Info kedai'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // SegmentedPill gaya Menu: terpilih latar primary, teks putih
        SegmentedPill(
          options: const ['Ambil Sendiri', 'Makan di Tempat'],
          selected: cart.makanDiTempat ? 1 : 0,
          onChanged: (i) => cart.setMakanDiTempat(i == 1),
          background: AppColors.surface,
          selectedBackground: AppColors.primary,
          selectedForeground: Colors.white,
          foreground: AppColors.ink,
          shadow: true,
        ),
      ],
    );
  }

  // _headerRingkas: header collapsed (metode + outlet + pill "Ubah")
  Widget _headerRingkas(CartProvider cart) {
    final metode = cart.makanDiTempat ? 'Makan di Tempat' : 'Ambil Sendiri';
    return Row(
      key: const ValueKey('ringkas'),
      children: [
        _tombolKembali(),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$metode · KopiKita',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(14, 800),
              ),
              const SizedBox(height: 2),
              Text(
                'Outlet Utama · 350 m dari kamu',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ts(12, 500, color: AppColors.muted),
              ),
            ],
          ),
        ),
        // Pill "Ubah": tukar metode pesanan
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => cart.setMakanDiTempat(!cart.makanDiTempat),
            child: Container(
              height: 44, // Hit area 44, tampilan pill 32
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Text('Ubah', style: ts(12, 800, color: AppColors.primary)),
            ),
          ),
        ),
      ],
    );
  }

  // _barFilter: chip kategori geser horizontal + tombol cari
  Widget _barFilter() {
    return Container(
      color: AppColors.bg, // Latar agar konten di belakangnya tertutup
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              // ListView horizontal: chip kategori
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kategoriMenu.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final aktif = i == _kategoriAktif;
                  return Center(
                    child: Material(
                      color: aktif ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => _pilihKategori(i),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.center,
                          child: Text(
                            kategoriMenu[i],
                            style: ts(
                              13,
                              700,
                              color: aktif ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          RoundIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Cari menu',
            foreground: AppColors.primary,
            onTap: () => segeraHadir(context, 'Pencarian menu'),
          ),
        ],
      ),
    );
  }

  // _seksiRekomendasi: judul + daftar horizontal kartu ringkas 276 lebar
  Widget _seksiRekomendasi() {
    return Column(
      key: _kunciSeksi['Rekomendasi'],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Text('Rekomendasi', style: ts(16, 800)),
        ),
        SizedBox(
          height: 104,
          // ListView horizontal: kartu berikutnya terpotong di tepi (bisa digeser)
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            clipBehavior: Clip.none,
            itemCount: rekomendasi.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = rekomendasi[i];
              // Container: kartu putih radius 20, padding 10, bayangan card
              return Container(
                width: 276,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    ProductThumb(size: 64, nama: p.nama),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(14, 700),
                          ),
                          Text(
                            p.deskripsi,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts(12, 500, color: AppColors.muted),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rp(p.harga),
                            style: ts(13, 800, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    AddButton(onTap: () => _bukaKustomisasi(p)),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // _seksiKategori: header kategori + baris datar tiap menu
  Widget _seksiKategori(String kategori) {
    final daftar = daftarMenu.where((p) => p.kategori == kategori).toList();
    // Column tanpa padding horizontal: baris menu selebar layar agar
    // highlight InkWell tidak mepet konten (padding 20 ada di dalam baris)
    return Column(
      key: _kunciSeksi[kategori],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header kategori: "Kopi" 16/800 + "3 menu" 12/600 muted
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(kategori, style: ts(16, 800)),
              const SizedBox(width: 8),
              Text(
                '${daftar.length} menu',
                style: ts(12, 600, color: AppColors.muted),
              ),
            ],
          ),
        ),
        // ...map: setiap produk jadi satu baris datar
        ...daftar.map(_barisMenu),
        const SizedBox(height: 12),
      ],
    );
  }

  // _barisMenu: baris datar (padding 14 0, garis bawah dividerList)
  Widget _barisMenu(Produk p) {
    final fav = _favorit.contains(p.nama);
    // Opacity: menu habis tampil 0.6
    return Opacity(
      opacity: p.habis ? 0.6 : 1,
      // InkWell selebar layar: highlight punya ruang 20 di kiri-kanan konten
      child: InkWell(
        onTap: p.habis ? null : () => _bukaKustomisasi(p),
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
                    ProductThumb(size: 84, makanan: p.makanan, nama: p.nama),
                    if (p.habis)
                      Positioned(
                        left: 6,
                        top: 6,
                        child: Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            'Habis',
                            style: ts(12, 700, color: Colors.white),
                          ),
                        ),
                      ),
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
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        tooltip: fav
                            ? 'Hapus dari favorit'
                            : 'Tambah ke favorit',
                        onPressed: () => setState(
                          () => fav
                              ? _favorit.remove(p.nama)
                              : _favorit.add(p.nama),
                        ),
                        icon: Icon(
                          fav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 22,
                          color: fav ? AppColors.promoLabel : AppColors.muted,
                        ),
                      ),
                    ),
                    AddButton(
                      onTap: p.habis ? null : () => _bukaKustomisasi(p),
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
