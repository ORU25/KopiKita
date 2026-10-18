# KopiKita — Spesifikasi Desain Aplikasi Pelanggan

Acuan UI untuk aplikasi Android pelanggan KopiKita (Flutter). Dokumen ini adalah **sumber kebenaran** untuk warna, tipografi, ukuran, dan perilaku layar. Gambar di `screens/` menunjukkan tampilan akhir; file di `source/` berisi nilai persis (HTML/CSS) bila ada yang ambigu.

- Frame desain: **390 × 844** (logical px = dp di Flutter).
- Gaya: card-based, modern, clean, minimalis. Hindari menumpuk card — daftar panjang memakai **baris datar dengan garis pemisah**, bukan card.
- Bahasa UI: Bahasa Indonesia.
- Lingkup: hanya aplikasi pelanggan. Metode pesanan hanya **Ambil Sendiri** (pickup) dan **Makan di Tempat** (dine-in) — tidak ada delivery. **Tidak ada fitur poin/loyalty.**

---

## 1. Token desain

### Warna

| Token | Hex | Dipakai untuk |
|---|---|---|
| `primary` | `#6B3216` | Tombol utama, harga, ikon aktif, chip terpilih, teks link |
| `primaryDeco` | `#8A4720` | Lingkaran dekoratif di kartu promo cokelat |
| `caramel` | `#C47A3A` | Aksen sekunder, status "sedang berjalan", lingkaran dekoratif kartu antrean |
| `caramelDeco` | `#D9954F` | Lingkaran dekoratif kartu promo karamel |
| `promoLabel` | `#9A5A1C` | Link "Lihat semua", hati favorit aktif |
| `ink` | `#2B1810` | Teks utama; latar banner bila gambar belum termuat |
| `textSecondary` | `#5A4436` | Label sekunder (aksi cepat, info voucher, chip tidak terpilih) |
| `muted` | `#7A6355` | Teks deskripsi/meta, ikon tidak aktif, tab tidak aktif |
| `disabled` | `#B9A89B` | Tombol + untuk menu habis, border checkbox kosong |
| `bg` | `#FFFFFF` | Latar halaman (putih); latar sheet Kustomisasi; input fokus |
| `surface` | `#FCF9F5` | Card, sheet (kecuali sheet Kustomisasi = `bg`), navbar, tombol bulat (cokelat muda) |
| `fill` | `#F3EADF` | Isi input, segmented control, chip tidak terpilih, stepper jumlah |
| `tint` | `#F1E4D4` | Thumbnail placeholder, avatar, segmented terpilih di Keranjang |
| `cartStrip` | `#F6ECE0` | Latar strip keranjang di atas navbar |
| `cream` | `#FBEFE0` | Teks/elemen terang di atas latar cokelat tua |
| `divider` | `#EDE3D8` | Garis pemisah umum, border bawah tab |
| `dividerSoft` | `#F0E7DC` | Pemisah di dalam card |
| `dividerList` | `#E9DED2` | Pemisah baris daftar menu |
| `outline` | `#E6D9CB` | Border tombol bulat stepper, tombol sekunder bergaris, garis stepper belum dilalui |
| `danger` | `#B3261E` | Aksi berbahaya (baris Keluar di Akun) |
| `pending` | `#D9CABB` | Titik status belum tercapai, dot slider tidak aktif, handle bottom sheet |

**Catatan "putih":** di bagian 2–3, latar card/sheet/navbar/tombol bulat yang disebut "putih" memakai token `surface` (`#FCF9F5`), bukan `#FFFFFF`. Sheet Kustomisasi berlatar `bg` (`#FFFFFF`), item terpilih `primary` teks putih; input fokus memakai `bg`. Teks/ikon putih di atas `primary` tetap `#FFFFFF`.

Thumbnail produk **sementara** memakai foto dari `assets/images/` (peta `gambarMenu` di `lib/data/dummy_data.dart`, dicari berdasarkan nama produk; `BoxFit.cover`, radius 10). Produk tanpa foto memakai placeholder: latar `tint #F1E4D4`, ikon `primary #6B3216`. Riwayat pesanan memakai foto item pertama di ringkasan. Nanti diganti foto produk dari Cloudinary dengan radius yang sama.

### Tipografi

Font: **Plus Jakarta Sans** (file variabel di `fonts/`, lisensi OFL; atau paket `google_fonts`). **Ukuran teks minimum 12.**

| Peran | Ukuran / tebal | Contoh |
|---|---|---|
| Nomor antrean | 48 / 800, letter-spacing −1 | "A-014" |
| Brand di Login | 30 / 800, ls −0.6 | "KopiKita" |
| Judul halaman | 24 / 800, ls −0.4 | "Pesanan Saya", "Akun" |
| Judul sheet / layar | 22 / 700–800, ls −0.3 | "Masuk", "Keranjang", nama produk di Kustomisasi |
| Judul header Menu / judul promo | 20 / 800, ls −0.3 | "KopiKita", "Diskon 20% pesanan pertama" |
| Sapaan | 18 / 700 | "Hai, Rina" |
| Judul seksi | 16 / 800 | "Promo untukmu", "Rekomendasi", "Kopi" |
| Tombol utama | 15 / 700 | "Masuk", "Pesan · Rp76.560" |
| Nama item / isi baris | 14 / 700 (baris pengaturan 14 / 600) | "Kopi Susu Kita" |
| Teks sekunder / link | 13 / 600–700 | "Lihat keranjang", subjudul |
| Meta, label, navbar | 12 / 500–700 | deskripsi produk, label field, label tab navbar |

Harga: 13–14 / 800, warna `primary`. Total: 18 / 800 (Keranjang), 16 / 800 (Pesanan).

### Radius

| Elemen | Radius |
|---|---|
| Thumbnail produk | **10** (sengaja tidak terlalu bulat) |
| Input, chip pilihan, segmented luar | 14–16 |
| Tombol utama | 16 |
| Card biasa (profil, detail, item keranjang, rekomendasi) | 20 |
| Card melayang Beranda/Login, kartu promo, kartu antrean | 24 |
| Banner (sudut bawah) | 0 0 24 24 |
| Bottom sheet & sheet navbar (sudut atas) | 28 28 0 0 |
| Pill (chip kategori, badge, tombol bulat) | penuh (tinggi/2) |

### Bayangan (lembut, kehangatan cokelat)

| Nama | Nilai CSS | Flutter kira-kira |
|---|---|---|
| `card` | `0 2px 10px rgba(60,30,10,0.05)` | `BoxShadow(color: Color(0x0D3C1E0A), blurRadius: 10, offset: Offset(0,2))` |
| `float` | `0 6px 20px rgba(43,24,16,0.07)` | `BoxShadow(color: Color(0x122B1810), blurRadius: 20, offset: Offset(0,6))` |
| `navSheet` | `0 -6px 24px rgba(60,30,10,0.08)` | `BoxShadow(color: Color(0x143C1E0A), blurRadius: 24, offset: Offset(0,-6))` |
| `chip` | `0 2px 8px rgba(60,30,10,0.05)` | tombol bulat putih di header Menu |

### Jarak & ukuran

- Padding horizontal halaman: **20**. Card melayang: inset **16** dari tepi layar.
- Jarak antar-blok vertikal: 14–16. Antar-elemen dalam blok: 4–12.
- **Target sentuh minimum 44 × 44** (tombol ikon 44; tombol + di daftar 36 visual tapi beri hit area 44).
- Tinggi: tombol utama 52, input 52, chip pilihan 44, chip kategori 40, segmented item 36–40, baris pengaturan 52, strip keranjang 56, baris navbar 84.

### Ikon

