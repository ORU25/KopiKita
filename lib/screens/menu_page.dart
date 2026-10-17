import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/produk.dart';
import '../providers/cart_provider.dart';
import '../services/product_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/favorit.dart';
import '../widgets/menu_row.dart';
import '../widgets/state_views.dart';
import 'customize_page.dart';
import 'search_page.dart';

// MenuPage: layar Menu (DESIGN.md 3.3)
// Header collapsing + bar filter sticky + rekomendasi horizontal + daftar menu datar
// Data produk realtime dari Firestore (products) lewat ProductRepository.
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
  // State: _produk = stream produk; dibuat ulang saat "Coba lagi"
  Stream<List<Produk>> _produk = ProductRepository.stream();
  // _kunciSeksi: GlobalKey tiap header kategori untuk scroll ke seksi
  final Map<String, GlobalKey> _kunciSeksi = {
    for (final k in kategoriMenu) k: GlobalKey(),
  };

  // _muatUlang: berlangganan ulang ke produk setelah error
  void _muatUlang() => setState(() => _produk = ProductRepository.stream());

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

  // _bukaCari: buka layar Cari; daftar yang sudah dimuat dikirim sebagai data awal
  void _bukaCari(List<Produk>? daftar) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SearchPage(awal: daftar)),
    );
  }

  // _bukaInfoKedai: tampilkan alert berisi alamat & jam operasional kedai
  void _bukaInfoKedai() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text('Info Kedai', style: ts(18, 800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Jl. Universitas Mulawarman',
                    style: ts(14, 600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time_rounded,
                    size: 20, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '10:00 – 23:00 WITA',
                    style: ts(14, 600),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup',
                style: ts(13, 800, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

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
            // FavoritBuilder: daftar favorit user (tombol hati di tiap baris)
            child: FavoritBuilder(
              builder: (context, favorit, _) => StreamBuilder<List<Produk>>(
                stream: _produk,
                builder: (context, snap) => _areaScroll(snap, favorit),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _areaScroll: bar filter selalu tampil; isinya memuat / error / kosong / daftar menu
  Widget _areaScroll(AsyncSnapshot<List<Produk>> snap, Set<String> favorit) {
    // keadaan: tampilan memuat/error/kosong; null bila daftar menu siap tampil
    final keadaan = keadaanStream<List<Produk>>(
      snap,
      onCoba: _muatUlang,
      kosong: (d) => d.isEmpty,
      tampilanKosong: const EmptyView(
        icon: Icons.coffee_outlined,
        judul: 'Menu belum tersedia',
        pesan: 'Kedai belum menambahkan menu. Coba lagi nanti.',
      ),
    );
    final data = snap.data ?? const <Produk>[];

    // NotificationListener: memantau offset scroll untuk header
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: CustomScrollView(
        slivers: [
          // PinnedHeaderSliver: bar filter tetap di atas saat scroll
          PinnedHeaderSliver(child: _barFilter(snap.data)),
          if (keadaan != null)
            // SliverFillRemaining: keadaan mengisi sisa area di bawah bar filter
            SliverFillRemaining(hasScrollBody: false, child: keadaan)
          else ...[
            // Seksi Rekomendasi (horizontal)
            SliverToBoxAdapter(
              child: _seksiRekomendasi(
                data.where((p) => p.rekomendasi).toList(),
              ),
            ),
            // Daftar menu vertikal per kategori
            for (final k in kategoriMenu.skip(1))
              SliverToBoxAdapter(
                child: _seksiKategori(
                  k,
                  data.where((p) => p.kategori == k).toList(),
                  favorit,
                ),
              ),
            // Ruang bawah ≥ tinggi sheet navbar agar item terakhir terlihat
            const SliverToBoxAdapter(child: SizedBox(height: 170)),
          ],
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
              onTap: _bukaInfoKedai, // ← Alert info kedai
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
  Widget _barFilter(List<Produk>? daftar) {
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
            onTap: () => _bukaCari(daftar),
          ),
        ],
      ),
    );
  }

  // _seksiRekomendasi: judul + daftar horizontal kartu ringkas 276 lebar
  // Hanya produk berflag rekomendasi; tanpa produk → seksi disembunyikan
  Widget _seksiRekomendasi(List<Produk> daftar) {
    if (daftar.isEmpty) return const SizedBox.shrink();
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
            itemCount: daftar.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = daftar[i];
              // Container: kartu putih radius 20, padding 10, bayangan card
              // Opacity: menu habis tampil 0.6
              return Opacity(
                key: ValueKey(p.id),
                opacity: p.habis ? 0.6 : 1,
                child: Container(
                  width: 276,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      // Stack: thumbnail 64 + badge "Habis" di pojok kiri atas
                      Stack(
                        children: [
                          ProductThumb(
                            size: 64,
                            makanan: p.makanan,
                            nama: p.nama,
                            url: p.gambarUrl,
                          ),
                          if (p.habis)
                            const Positioned(
                              left: 4,
                              top: 4,
                              child: HabisBadge(),
                            ),
                        ],
                      ),
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
                      AddButton(
                        onTap: p.habis ? null : () => _bukaKustomisasi(p),
                      ),
                    ],
                  ),
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
  Widget _seksiKategori(String kategori, List<Produk> daftar, Set<String> favorit) {
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
        // Kategori tanpa produk: keterangan singkat agar chip tetap bermakna
        if (daftar.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Text(
              'Belum ada menu di kategori ini.',
              style: ts(13, 500, color: AppColors.muted),
            ),
          ),
        // map: setiap produk jadi satu baris datar
        for (final p in daftar)
          BarisMenu(key: ValueKey(p.id), produk: p, favorit: favorit.contains(p.id)),
        const SizedBox(height: 12),
      ],
    );
  }
}