import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/dummy_data.dart';
import '../main.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'customize_page.dart';

// HomePage: layar Beranda (DESIGN.md 3.2)
// Banner gambar + card melayang (sapaan, metode pesan, aksi cepat) + slider promo
// + daftar "Paling laris"
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State: _promoController mengontrol PageView slider promo
  // viewportFraction 0.82 ≈ lebar kartu 290 + jarak 12 pada layar 390
  final PageController _promoController = PageController(viewportFraction: 0.82);
  // State: _promoAktif menyimpan index kartu promo yang sedang tampil (untuk dot)
  int _promoAktif = 0;

  // dispose: membersihkan controller saat widget dihancurkan
  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  // _lebarDot: lebar dot indikator ke-i (aktif 20, lainnya 6)
  double _lebarDot(int i) => i == _promoAktif ? 20 : 6;

  // _tapDot: cari dot terdekat dari posisi tap (dx relatif tengah baris);
  // bila dalam radius 22, geser slider ke kartu tersebut
  void _tapDot(double dx) {
    final lebar = [for (var i = 0; i < 3; i++) _lebarDot(i) + 6]; // + margin 3×2
    var x = -lebar.reduce((a, b) => a + b) / 2; // Tepi kiri baris dot
    var terdekat = 0;
    var jarak = double.infinity;
    for (var i = 0; i < lebar.length; i++) {
      final j = (dx - (x + lebar[i] / 2)).abs(); // Jarak ke tengah dot ke-i
      if (j < jarak) (terdekat, jarak) = (i, j);
      x += lebar[i];
    }
    if (jarak > 22) return; // Tap terlalu jauh dari dot mana pun
    _promoController.animateToPage(
      terdekat,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // _pilihMetode: simpan metode pesanan lalu pindah ke tab Menu
  void _pilihMetode(bool makanDiTempat) {
    // context.read: mengambil CartProvider tanpa mendengarkan perubahan
    context.read<CartProvider>().setMakanDiTempat(makanDiTempat);
    NavigationPage.tab.value = NavigationPage.tabMenu;
  }

  @override
  Widget build(BuildContext context) {
    // atasAman: tinggi status bar agar tombol notifikasi tidak tertutup
    final atasAman = MediaQuery.paddingOf(context).top;

    // SingleChildScrollView: seluruh Beranda bisa digeser
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 170), // Ruang untuk sheet navbar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stack: banner di belakang, card melayang di depan
          Stack(
            children: [
              // ClipRRect: banner tinggi 280 dengan radius bawah 24
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: Container(
                  height: 280,
                  width: double.infinity,
                  color: AppColors.ink, // Latar bila gambar belum termuat
                  // Gradasi gelap di bagian bawah banner agar sapaan terbaca
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.35, 1],
                      colors: [
                        AppColors.ink.withValues(alpha: 0),
                        AppColors.ink.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/banner-beranda.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -0.28),
                  ),
                ),
              ),
              // Positioned: tombol notifikasi bulat 44 di kanan atas
              Positioned(
                top: atasAman + 16,
                right: 20,
                child: RoundIconButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifikasi',
                  background: AppColors.cream.withValues(alpha: 0.14),
                  foreground: AppColors.cream,
                  shadow: false,
                  onTap: () => segeraHadir(context, 'Notifikasi'),
                ),
              ),
              // Positioned: sapaan di atas card, menimpa banner gelap.
              // left 32 = tepi card 16 + padding 16, sejajar isi card
              // (bukan sudut card yang melengkung).
              // Nama→subjudul rapat (4), subjudul→card 12. Line-height 1.2 agar
              // tinggi pasti: 32×1.2 + 4 + 16×1.2 = 61.6 → top = 226 − 12 − 61.6
              Positioned(
                top: 152.4,
                left: 32,
                right: 32,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hai, Rina',
                        style: ts(32, 800,
                            color: Colors.white, ls: -0.5, height: 1.2)),
                    const SizedBox(height: 4),
                    Text('Mau ngopi apa hari ini?',
                        style: ts(16, 600, color: Colors.white, height: 1.2)),
                  ],
                ),
              ),
              // Padding: card melayang mulai top 226, inset 16
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 226, 16, 0),
                child: _kartuMelayang(),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Judul seksi "Promo untukmu" + link "Lihat semua"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Text('Promo untukmu', style: ts(16, 800))),
                GestureDetector(
                  onTap: () => segeraHadir(context, 'Daftar promo'),
                  child: Text('Lihat semua',
                      style: ts(13, 700, color: AppColors.promoLabel)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Slider promo: PageView dengan snap ke kiri (padding kiri 20)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SizedBox(
              height: 128,
              child: PageView(
                controller: _promoController,
                padEnds: false, // Kartu pertama rata kiri
                clipBehavior: Clip.none, // Kartu boleh tampil di area padding
                onPageChanged: (i) => setState(() => _promoAktif = i),
                children: const [
                  _KartuPromo(
                    gambar: 'assets/images/banner-promo-1.png',
                    label: 'Pelanggan baru: diskon 20% pesanan pertama, kode KOPIKITA20',
                  ),
                  _KartuPromo(
                    gambar: 'assets/images/banner-promo-2.png',
                    label: 'Promo mingguan: beli 2 minum gratis 1, kode KITAB2G1',
                  ),
                  _KartuPromo(
                    gambar: 'assets/images/banner-promo-3.png',
                    label: 'Paket pagi: kopi dan croissant mulai Rp35.000',
                  ),
                ],
              ),
            ),
          ),
          // Tanpa SizedBox: area tap 44 sudah memberi jarak ±19 di atas dot

          // Indikator dot: aktif 20×6 primary, lainnya 6×6 pending.
          // Tap dot → lompat ke kartu itu. Area tap 44 tinggi & ±22 dari
          // tengah dot (target sentuh 44×44) tanpa mengubah jarak dot 6.
          SizedBox(
            height: 44,
            child: LayoutBuilder(
              builder: (context, c) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _tapDot(d.localPosition.dx - c.maxWidth / 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: _lebarDot(i),
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _promoAktif
                              ? AppColors.primary
                              : AppColors.pending,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Judul seksi "Paling laris" + link "Lihat menu" (→ tab Menu)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(child: Text('Paling laris', style: ts(16, 800))),
                GestureDetector(
                  onTap: () =>
                      NavigationPage.tab.value = NavigationPage.tabMenu,
                  child: Text('Lihat menu',
                      style: ts(13, 700, color: AppColors.promoLabel)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Daftar menu terlaris: baris datar (bukan card)
          for (final p in rekomendasi)
            _barisLaris(p, terakhir: p == rekomendasi.last),
        ],
      ),
    );
  }

  // _barisLaris: baris datar ringkas (thumbnail 64 · nama/deskripsi/harga · +)
  // Ketuk baris atau + → sheet Kustomisasi
  Widget _barisLaris(Produk p, {bool terakhir = false}) {
    // InkWell selebar layar: highlight punya ruang 20 di kiri-kanan konten
    return InkWell(
      onTap: () => bukaKustomisasi(context, p),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: terakhir
                ? null
                : const Border(
                    bottom: BorderSide(color: AppColors.dividerList)),
          ),
          child: Row(
            children: [
              ProductThumb(size: 64, makanan: p.makanan, nama: p.nama),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.nama, style: ts(14, 700)),
                    const SizedBox(height: 2),
                    Text(
                      p.deskripsi,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ts(12, 500, color: AppColors.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(rp(p.harga),
                        style: ts(14, 800, color: AppColors.primary)),
                  ],
                ),
              ),
              AddButton(onTap: () => bukaKustomisasi(context, p)),
            ],
          ),
        ),
      ),
    );
  }

  // _kartuMelayang: card putih berisi sapaan, 2 aksi besar, dan 4 aksi cepat
  Widget _kartuMelayang() {
    // Container: card radius 24, padding 16, bayangan float
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.float,
      ),
      child: Column(
        children: [
          // 1. Dua aksi besar sama lebar: Ambil Sendiri & Makan di Tempat
          Row(
            children: [
              Expanded(
                child: _AksiBesar(
                  gambar: 'assets/images/ikon-ambil-sendiri.png',
                  label: 'Ambil Sendiri',
                  onTap: () => _pilihMetode(false),
                ),
              ),
              Expanded(
                child: _AksiBesar(
                  gambar: 'assets/images/ikon-makan-di-tempat.png',
                  label: 'Makan di Tempat',
                  onTap: () => _pilihMetode(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. Garis pemisah 1px dividerSoft
          const Divider(height: 1, color: AppColors.dividerSoft),
          const SizedBox(height: 14),

          // 4. Empat aksi cepat
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AksiCepat(
                icon: Icons.sell_outlined,
                label: 'Promo',
                onTap: () => segeraHadir(context, 'Promo'),
              ),
              _AksiCepat(
                icon: Icons.confirmation_number_outlined,
                label: 'Voucher',
                onTap: () => NavigationPage.tab.value = NavigationPage.tabAkun,
              ),
              _AksiCepat(
                icon: Icons.favorite_border_rounded,
                label: 'Favorit',
                onTap: () => NavigationPage.tab.value = NavigationPage.tabMenu,
              ),
              _AksiCepat(
                icon: Icons.sync_rounded,
                label: 'Pesan Lagi',
                onTap: () => NavigationPage.tab.value = NavigationPage.tabPesanan,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// _AksiBesar: tombol aksi metode pesan (gambar tinggi 48 + label 14/700)
class _AksiBesar extends StatelessWidget {
  final String gambar; // Path aset ilustrasi
  final String label; // Teks label
  final VoidCallback onTap; // Aksi saat ditekan
  const _AksiBesar({required this.gambar, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // InkWell: efek ripple saat ditekan
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            // SizedBox: area gambar 76×56, gambar tinggi 48 tanpa latar
            SizedBox(
              width: 76,
              height: 56,
              child: Center(child: Image.asset(gambar, height: 48)),
            ),
            const SizedBox(height: 8),
            Text(label, style: ts(14, 700)),
          ],
        ),
      ),
    );
  }
}

// _AksiCepat: ikon garis 24 primary + label 12/500, lebar 72
class _AksiCepat extends StatelessWidget {
  final IconData icon; // Ikon aksi
  final String label; // Teks label
  final VoidCallback onTap; // Aksi saat ditekan
  const _AksiCepat({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Icon(icon, size: 24, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: ts(12, 500, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

// _KartuPromo: kartu promo 128 tinggi, radius 24, isi gambar banner
// (teks promo sudah ada di gambar; label dipakai pembaca layar)
class _KartuPromo extends StatelessWidget {
  final String gambar; // Path aset banner promo
  final String label; // Deskripsi promo untuk aksesibilitas
  const _KartuPromo({required this.gambar, required this.label});

  @override
  Widget build(BuildContext context) {
    // Padding kanan 12 = jarak antar kartu
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          gambar,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          semanticLabel: label,
        ),
      ),
    );
  }
}