Ikon garis (outline), 24 × 24, stroke 1.8, ujung bulat (gaya mirip **Lucide**). Paket `lucide_icons` / `lucide_icons_flutter` cocok. Path SVG persis ada di `source/*.dc.html` bila perlu ikon kustom (cangkir kopi, struk).

Aset gambar di `assets/`:
- `banner-beranda.jpg` — gambar banner Beranda (`BoxFit.cover`, alignment kira-kira `Alignment(0, -0.28)`).
- `ikon-ambil-sendiri.png` — ilustrasi tas (aksi "Ambil Sendiri"), tampil tinggi 48.
- `ikon-makan-di-tempat.png` — ilustrasi cangkir (aksi "Makan di Tempat"), tampil tinggi 48.

---

## 2. Komponen bersama

### Bottom navigation + strip keranjang (satu sheet)
Ada di Beranda, Menu, Pesanan (Aktif & Riwayat), Akun. **Tidak** ada di Login, Kustomisasi, Keranjang.

- Satu container putih menempel di bawah, radius atas 28, bayangan `navSheet`.
- **Strip keranjang** (hanya tampil bila keranjang berisi): tinggi 56, latar `cartStrip #F6ECE0`, radius atas 28, padding 0 20. Isi: kotak ikon troli 36×36 (putih, radius 12, ikon `primary`) · teks "3 item · **Rp76.560**" (13, muted; total 800 ink) · link "Lihat keranjang ›" (13/700 `primary`). Ketuk → Keranjang. Keranjang **bukan** tab navbar.
- **Baris navbar**: tinggi 84, padding 10 8 14, 4 tab sama lebar: Beranda (rumah), Menu (cangkir), Pesanan (struk), Akun (orang). Tiap tab: ikon 24 di tengah kotak 40×40 (aktif: **lingkaran** diameter 40), label 12 di bawah (gap 4).
  - Aktif: indikator lingkaran latar `primary` (cokelat solid, selaras chip kategori & tombol utama), ikon putih; label `primary` 700.
  - Tidak aktif: tanpa latar, warna `muted`, label 600.
  - Ripple tap: `primary` alpha 0.08.
- Flutter: `bottomNavigationBar: Column(mainAxisSize: min, children: [if (cart.isNotEmpty) CartStrip(), NavigationBar(...)])` dibungkus `Container` `surface` radius atas 28. `NavigationBar` M3: `indicatorColor: transparent`, `indicatorShape: CircleBorder()` (untuk ripple); lingkaran aktif 40 `primary` + ikon putih dibuat lewat `selectedIcon` (`_ikonNav`), ikon tidak aktif juga dibungkus 40×40 agar label tidak bergeser, `height: 84`, `labelBehavior: alwaysShow`, latar `surface`, tanpa surface tint.

### Card melayang (Beranda & Login)
Putih, radius 24, padding 16 (Login 22 20 20), bayangan `float`, posisi `top: 226` menimpa bagian bawah banner (banner tinggi 280–290). Kiri/kanan 16.

### Segmented control
Wadah padding 4, radius 14–16, latar putih (header Menu, Keranjang). Item tinggi 36–40, radius 10–12, 13/700. Item terpilih selalu diberi bayangan `chip` agar terpisah dari wadah.
- Menu: terpilih = latar `primary`, teks putih.
- (Kustomisasi tidak lagi memakai segmented; Ukuran & Suhu memakai chip pilihan berikon.)
- Keranjang: terpilih = latar `tint`, teks `primary`.

### Chip pilihan (Kustomisasi)
Tinggi 44, radius 14, sama lebar (Expanded), ikon opsional di kiri teks. Terpilih: latar `primary` (lebih gelap), teks/ikon putih, tanpa border. Tidak terpilih: latar `fill`, teks `textSecondary`.

### Baris datar
Padding vertikal 14, `border-bottom: 1px` (`dividerList` / `divider`), tanpa card. Dipakai untuk daftar menu, riwayat pesanan, pengaturan akun.

### Tombol
- Utama: tinggi 52, radius 16, latar `primary`, teks putih 15/700. Lebar penuh atau `Expanded`.
- Sekunder bergaris: tinggi 52, radius 16, border 1.5 `outline`, teks ink 14/700 (saat ini belum dipakai — tombol "Lanjutkan dengan Google" sudah dihapus).
- Tombol bulat tambah (+): 36×36, latar `primary`, ikon putih 20. Saat habis: latar `disabled`.
- Stepper di keranjang: lingkaran 32 border 1 `outline`, ikon `primary`, angka 14/700.

---

## 3. Layar

Urutan alur: **Splash → Login (↔ Daftar) → Beranda → Menu → Kustomisasi → Keranjang → Pesanan (Aktif) ↔ Riwayat**, plus **Akun**.

### 3.0 Splash (`assets/splashScreen.png`)
- Layar pertama saat aplikasi dibuka: `SplashScreen` (`lib/main.dart`) — satu gambar penuh layar `Image.asset('assets/splashScreen.png', fit: BoxFit.cover)` di atas latar `bg`. Logo dan teks "Loading..." sudah ada di dalam gambar, jadi tidak ada widget tambahan.
- **Splash native** (sebelum Flutter siap, dibuat `flutter_native_splash`, konfigurasi di `pubspec.yaml`): latar putih `#FFFFFF` + logo transparan `assets/images/logoTransparant.png` di tengah (Android 12+ memakai `assets/images/logoSplashAndroid12.png` = logo 500 px di tengah kanvas transparan 768 px, karena Android 12 memotong ikon menjadi lingkaran berdiameter 2/3 gambar; tanpa padding logo terlihat terpotong/ter-zoom), untuk Android (termasuk Android 12+) dan iOS, sama di mode terang & gelap. Android 12+ hanya mengizinkan ikon di tengah, jadi gambar penuh baru tampil di `SplashScreen` Flutter. `NormalTheme` di `android/app/src/main/res/values*/styles.xml` memakai `@drawable/launch_background` (bukan `?android:colorBackground`) supaya tidak berkedip hitam di mode gelap.
- Tampil **minimal 2 detik** (`Future.delayed` top-level `_splashSelesai`, dibuat sekali), lalu `AuthGate` (3.1b). Bila status login Firebase belum siap, AuthGate tetap menampilkan `SplashScreen`.

```dart
home: FutureBuilder(
  future: _splashSelesai,
  builder: (context, snap) => snap.connectionState == ConnectionState.done
      ? const AuthGate()
      : const SplashScreen(),
),
```

### 3.1 Login (`screens/Login.png`, `source/Login.dc.html`)
- Banner atas tinggi 290, latar `ink #2B1810`, radius bawah 24. Teks **rata tengah** (top 64): "KopiKita" 30/800 `cream`, tagline "Pesan kopi favoritmu tanpa antre." 14/500.
- **Badge logo**: lingkaran 92, latar `bg` (putih), border 4 `surface`, bayangan `float`, padding 12, aset `assets/images/logo-app.png` (dari `kopikita-design/assets/logoAppLatarPutih.png`). Tengah horizontal, top 180 → titik tengahnya tepat di tepi atas card (setengah di banner, setengah di card).
- Card melayang (top 226, padding 58 20 20 untuk ruang badge): "Masuk" 22/800 + subjudul (keduanya rata tengah) "Masuk untuk mulai memesan." 13 muted → field **Email** (label 12/700 `textSecondary`, input 52 radius 14 latar `fill`, ikon amplop kiri) → field **Kata sandi** (state fokus: latar putih, border 1.5 `primary`, ikon gembok, tombol mata 44 di kanan) → link "Lupa kata sandi?" rata kanan 13/700 `primary` → tombol **Masuk** (akhir card).
- **Login Google tidak diimplementasikan.** Autentikasi hanya email/kata sandi lewat Firebase Auth. Pemisah "atau" dan tombol "Lanjutkan dengan Google" yang masih terlihat di `screens/Login.png` / `source/Login.dc.html` **diabaikan** — sengaja tidak dipakai.
- **Lupa kata sandi** — `AlertDialog` (radius 20, latar `surface`), bukan halaman baru: judul "Lupa kata sandi" 16/800 ls −0.3 → penjelasan "Masukkan email akunmu. Kami akan mengirim tautan untuk mengatur ulang kata sandi." 13 muted line-height 1.4 → field email (prefill dari field Login, keyboard email, autofocus) → tombol **Batal** 13/700 `muted` dan **Kirim** 13/700 `primary`. Kirim → `FirebaseAuth.sendPasswordResetEmail()`; sukses → SnackBar "Tautan reset dikirim ke {email}"; gagal → SnackBar pesan Bahasa Indonesia dari `AuthService.pesanError`.
- Bawah (bottom 36, tengah): "Belum punya akun? **Daftar**" (14 muted; "Daftar" 800 `primary`) → layar Daftar (3.1a).
- Autentikasi: Firebase Auth **email/kata sandi saja**. Masuk berhasil → Beranda.
- Flutter: banner + badge + card + ajakan bawah adalah widget bersama `AuthScaffold` (`lib/screens/login_page.dart`), dipakai Masuk & Daftar; isi form dikirim lewat `children`.

### 3.1a Daftar (belum ada gambar; turunan Login)
- Kerangka **sama persis** dengan Login (`AuthScaffold`): banner 290 `ink`, badge logo, card melayang top 226 padding 58 20 20.
- Isi card: "Daftar" 22/800 + "Buat akun untuk mulai memesan." 13 muted (rata tengah) → field **Nama** (ikon orang, placeholder "Nama lengkap", huruf kapital tiap kata) → field **Email** (ikon amplop) → field **Kata sandi** (ikon gembok, tombol mata 44, placeholder "Minimal 6 karakter") → jarak 20 → tombol utama **Daftar**. Jarak antar-field 14, label field 12/700 `textSecondary`.
- Bawah: "Sudah punya akun? **Masuk**" → kembali ke Login (pop).
- **Implementasi**: `AuthService.daftar(nama, email, password)` (`lib/services/auth_service.dart`): `createUserWithEmailAndPassword` → `updateDisplayName(nama)` → tulis dokumen `users/{uid}` (`nama`, `email`, `role: "pelanggan"`, `favorit: []`, `voucher: ["KOPIKITA20", "HEMAT5RB"]`, `notifikasi: true`, `createdAt`). Jika Firestore gagal, akun Auth dihapus (rollback) agar tidak ada user tanpa dokumen.
- **Transisi ke Beranda** diurus `AuthGate` (lihat 3.1b), bukan `Navigator.push` manual. Setelah daftar sukses, `authStateChanges()` berubah dan AuthGate otomatis menampilkan Beranda.
- Setelah daftar sukses dan AuthGate menampilkan `NavigationPage`, layar `RegisterPage` **di-pop** (`Navigator.of(context).popUntil((r) => r.isFirst)`) agar Beranda (root baru) langsung terlihat, bukan tetap menampilkan form Daftar.

```dart
// Pola pakai AuthScaffold (lib/screens/register_page.dart)
AuthScaffold(
  judul: 'Daftar',
  subjudul: 'Buat akun untuk mulai memesan.',
  ajakan: 'Sudah punya akun?',
  aksi: 'Masuk',
  onAksi: () => Navigator.pop(context),
  children: [labelField('Nama'), TextField(...), /* Email, Kata sandi */ PrimaryButton(label: 'Daftar', onPressed: _daftar)],
)
```

### 3.1b AuthGate (belum ada gambar; pengatur alur)

- Widget pembungkus di `lib/main.dart` yang menjadi `home:` dari `MaterialApp`. Menentukan layar awal berdasarkan status login Firebase (`FirebaseAuth.instance.authStateChanges()`).
- Tiga keadaan:
  - `ConnectionState.waiting` (pertama kali dibuka) → `SplashScreen` (3.0), agar tidak berkedip Login dulu.
  - `snapshot.hasData` (sudah login) → `NavigationPage` (tab Beranda). Setiap transisi dari belum-login ke sudah-login **mereset tab navbar ke Beranda** (`NavigationPage.tab.value = tabBeranda`) lewat `addPostFrameCallback`.
  - Selainnya (belum login) → `LoginPage`.
- Karena AuthGate memantau `authStateChanges()`, layar Login/Tidak perlu navigasi manual: berhasil login → AuthGate otomatis pindah ke Beranda; `AuthService.keluar()` → AuthGate otomatis kembali ke Login.
- **Tidak ada provider user.** Data profil (`users/{uid}`) dibaca langsung oleh layar yang membutuhkannya lewat `UserRepo` (`lib/services/user_repo.dart`):
  - `UserRepo.stream()` → `Stream<DocumentSnapshot>` untuk Beranda (sapaan) dan Akun.
  - `UserRepo.ambil()` → sekali baca, untuk prefill Edit profil dan Notifikasi.
  - `UserRepo.update(data)` → tulis `users/{uid}` (ganti nama, toggle notifikasi).
  - Getter aman null-safe: `namaDari`, `emailDari`, `roleDari`, `voucherDari`, `notifikasiDari`.

### 3.2 Beranda (`screens/Beranda.png`, `source/Main.dc.html`)

- **Banner** tinggi 280, radius bawah 24 (`ClipRRect`), latar `ink` bila gambar belum termuat, `Image.asset('assets/images/banner-beranda.jpg')` `BoxFit.cover` dengan `alignment: Alignment(0, 0)`. Gradasi gelap `ink` via `foregroundDecoration` dari alpha 0 (stop 0.35) → alpha 0.85 (bawah). Tanpa logo.
- **Tombol notifikasi** bulat 44 di kanan atas (`Positioned(top: atasAman + 16, right: 20)`; `atasAman = MediaQuery.padding.top`); latar `cream` alpha 0.14, ikon `notifications_none_rounded` warna `cream`, `shadow: false`; ketuk → push `NotificationPage`.
- **Sapaan di atas card** (`Positioned(top: 152.4, left: 32, right: 32)` — tepi card 16 + padding 16 agar sejajar isi card, bukan sudut lengkungnya):
  - `StreamBuilder` ke `users/{uid}`. Teks `Hai, {nama depan}` (kata pertama) 32/800 putih ls −0.5 line-height 1.2, `maxLines: 1`, ellipsis; bila nama kosong → `Hai!`.
  - Jarak 4, subjudul `Mau ngopi apa hari ini?` 16/600 putih line-height 1.2.
- **Card melayang** (`Padding.fromLTRB(16, 226, 16, 0)`; putih `surface`, radius 24, padding 16, bayangan `float`, gap 14):
  1. Dua aksi besar sama lebar (`Expanded`): **Ambil Sendiri** (`ikon-ambil-sendiri.png`) dan **Makan di Tempat** (`ikon-makan-di-tempat.png`). Tiap `_AksiBesar`: `InkWell` radius 16, padding vertikal 4, `SizedBox(76×56)` dengan gambar tinggi 48, `SizedBox(8)`, label 14/700. Ketuk → `cart.setMakanDiTempat(bool)` lalu `NavigationPage.tab = tabMenu`.
  2. Garis 1px `dividerSoft`.
  3. **Empat aksi cepat** (`spaceAround`, tiap `_AksiCepat`: lebar 72, padding vertikal 6, ikon garis 24 `primary`, gap 8, label 12/500 `textSecondary` line-height 1.15 maks 2 baris):
     - **Voucher** (`confirmation_number_outlined`) → tab **Akun** (daftar voucher),
     - **Favorit** (`favorite_border_rounded`) → push `FavoritePage`,
     - **Menu** (`restaurant_menu_rounded`) → tab **Menu**,
     - **Pesan Lagi** (`receipt_long_rounded`) → `OrdersPage.mintaRiwayat()` lalu tab **Pesanan** (langsung terbuka di sub-tab Riwayat).
- `SizedBox(28)` · judul seksi **Promo untukmu** 16/800 + link **Lihat semua** 13/700 `promoLabel` (→ tab **Akun**/voucher), padding horizontal 20. `SizedBox(14)`.
- **Slider promo**: `Padding(left: 20)` + `SizedBox(height: 128)` + `PageView(controller: PageController(viewportFraction: 0.82), padEnds: false, clipBehavior: Clip.none)`. Tiap `_KartuPromo`: `Padding(right: 12)` + `ClipRRect(radius 24)` + `Image.asset` cover penuh (`width/height: double.infinity`) dengan `semanticLabel` berisi isi promo. Tiga gambar: `banner-promo-1..3.png` (teks promo sudah ada di gambar).
- **Indikator dot**: `SizedBox(height: 44)` + `LayoutBuilder` + `GestureDetector(behavior: HitTestBehavior.opaque)`. Tap → `_tapDot` mencari dot terdekat dari tengah baris (lebar tiap dot = lebar dot + margin 3×2); bila jarak < 22 → `animateToPage` 300 ms `easeOut`. Tiap dot `AnimatedContainer` 200 ms, margin horizontal 3, aktif 20×6 `primary`, lainnya 6×6 `pending`, radius 3.
- `SizedBox(14)` · judul **Paling laris** 16/800 + link **Lihat menu** 13/700 `promoLabel` (→ tab Menu). `SizedBox(4)`.
- **Daftar Paling laris** (`StreamBuilder<List<Produk>>` realtime):
  - Loading/error/empty lewat `keadaanStream` → `EmptyView(coffee_outlined, "Belum ada menu terlaris", "Menu pilihan kedai akan tampil di sini.")`.
  - Ambil produk ber-flag `rekomendasi`, `take(4)` (urutan katalog), render `_barisLaris`.
  - **Baris datar** (`_barisLaris`): `Opacity` 0.6 bila `habis`; seluruh baris `InkWell` → `bukaKustomisasi` (nonaktif bila habis). Padding horizontal 20, vertikal 12; garis bawah `dividerList` kecuali baris terakhir. Isi `Row`:
    - `Stack` `ProductThumb` 64 (radius 10) + `HabisBadge` di `Positioned(left: 4, top: 4)` bila habis;
    - `SizedBox(14)`;
    - `Expanded` kolom: nama 14/700 · deskripsi 12/500 `muted` 1 baris ellipsis · `SizedBox(4)` · harga 14/800 `primary`;
    - `AddButton` (hit 44, `disabled` saat habis) → `bukaKustomisasi`.
- Padding bawah `SingleChildScrollView` **170** agar item terakhir tidak tertutup sheet navbar.

### 3.3 Menu (`screens/Menu.png`, `screens/Menu-header-collapsed.png`, `source/Menu.dc.html`)

Struktur: `SafeArea(bottom: false)` → `Column` (header tidak ikut scroll + `Expanded` berisi area scroll). Header dibungkus `AnimatedSize` 200 ms + `AnimatedSwitcher` 200 ms (transisi halus expanded ↔ collapsed).

- **Header collapsing** (padding `fromLTRB(20, 20, 20, 10)`, latar `bg`):
  - *Expanded* (`key: 'lengkap'`): `Row` — tombol kembali bulat 44 (`chevron_left_rounded`, → tab **Beranda**, bukan pop) · `SizedBox(12)` · `Expanded "KopiKita"` 20/800 ls −0.3 · tombol info bulat 44 (`info_outline_rounded`, warna `primary`) → `AlertDialog` **Info Kedai**. `SizedBox(12)`, lalu `SegmentedPill` **Ambil Sendiri | Makan di Tempat** (bg `surface`, terpilih `primary`/putih, fg `ink`, bayangan `chip`) → `cart.setMakanDiTempat`.
  - *Collapsed* (`key: 'ringkas'`): `Row` tombol kembali · `SizedBox(12)` · `Expanded` dua baris `{Metode} · KopiKita` 14/800 (1 baris ellipsis) + `Outlet Utama · 350 m dari kamu` 12/500 `muted` (1 baris ellipsis) · pill **Ubah** (`Material surface`, radius 16, tinggi **44** — tampilan pill 32, hit area 44; padding horizontal 12; teks 12/800 `primary`) → toggle `cart.setMakanDiTempat`.
  - **Histeresis**: collapse saat offset > 60, expand saat < 8 (abaikan `ScrollNotification` horizontal).
- **AlertDialog Info Kedai** (radius 24, latar `surface`; `titlePadding fromLTRB(24, 22, 24, 0)`, `contentPadding fromLTRB(24, 12, 24, 8)`, `actionsPadding fromLTRB(16, 0, 16, 12)`): judul "Info Kedai" 18/800 · baris `location_on_outlined` 20 `primary` + "Jl. Universitas Mulawarman" 14/600 · `SizedBox(14)` · baris `access_time_rounded` 20 `primary` + "10:00 – 23:00 WITA" 14/600 · aksi **Tutup** 13/800 `primary`.
- **Bar filter sticky** (`PinnedHeaderSliver`; container `bg`, padding `fromLTRB(20, 6, 20, 10)`): `Expanded SizedBox(height: 44)` + `ListView.separated` horizontal (separator 8) berisi chip kategori — tinggi 40, radius penuh (20), padding horizontal 16, 13/700; terpilih latar `primary` teks putih, tidak terpilih latar **`surface`** teks `ink`. Kategori: **Rekomendasi, Kopi, Non-Kopi, Makanan** (dari `kategoriMenu`). Kanan: `RoundIconButton` cari bulat 44 (`search_rounded`, `primary`) → `_bukaCari(daftar)` (mengirim `awal: data` ke `SearchPage`).
- Ketuk chip → `setState(_kategoriAktif)` + `Scrollable.ensureVisible` ke `GlobalKey` seksi kategori (300 ms, `alignment: 0`).
- **Area scroll** (`NotificationListener` + `CustomScrollView`):
  - `PinnedHeaderSliver(_barFilter)`.
  - Bila loading/error/kosong → `SliverFillRemaining(hasScrollBody: false)` berisi `keadaanStream` → `EmptyView(coffee_outlined, "Menu belum tersedia", "Kedai belum menambahkan menu. Coba lagi nanti.")`; `onCoba: _muatUlang`.
  - Bila siap:
    - `SliverToBoxAdapter(_seksiRekomendasi(produk.rekomendasi))`;
    - `SliverToBoxAdapter(_seksiKategori(...))` untuk tiap `kategoriMenu.skip(1)`;
    - `SliverToBoxAdapter(SizedBox(height: 170))` sebagai ruang sheet navbar.
- **Rekomendasi** (disembunyikan bila kosong): judul "Rekomendasi" 16/800 (padding `fromLTRB(20, 8, 20, 10)`); `SizedBox(height: 104)` + `ListView.separated` horizontal (padding horizontal 20, vertikal 10, separator 12, `clipBehavior: Clip.none` — kartu berikutnya terpotong di tepi). Tiap kartu `Container width: 276`, padding 10, `surface` radius 20, bayangan `card`, `Opacity` 0.6 bila habis. Isi `Row`:
  - `Stack` `ProductThumb` 64 + `HabisBadge` `Positioned(left: 4, top: 4)` bila habis · `SizedBox(10)`;
  - `Expanded` kolom (center): nama 14/700 · deskripsi 12/500 `muted` · `SizedBox(2)` · harga 13/800 `primary` (semua 1 baris ellipsis);
  - `AddButton` (disabled saat habis) → `bukaKustomisasi`.
  `SizedBox(16)` penutup.
- **Seksi kategori**: `Column` ber-`GlobalKey` kategori. Header `Row` (baseline, `TextBaseline.alphabetic`): "Kopi" 16/800 + `SizedBox(8)` + "3 menu" 12/600 `muted` (padding `fromLTRB(20, 8, 20, 4)`). Kategori kosong → "Belum ada menu di kategori ini." 13/500 `muted` (padding 20/14). Setiap produk → `BarisMenu(produk, favorit: favorit.contains(p.id))`. `SizedBox(12)` penutup.
- **Menu habis**: opacity 0.6, badge "Habis" (22 tinggi, latar `ink`, teks putih 12/700) di pojok kiri atas thumbnail, tombol + `disabled`.

### 3.3a Cari (`search_page.dart`)

- `SearchPage(awal: List<Produk>?)` — menerima daftar produk yang sudah dimuat Menu sebagai `initialData` agar hasil tampil instan; tetap mengikuti stream realtime (mis. status Habis). Tidak ada query Firestore per ketikan.
- `Scaffold(bg)` + `SafeArea`.
- **Header** (padding `fromLTRB(20, 12, 20, 8)`): tombol kembali bulat 44 (`chevron_left_rounded` → `Navigator.pop`) · `SizedBox(12)` · `Expanded TextField` (`autofocus: true`, `textInputAction: search`, style 14/500, `onChanged` → `_kata = v.trim().toLowerCase()`). Dekorasi: hint "Cari menu", prefix `search_rounded`, suffix tombol hapus 44 (`close_rounded`) hanya bila `_kata` / `_ctrl.text` tidak kosong → `_hapus` (kosongkan ctrl + state).
- **Hasil** dibungkus `FavoritBuilder` → `StreamBuilder<List<Produk>>` (`initialData: widget.awal`).
- **Logika tampilan**:
  - loading/error → `keadaanStream` (`onCoba: _muatUlang`, `kosong: (_) => false`, `tampilanKosong: SizedBox.shrink()`).
  - `_kata` kosong → `EmptyView(search_rounded, "Cari menu favoritmu", "Ketik nama menu, misalnya \"latte\" atau \"croissant\".")`.
  - filter **lokal**: `p.nama.toLowerCase().contains(_kata)`.
  - hasil kosong → `EmptyView(search_off_rounded, "Menu tidak ditemukan", "Coba kata kunci lain atau periksa ejaannya.")`.
  - ada hasil → `ListView` (`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`, padding bawah 24): teks `{n} menu ditemukan` 12/600 `muted` (padding `fromLTRB(20, 8, 20, 4)`), lalu `BarisMenu` per produk (favorit sesuai set dari `FavoritBuilder`).

### 3.3b Favorit (`favorite_page.dart`)

- `Scaffold(bg)` + `AppBar` (latar `bg`, `foregroundColor: ink`, `elevation: 0`, `titleSpacing: 0`, judul **"Favorit"** 18/800 ls −0.3).
- Body `FavoritBuilder` → `StreamBuilder<List<Produk>>` (`stream` dari `ProductRepository.stream()`, dibuat ulang saat `_muatUlang`):
  - Tunggu daftar favorit pertama (`!siap && !snap.hasError`) → `LoadingView` (agar tidak sempat terlihat "kosong").
  - Loading/error/empty lewat `keadaanStream` dengan `kosong` = tidak ada produk yang `favorit.contains(p.id)` → `EmptyView(favorite_border_rounded, "Belum ada favorit", "Ketuk ikon hati pada menu untuk menyimpannya di sini.")`.
- **Daftar**: urutan mengikuti katalog (`snap.requireData.where(p => favorit.contains(p.id))`), `ListView` padding atas 4 bawah 24, tiap item `BarisMenu(produk, favorit: true)`. Ketuk hati di sini → item langsung hilang dari daftar (stream favorit reaktif).

### 3.4 Kustomisasi (`screens/Kustomisasi.png`, `source/Kustomisasi.dc.html`)
 
Bottom sheet yang meluncur dari bawah, dibuka lewat `bukaKustomisasi(context, Produk p)` dari Menu, Beranda (Paling laris), Cari, dan Favorit. **Signature fungsi ini tidak boleh diubah.** Tanpa navbar dan tanpa strip keranjang.
 
- **Sheet** (`showModalBottomSheet`, `isScrollControlled: true`, `useSafeArea: true`): latar `bg` (putih), radius atas 28. Isinya `DraggableScrollableSheet` (`initialChildSize` 0.9, `maxChildSize` 0.9, `minChildSize` 0.5). Ditarik turun sampai batas bawah atau ketuk di luar sheet = batal, tidak ada yang masuk keranjang.
- **Handle** 40×4, warna `pending`, radius 2, margin atas 10 dan bawah 4.
- **Memuat konfigurasi**: harga Large dan daftar add-on dibaca dari dokumen `config/menu` (`hargaLarge`: int; `addOn`: peta nama → harga). Selama dibaca tampil `CircularProgressIndicator` `primary` di tengah sheet. Bila gagal dibaca, memakai nilai cadangan `hargaLarge` dan `addOnMenu` di `lib/data/dummy_data.dart`. (Tarif pajak juga ada di `config/menu`, tetapi dipakai Keranjang, bukan sheet ini.)
- **Isi** (`ListView`, padding 20 horizontal dan 12 vertikal, ikut `scrollController` sheet):
  1. **Header produk**: `ProductThumb` 64 (radius 10) · `SizedBox(14)` · kolom nama 18/700 ls −0.3 dan deskripsi 12/500 `muted` (maks. 2 baris, ellipsis) · harga dasar 15/800 `primary` di kanan.
  2. Jarak 20, lalu grup pilihan di bawah. **Produk Makanan tidak punya opsi minuman**; hanya field catatan.
  3. **Ukuran** (hanya bila `Produk.bisaLarge`): dua chip sama lebar **Regular** dan **Large +Rp4.000** (nominal dari `config/menu`), ikon `coffee_outlined` 16 (Regular) dan 20 (Large). Bawaan Regular.
  4. **Suhu** (sesuai `Produk.suhu`; tersembunyi bila kosong): chip **Panas** (`local_fire_department_outlined` 18) dan/atau **Es** (`ac_unit_rounded` 18). Bawaan = suhu pertama pada daftar produk, jika kosong Es.
  5. **Level gula**: **Tanpa · Sedikit · Normal · Manis**, bawaan Normal.
  6. **Level es** (hanya bila Suhu = Es): **Sedikit · Normal · Banyak**, bawaan Normal.
  7. **Add-on** (hanya yang diizinkan produk lewat `Produk.addOnBerlaku`; `addOn` null = semua add-on katalog; tersembunyi bila tidak ada): label "Add-on" 12/600 `muted`, lalu baris-baris add-on.
  8. **Catatan**: `TextField` hint "Catatan untuk barista (opsional)", ikon awal `edit_outlined` 20, padding vertikal 12.
- **Label grup** 12/600 `muted`, jarak ke chip 8; jarak antar-grup 14.
- **Chip pilihan**: tinggi 44, radius 14, sama lebar (`Expanded`) dengan jarak 8, teks 13/700 dengan `FittedBox(scaleDown)`. Terpilih: latar `primary`, teks/ikon putih. Tidak terpilih: latar `fill`, teks `textSecondary`. Transisi 150 ms.
- **Baris add-on**: tinggi 44 (target sentuh), padding horizontal 4, `InkWell` radius 12. Checkbox kecil 18×18 radius 5: terpilih latar `primary` + centang putih 14, kosong border 1.5 `disabled`. Nama 13/600, harga "+Rp5.000" 12/700 `muted` di kanan.
- **Footer** (tetap di bawah, border atas 1 `divider`, padding `fromLTRB(20, 12, 20, 20 + inset bawah)`): **stepper jumlah** tinggi 52, radius 16, latar `fill`, tombol − (nonaktif saat jumlah 1), angka 16/700 lebar 24, tombol +; jarak 12; tombol utama `Expanded` **"Tambah · Rp…"**. Seluruh isi sheet naik di atas keyboard (`viewInsets`) saat mengetik catatan.
- **Harga**: harga satuan = harga dasar + tambahan Large (bila Large) + jumlah harga add-on terpilih. Tombol menampilkan harga satuan × jumlah.
- **Tombol Tambah** → `CartProvider.addItem(CartItem(...))` lalu sheet ditutup (kembali ke layar asal). Add-on diurutkan menurut urutan katalog `config/menu` agar `kunci` item konsisten; item dengan `kunci` (`nama|opsi|catatan`) sama digabung (jumlah bertambah), opsi berbeda menjadi baris baru.
### 3.5 Keranjang (`screens/Keranjang.png`, `source/Keranjang.dc.html`)
 
Tanpa navbar dan tanpa strip keranjang. Padding 24 20 (isi `ListView` `fromLTRB(20, 16, 20, 100)`), gap 16.
 
- **Header**: tombol kembali 44 · "Keranjang" 22/700 ls −0.3 · kanan "3 item" 13/600 `muted`.
- **Segmented tipe pesanan** **Makan di tempat | Ambil sendiri** (latar `surface`, terpilih `tint`/`primary`) → `cart.setMakanDiTempat`.
- **Nomor meja** (hanya bila Makan di tempat; **wajib**): baris dengan garis bawah `divider`, label "Nomor meja" 14/500 `muted` di kiri, kolom isian angka di kanan (lebar 130, rata kanan, maks. 3 digit, hint "Isi meja", teks 14/700). Kosong atau 0 → saat tombol **Pesan** ditekan, kolom menampilkan `errorText` **"Nomor meja wajib diisi."** dan pesanan tidak dikirim. Tidak ada nilai bawaan.
- **Keadaan kosong**: "Keranjang masih kosong." 14/600 `muted`, rata tengah (padding vertikal 48); tombol Pesan disembunyikan.
- **Card** `surface` radius 20, padding horizontal 16, berisi baris item (pemisah `dividerSoft`): thumbnail 56 radius 10 (`ProductThumb`, foto Cloudinary bila ada) · nama 14/700 · opsi 12/500 `muted` (mis. "Large · Es · Gula normal · Es normal · + Extra shot"; Makanan menampilkan catatan) · harga 14/700 · stepper bulat − n + (lingkaran 32 border `outline`, ikon `primary`, hit area 44; jumlah 0 menghapus baris). Baris terakhir di card: **voucher**.
- **Baris voucher** (tinggi minimal 56): ikon `sell_outlined` 20 `primary` · teks 14/600 — **"Belum ada voucher"** atau **"KOPIKITA20 diterapkan"** · link **Ganti** 14/700 `primary` → sheet Ganti voucher (3.5a). Bila voucher terpasang tetapi tidak lagi memenuhi syarat (mis. subtotal turun di bawah minimal belanja): teks menjadi "KOPIKITA20 belum berlaku" dan di bawahnya alasan 12/500 `promoLabel` (mis. "Minimal belanja Rp50.000."); diskon dianggap Rp0 sampai syarat terpenuhi lagi.
- **Ringkasan datar** (13): Subtotal, Diskon (−, hanya bila ada), **Pajak {persen}%**, garis, **Total** 18/800. Catatan "Bayar di kasir dengan tunai atau QRIS." 12 `muted`.
  - **Voucher**: divalidasi ke `vouchers/{kode}` — harus `aktif`, `berlakuSampai` belum lewat, subtotal ≥ `minBelanja`. Tipe `persen` = `nilai`% × subtotal; tipe `potongan` = `nilai` rupiah. Diskon tidak pernah melebihi subtotal.
  - **Pajak** = tarif `config/menu.pajak` (pecahan, mis. `0.10` = 10%; bawaan 0.10 bila tidak terbaca) × (subtotal − diskon), dibulatkan.
  - Contoh angka: Subtotal Rp87.000, Diskon −Rp17.400 (KOPIKITA20, 20%), Pajak Rp6.960 (10% dari setelah diskon), Total Rp76.560.
- **Tombol utama** tetap di bawah (left/right 20, bottom 24): **"Pesan · Rp76.560"**. Selama diproses berlabel "Memproses..." dan tidak bisa ditekan ulang.
- **Alur Pesan** (satu transaction Firestore, tidak ada pesanan setengah jadi):
  1. Validasi nomor meja (bila Makan di tempat) dan status login.
  2. Baca `counters/antrean` (`tanggal`, `nomor`): **nomor antrean naik 1; bila `tanggal` berbeda dari hari ini, kembali ke 1** → "A-001".
  3. Cek tiap produk di keranjang belum `habis` dan voucher masih valid di server.
  4. Tulis `orders/{id}` berstatus `menunggu_bayar` (+ `createdAt`, `updatedAt` dari server) dan perbarui counter.
  5. Kosongkan keranjang, lepas voucher, reset nomor meja → buka tab **Pesanan → Aktif** (`OrdersPage.mintaAktif()`), layar Keranjang ditutup.
- **Error** (keranjang tetap utuh, tampil di SnackBar): tidak ada koneksi / koneksi lambat (batas 15 detik); menu habis atau sudah tidak tersedia ("{nama} sedang habis. Hapus dari keranjang dulu."); voucher tidak lagi valid; akses Firestore ditolak (rules); nomor meja kosong; sesi login berakhir.
### 3.5a Sheet Ganti voucher (`widgets/voucher_sheet.dart`; belum ada gambar)
 
Dibuka dari link **Ganti** di baris voucher Keranjang lewat `bukaGantiVoucher(context)`.
 
- **Sheet** (`showModalBottomSheet`, `isScrollControlled: true`, `useSafeArea: true`): latar `bg`, radius atas 28, tinggi mengikuti isi (maks. layar), naik di atas keyboard. Handle 40×4 `pending`.
- **Judul** "Pilih voucher" 18/800 ls −0.3 (padding `fromLTRB(20, 12, 20, 12)`).
- **Input kode manual** (padding horizontal 20): `TextField` (hint "Masukkan kode voucher", ikon awal `confirmation_number_outlined`, huruf kapital, aksi keyboard *done*) + tombol teks **Pakai** 14/700 `primary` (jarak 8). Galat tampil di bawah input: 12/600 `promoLabel`.
- **Daftar** (padding `fromLTRB(20, 0, 20, 24)`, jarak antar-kartu 10), sumber `users/{uid}.voucher` × `vouchers/{kode}` (dibaca sekali saat sheet dibuka):
  1. Opsi **Tanpa voucher**: tinggi 56, radius 18, ikon `block_rounded` 20 `muted`, label 14/700.
  2. **Kartu voucher**: latar `tint`, radius 18, padding 14 × 12, ikon `sell_outlined` 20 `primary` · kode 14/800 `primary` · info 12/500 `textSecondary` · bila tidak berlaku, alasan 12/600 `promoLabel`.
  - Border 1 `outline`; **terpilih** border 1.5 `primary` + ikon `check_circle_rounded` `primary` di kanan.
  - **Tidak memenuhi syarat** (tidak aktif, kedaluwarsa, atau subtotal di bawah `minBelanja`): diredupkan (opacity 0.55), tidak bisa diketuk, alasan tampil di kartu.
- **Memilih** voucher atau menekan **Pakai** memvalidasi ke `vouchers/{kode}` lewat `CartProvider.terapkanVoucher`. Berhasil → sheet menutup dan Keranjang langsung menghitung ulang diskon, pajak, dan total. Gagal → sheet tetap terbuka dengan pesan:
  - "Kode voucher tidak ditemukan.", "Voucher tidak aktif.", "Voucher sudah kedaluwarsa.", "Minimal belanja Rp50.000.", "Tidak ada koneksi internet.".
  - **Tanpa voucher** melepas voucher dan menutup sheet.
- **Keadaan**: memuat (spinner `primary` di tengah), error dengan tombol **Coba lagi** 14/700 `primary`, kosong "Kamu belum punya voucher." 13/500 `muted`.
### 3.5b Promo & Voucher (`screens/promo_page.dart`; belum ada gambar)
 
Daftar lengkap voucher milik pengguna. Dibuka dari tautan **Lihat semua** di bagian Voucher saya (Akun, 3.8); layar ini juga disiapkan untuk disambungkan dari Beranda.
 
- `Scaffold(bg)` + `AppBar` sama dengan Notifikasi dan Favorit (latar `bg`, `elevation: 0`, `titleSpacing: 0`, judul **"Promo & Voucher"** 18/800 ls −0.3).
- **Daftar** realtime: `users/{uid}.voucher` × `vouchers/{kode}`. `ListView` padding `fromLTRB(20, 8, 20, 24)`, jarak antar-kartu 10, memakai kartu voucher yang sama dengan 3.5a (latar `tint`, radius 18, border 1 `outline`).
  - Catatan di tiap kartu 12/600 `promoLabel`: syarat dan masa berlaku, mis. "Min. belanja Rp50.000 · Berlaku s.d. 31 Okt 2026".
  - Voucher yang **berlaku** di atas, ikon salin `copy_rounded` 18 `muted` di kanan; ketuk kartu = salin kode, SnackBar "Kode KOPIKITA20 disalin.".
  - Voucher **tidak aktif atau kedaluwarsa** di bawah, diredupkan (opacity 0.55), tidak bisa diketuk, catatan "Tidak aktif." atau "Sudah kedaluwarsa.".
- **Keadaan** (lewat `keadaanStream`): memuat → `LoadingView`; error → `ErrorView` ("Coba lagi"); kosong → `EmptyView(sell_outlined, "Belum ada voucher", "Voucher yang kamu dapat akan muncul di sini.")`.

### 3.6 Pesanan — Aktif (`screens/Pesanan-Aktif.png`, `source/Status.dc.html`)
- Judul "Pesanan Saya" 24/800. Tab teks **Aktif | Riwayat** (tinggi 44, garis bawah 2 `primary` di tab aktif, garis dasar 1 `divider`).
- **Kartu antrean** (radius 24, latar `primary`, teks `cream`, lingkaran deko `caramel` opacity 0.45): "Nomor antrean" 12/600 · **A-014** 48/800 · "Makan di tempat · Meja 7" 13 · badge status kanan (32 tinggi, latar `cream`, teks `primary` 13/800, mis. "Diproses").
- **Card stepper status** (putih, radius 20, bayangan `card`): 5 langkah vertikal sesuai status Firestore —
  `menunggu_bayar` "Menunggu bayar" → `dibayar` "Dibayar" → `diproses` "Diproses" → `siap` "Siap diambil" → `selesai` "Selesai". (`batal` ditampilkan sebagai badge "Dibatalkan" di Riwayat.)
  - Selesai: titik 28 latar `primary` + centang putih, garis penghubung `primary`.
  - Sekarang: titik `caramel`, label 14/800.
  - Belum: titik putih border 2 `pending`, label muted, garis `outline`.
  - Tiap langkah ada catatan 12 muted (mis. "Barista sedang membuat pesananmu").
- **Card detail**: baris item "1× Kopi Susu Kita (Large, Es) … Rp31.000", garis, "Total dibayar" + total 16/800 `primary`.
- Bawah: strip keranjang + navbar (tab Pesanan aktif). Status diperbarui realtime (Firestore stream).

### 3.7 Pesanan — Riwayat (`screens/Pesanan-Riwayat.png`, `source/Riwayat.dc.html`)
- Header & tab sama, tab Riwayat aktif.
- Dikelompokkan per bulan (header 13/700 muted, mis. "Oktober 2026"). Tiap pesanan baris datar (padding 14 0, garis `divider`): thumbnail 48 radius 10 · ringkasan item 14/700 (ellipsis) · "8 Okt · Selesai" 12 muted · kanan: total 14/800 + link "Pesan lagi" 12/700 `primary`.

### 3.8 Akun (`screens/Akun.png`, `source/Akun.dc.html`)
- Judul "Akun" 24/800.
- Card profil (putih, radius 20, padding 14): avatar inisial 48 bulat latar `tint` · nama 16/800 · email 12 muted. **Hanya tampilan** — tidak bisa diketuk dan tanpa chevron (chevron di `screens/Akun.png` diabaikan); edit lewat baris "Edit profil".
- **Voucher saya**: judul 16/800; daftar horizontal kartu 200×76 radius 18, latar `tint`, border 1.5 dashed `caramel`: kode 14/800 `primary` + info 12 `textSecondary`. Data dari Firestore: hanya voucher milik pengguna (`users/{uid}.voucher` × `vouchers/{kode}`) yang `aktif` dan belum kedaluwarsa, realtime. Kosong → "Belum ada voucher." 13/500 `muted`. Di bawah daftar tautan **Lihat semua** 13/700 `primary` → Promo & Voucher (3.5b).
- **Avatar profil** di card: bulat **48**, `ClipOval`. Bila `users/{uid}.fotoUrl` terisi → `Image.network` (`BoxFit.cover`); bila kosong atau gagal dimuat → latar `tint` dengan inisial nama 16/800 `primary` (`errorBuilder` menangani kasus jaringan mati). Saat pertama kali belum ada foto, tampilan persis seperti sebelumnya (inisial).
- **Baris pengaturan datar** (`_barisPengaturan`: 52 tinggi, **ikon kiri 22** + jarak 12, label 14/600, chevron muted di kanan, garis bawah `divider`), urutan dari atas:
  1. **Notifikasi pesanan** (ikon `notifications_none_rounded`) — **toggle langsung di baris**, bukan halaman tersendiri: `Switch` di kanan (thumb aktif `primary`) menggantikan chevron; ketuk baris = membalik toggle. Nilai dibaca dari `users/{uid}.notifikasi` lewat `UserRepo.stream()` yang sama dengan card profil; ubah → `UserRepo.update({'notifikasi': v})` (cache lokal Firestore membuat switch langsung berubah); gagal → SnackBar `Gagal menyimpan: {e}`. (`NotificationPage` tetap ada, hanya dibuka dari tombol lonceng di Beranda.)
  2. **Edit profil** (ikon `person_outline_rounded`) — membuka `showModalBottomSheet` (radius atas 24, latar `surface`, padding 20 + naik setinggi keyboard lewat widget `_NaikKeyboard`). **Animasi keyboard harus halus**: `_NaikKeyboard` adalah satu-satunya widget yang membaca `MediaQuery.viewInsetsOf(context)` sehingga hanya dia yang dibangun ulang tiap frame (isi sheet tidak), dan memakai `AnimatedPadding` (120 ms, `easeOut`) untuk menghaluskan inset keyboard yang datang patah-patah. Jangan memakai `autofocus` di sheet — keyboard dan animasi sheet naik bersamaan membuat patah-patah. Isi sheet, dari atas:

```dart
class _NaikKeyboard extends StatelessWidget {
  final Widget child;
  const _NaikKeyboard({required this.child});
  @override
  Widget build(BuildContext context) => AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );
}
```
     - Judul "Edit profil" 18/800 ls −0.3.
     - **Avatar besar 84** (`ClipOval`) di tengah, menampilkan urutan prioritas: (a) `Image.memory` bytes yang baru dipilih (`preview` lokal), (b) `Image.network(users/{uid}.fotoUrl)`, (c) latar `tint` + inisial 24/800 `primary`. Di pojok kanan-bawah avatar, **tombol kamera** bulat 32 (latar `primary`, ikon `photo_camera_outlined` 18 putih, `clipBehavior: Clip.none`, posisi `right: -4, bottom: -4`); target sentuh 44×44 (padding implisit). Ketuk → `image_picker` (`maxWidth: 512`, `imageQuality: 85`); batal memilih → tidak ada perubahan state.
     - Label "Nama" 12/700 `textSecondary`, field nama (52, radius 14, latar `fill`, tanpa autofocus, `textCapitalization: words`). Validasi: nama < 2 karakter ditolak → `errorText` di bawah field "Nama minimal 2 karakter." (hilang saat mengetik).
     - **Batas foto** (dicek di `_pilihFoto`, setelah kompresi `maxWidth: 512`, `imageQuality: 85`): ekstensi harus `jpg/jpeg/png/webp` → selain itu "Format foto harus JPG, PNG, atau WEBP."; ukuran ≤ 2 MB (`_maxFotoBytes`) → selain itu "Ukuran foto maksimal 2 MB.". Gagal cek → foto tidak diganti, pesan tampil sebagai error umum.
     - Tombol utama **Simpan** (52, radius 16). Bila `_fotoBaru` ada → unggah ke Cloudinary (`CloudinaryAccService.uploadBytes`, folder `foto-profil`, unsigned preset `kopikita_menu`) → dapat `secure_url` → tulis `users/{uid}.fotoUrl`. Selalu tulis `users/{uid}.nama`. SnackBar "Profil diperbarui." setelah sheet ditutup. Gagal unggah/tulis → error umum `Gagal menyimpan: {e}`, sheet tetap terbuka.
     - **Aturan error di bottom sheet**: jangan pakai SnackBar (dirender di Scaffold di belakang sheet → tertutup sheet/keyboard). Error per field → `InputDecoration(errorText: ...)`; error umum → widget `_ErrorUmum` (teks 12/600 `danger`, jarak atas 12) tepat di atas tombol Simpan.
  3. **Ubah kata sandi** (ikon `lock_outline_rounded`) — bottom sheet `_SheetUbahSandi` dengan gaya **sama dengan Edit profil** (`showModalBottomSheet`, `isScrollControlled: true`, latar `surface`, radius atas 24, padding 20 + `_NaikKeyboard` agar sheet naik halus di atas keyboard): judul "Ubah kata sandi" 18/800 ls −0.3 → jarak 16 → label "Kata sandi lama" 12/700 `textSecondary` + field tersamar (`obscureText`, tanpa autofocus, aksi keyboard *next*) → jarak 14 → label "Kata sandi baru" + field tersamar (placeholder "Minimal 6 karakter", aksi *next*) → jarak 14 → label "Konfirmasi kata sandi baru" + field tersamar (placeholder "Ulangi kata sandi baru", aksi *done* = simpan) → jarak 16 → tombol utama **Simpan** (`PrimaryButton`, teks "Menyimpan..." dan field nonaktif saat proses). Validasi lokal dulu (tanpa memanggil Firebase), tampil sebagai `errorText` di bawah field (hilang saat field diketik): sandi lama kosong → "Wajib diisi."; sandi baru < 6 → "Minimal 6 karakter."; konfirmasi ≠ baru → "Tidak sama dengan kata sandi baru.". Lolos → `AuthService.ubahSandi(lama, baru)` (`reauthenticateWithCredential(EmailAuthProvider.credential(email, lama))` → `updatePassword(baru)`). Sukses → sheet ditutup + SnackBar "Kata sandi berhasil diubah."; `wrong-password`/`invalid-credential` → `errorText` field sandi lama "Kata sandi lama salah." (sheet tetap terbuka); error lain (jaringan, `too-many-requests`) → `_ErrorUmum` dengan pesan `AuthService.pesanError`. Reset lewat email tetap ada di Login ("Lupa kata sandi?").
  4. **Keluar** (ikon `logout_rounded`) — **dipisah** jarak 24 dari baris di atasnya, ikon + label warna `danger`, tanpa chevron, tanpa garis bawah. Ikon logout berukuran **19** (bukan 22) di dalam kotak lebar 22 yang sama: glyph `logout` lebih lebar (x 2–22 dari grid 24, ikon lain 4–20), jadi dikecilkan agar tepi kirinya sejajar ikon di atasnya; label tetap mulai di x yang sama. `AuthService.keluar()` (hanya `signOut`, tanpa navigasi manual); AuthGate otomatis kembali ke `LoginPage`.
- **Field Firestore baru:** `users/{uid}.fotoUrl: string` (opsional, kosong/default `""`). URL `https://res.cloudinary.com/...`. Karena ini penambahan skema, **wajib disetujui P1** dan dicatat di kontrak `PEMBAGIAN_TUGAS.md` sebelum merge.
- Bawah: strip keranjang + navbar (tab Akun aktif).

---

## 4. Implementasi Flutter — saran

```dart
// lib/theme/app_colors.dart
class AppColors {
  static const primary = Color(0xFF6B3216);
  static const caramel = Color(0xFFC47A3A);
  static const ink = Color(0xFF2B1810);
  static const textSecondary = Color(0xFF5A4436);
  static const muted = Color(0xFF7A6355);
  static const disabled = Color(0xFFB9A89B);
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFCF9F5);
  static const fill = Color(0xFFF3EADF);
  static const tint = Color(0xFFF1E4D4);
  static const cartStrip = Color(0xFFF6ECE0);
  static const cream = Color(0xFFFBEFE0);
  static const divider = Color(0xFFEDE3D8);
  static const dividerSoft = Color(0xFFF0E7DC);
  static const dividerList = Color(0xFFE9DED2);
  static const outline = Color(0xFFE6D9CB);
  static const pending = Color(0xFFD9CABB);
  static const promoLabel = Color(0xFF9A5A1C);
}
```

- `ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.bg, fontFamily: 'PlusJakartaSans', colorScheme: ColorScheme.light(primary: AppColors.primary, secondary: AppColors.caramel, surface: AppColors.surface, onSurface: AppColors.ink, outline: AppColors.outline), dividerColor: AppColors.divider)`. Matikan `surfaceTintColor` pada Card/NavigationBar/BottomSheet agar warnanya bersih.
- Daftarkan font di `pubspec.yaml` dari `design/fonts/PlusJakartaSans-Variable.ttf` (atau pakai `google_fonts`).
- Buat widget bersama: `AppBottomBar` (strip keranjang + navbar), `FloatingCard`, `SegmentedPill`, `ChoiceChipTile`, `FlatListRow`, `ProductThumb` (radius 10, placeholder `tint`, nanti `CachedNetworkImage` dari Cloudinary), `PrimaryButton`, `OrderStatusStepper`.
- Routing (mis. `go_router`): `/login`, `/` (Beranda), `/menu?metode=pickup|dine`, `/menu/:id` (Kustomisasi sebagai sheet), `/keranjang`, `/pesanan` (tab aktif/riwayat), `/akun`. Shell route untuk 4 tab navbar.
- Teks harga: format Rupiah tanpa desimal dengan titik ribuan — "Rp22.000" (`NumberFormat.currency(locale: 'id', symbol: 'Rp', decimalDigits: 0)`).

## 5. Belum didesain
Lupa kata sandi, Notifikasi, Edit profil, pencarian menu, keadaan error/loading, serta aplikasi staf & admin. (Detail promo/voucher sudah dirancang di 3.5b; sheet Ganti voucher di 3.5a.) Ikuti token dan komponen di atas untuk layar-layar yang belum didesain.