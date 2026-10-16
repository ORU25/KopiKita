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

Urutan alur: **Login (↔ Daftar) → Beranda → Menu → Kustomisasi → Keranjang → Pesanan (Aktif) ↔ Riwayat**, plus **Akun**.

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
  - `ConnectionState.waiting` (pertama kali dibuka) → `Scaffold` dengan `CircularProgressIndicator` di tengah. Splash sederhana agar tidak berkedip Login dulu.
  - `snapshot.hasData` (sudah login) → `NavigationPage` (tab Beranda). Setiap transisi dari belum-login ke sudah-login **mereset tab navbar ke Beranda** (`NavigationPage.tab.value = tabBeranda`) lewat `addPostFrameCallback`.
  - Selainnya (belum login) → `LoginPage`.
- Karena AuthGate memantau `authStateChanges()`, layar Login/Tidak perlu navigasi manual: berhasil login → AuthGate otomatis pindah ke Beranda; `AuthService.keluar()` → AuthGate otomatis kembali ke Login.
- **Tidak ada provider user.** Data profil (`users/{uid}`) dibaca langsung oleh layar yang membutuhkannya lewat `UserRepo` (`lib/services/user_repo.dart`):
  - `UserRepo.stream()` → `Stream<DocumentSnapshot>` untuk Beranda (sapaan) dan Akun.
  - `UserRepo.ambil()` → sekali baca, untuk prefill Edit profil dan Notifikasi.
  - `UserRepo.update(data)` → tulis `users/{uid}` (ganti nama, toggle notifikasi).
  - Getter aman null-safe: `namaDari`, `emailDari`, `roleDari`, `voucherDari`, `notifikasiDari`.

### 3.2 Beranda (`screens/Beranda.png`, `source/Main.dc.html`)
- **Banner** tinggi 280, radius bawah 24, gambar `banner-beranda.jpg` cover, dengan gradasi gelap `ink` 0% (35% tinggi) → 85% (bawah) agar sapaan terbaca. Tanpa logo. Tombol notifikasi bulat 44 di kanan atas (top 24, right 20; latar `rgba(251,239,224,0.14)`, ikon `cream`).
- **Sapaan di atas card** (menimpa banner, top 152.4, kiri/kanan 32 = tepi card 16 + padding 16 agar sejajar isi card, bukan sudut lengkungnya): "Hai, Rina" 32/800 putih ls −0.5 line-height 1.2, jarak 4 (rapat), subjudul "Mau ngopi apa hari ini?" 16/600 putih line-height 1.2, lalu jarak 12 ke card. Tanpa indikator voucher.
- **Card melayang** (top 226, inset 16, padding 16, gap 14):
  1. Dua aksi besar sama lebar: **Ambil Sendiri** (gambar tas) dan **Makan di Tempat** (gambar cangkir). Gambar tinggi 48 dalam area 76×56, tanpa latar; label 14/700 di bawah (gap 8). Ketuk → Menu dengan metode terpilih.
  2. Garis 1px `dividerSoft`.
  3. Empat aksi cepat (ikon garis 24 stroke 1.4 `primary`, label 12/500 `textSecondary`, lebar 72): **Promo**, **Voucher**, **Favorit**, **Pesan Lagi**.
- **Promo untukmu** (top 495): judul 16/800 + "Lihat semua" 13/700 `promoLabel`.
- **Slider promo** (top 525): kartu 290×128, radius 24, padding 14 20, jarak 12, snap ke kiri dengan padding 20 (Flutter: `PageView` `viewportFraction ≈ 0.78` + `padEnds: false`, atau `ListView` + `PageScrollPhysics`). Tiap kartu = **gambar banner** (`Image.asset`, `BoxFit.cover`, radius 24; teks promo sudah ada di gambar, `semanticLabel` berisi isi promo). Rasio gambar ≈ 2,27:1 (sumber 1889×832 di `kopikita-design/assets/bannerPromo1–3.png`, disalin ke `assets/images/banner-promo-1..3.png`).
  - Kartu 1: `banner-promo-1.png` — Pelanggan baru · Diskon 20% pesanan pertama · KOPIKITA20.
  - Kartu 2: `banner-promo-2.png` — Promo mingguan · Beli 2 minum gratis 1 · KITAB2G1.
  - Kartu 3: `banner-promo-3.png` — Paket pagi · Kopi + croissant mulai Rp35.000.
- **Indikator dot** (top 659): aktif 20×6 `primary`, lainnya 6×6 `pending`, gap 6. Dot bisa ditekan → slider beranimasi ke kartu itu (300 ms, easeOut). Area tap: baris tinggi 44, dot terdekat dalam radius 22 dari tengahnya (target 44×44 tanpa mengubah jarak visual).
- **Paling laris** (di bawah dot, jarak 14): judul 16/800 + link "Lihat menu" 13/700 `promoLabel` (→ tab Menu). Lalu 4 **baris datar** (data `rekomendasi`; padding 12 0 di dalam inset 20, garis bawah `dividerList`, baris terakhir tanpa garis, gap 14): thumbnail 64 radius 10 · nama 14/700 · deskripsi 12 muted (1 baris, ellipsis) · harga 14/800 `primary` · tombol + 36 (hit 44). Ketuk baris / + → sheet Kustomisasi.
- Bawah: strip keranjang + navbar (tab Beranda aktif).

### 3.3 Menu (`screens/Menu.png`, `screens/Menu-header-collapsed.png`, `source/Menu.dc.html`)
Kolom: header (tidak ikut scroll) + area scroll + sheet navbar di bawah.

- **Header collapsing** (padding 20 20 10, latar `bg`):
  - *Expanded* (scroll di atas): tombol kembali bulat 44 putih · "KopiKita" 20/800 · tombol info bulat 44. Di bawahnya segmented **Ambil Sendiri | Makan di Tempat** (terpilih latar `primary`).
  - *Collapsed* (setelah scroll > 60, kembali saat < 8 — beri histeresis agar tidak berkedip): tombol kembali · dua baris "{Metode} · KopiKita" 14/800 + "Outlet Utama · 350 m dari kamu" 12/500 muted · pill "Ubah" 32 (putih, 12/800 `primary`).
  - Flutter: `CustomScrollView` + `SliverPersistentHeader`/`SliverAppBar` (pinned) yang berganti konten berdasarkan offset, atau `NestedScrollView`.
- **Bar filter sticky** (pinned di atas area scroll, latar `bg`, padding 6 20 10): chip kategori geser horizontal (tinggi 40, radius penuh, 13/700; terpilih latar `primary` teks putih, lainnya putih teks ink) — **Rekomendasi, Kopi, Non-Kopi, Makanan** — + tombol cari bulat 44 di kanan.
- **Rekomendasi**: judul 16/800, lalu daftar horizontal kartu **ringkas memanjang** 276 lebar (putih, radius 20, padding 10, bayangan `card`, snap): thumbnail 64 radius 10 · nama 14/700 (1 baris, ellipsis) · deskripsi 12 muted · harga 13/800 `primary` · tombol + 36. Kartu berikutnya terpotong di tepi agar terlihat bisa digeser.
- **Daftar menu vertikal** dikelompokkan per kategori: header kategori "Kopi" 16/800 + "3 menu" 12/600 muted. Tiap item **baris datar** (padding 14 0, garis bawah `dividerList`, gap 14):
  - Thumbnail 84×84 radius 10.
  - Nama 14/700, deskripsi 12 muted (line-height 1.35), harga 14/800 `primary` di bawah.
  - Kolom kanan: tombol hati 36 (tidak aktif garis `muted`; aktif terisi `#9A5A1C`) di atas, tombol + 36 di bawah.
  - Menu habis: opacity 0.6, badge "Habis" (22 tinggi, latar ink, teks putih 12/700) di pojok kiri atas thumbnail, tombol + `disabled`.
- Ketuk + / item → Kustomisasi. Padding bawah area scroll ≥ tinggi sheet navbar (~156) agar item terakhir tidak tertutup.

### 3.4 Kustomisasi (`screens/Kustomisasi.png`, `source/Kustomisasi.dc.html`)
Modal bottom sheet yang meluncur dari bawah di atas layar Menu (Flutter: `bukaKustomisasi()` → `showModalBottomSheet(isScrollControlled: true, useSafeArea: true)` + `DraggableScrollableSheet(expand: false, initial/max 0.9, min 0.5)`; `ListView` memakai `scrollController` sheet). Tanpa navbar, tanpa hero, tanpa tombol X.
- **Batal**: tarik sheet ke bawah (dari handle, atau dari isi saat scroll di posisi atas) atau tap area gelap di luar sheet. Tidak ada item yang masuk keranjang.
- Sheet latar `bg` (putih, seperti halaman lain), radius atas 28, tinggi awal 90% layar, handle 40×4 `pending`. Konten padding 12 20, gap 14; bawah sheet diberi padding `viewInsets` agar footer naik di atas keyboard:
  - Nama 22/700 + deskripsi 13 muted · harga dasar 16/800 `primary` kanan. Blok ini diberi inset ekstra 4 (total 24 dari tepi sheet) karena teks polos di tepi 20 terlihat lebih mepet dibanding tombol/chip berlatar.
  - **Ukuran** dan **Suhu** masing-masing satu baris penuh (bertumpuk, bukan berdampingan), memakai chip pilihan berikon (ikon di kiri teks, gap 6, warna mengikuti teks): Regular (cangkir 16) / Large +Rp4.000 (cangkir 20); Panas (api 18) / Es (kristal es 18). Label grup 12/600 muted.
  - **Level gula**: Tanpa · Sedikit · Normal · Manis (chip pilihan).
  - **Level es**: Sedikit · Normal · Banyak (saran implementasi: sembunyikan bila Suhu = Panas).
  - **Add-on**: label "Add-on" + baris checkbox **kecil tanpa garis pemisah**: tinggi 44 (target sentuh), inset 4 kiri-kanan (sejajar nama menu, tidak melebihi elemen lain), ripple radius 12; checkbox 18 radius 5 (aktif latar `primary` + centang putih 14; kosong border 1.5 `disabled`), gap 10, nama 13/600, harga "+Rp5.000" 12/700 muted. Contoh: Extra shot, Oat milk, Sirup karamel.
  - Field catatan: 44 tinggi, radius 14, latar `fill`, ikon pensil, placeholder "Catatan untuk barista (opsional)".
- Footer tetap (border atas `divider`, padding 12 20 20): stepper jumlah (52 tinggi, radius 16, latar `fill`, tombol −/+ 40) + tombol utama "Tambah · Rp31.000" (harga = total pilihan × jumlah). Tambah → item masuk keranjang, sheet tertutup.

### 3.5 Keranjang (`screens/Keranjang.png`, `source/Keranjang.dc.html`)
Tanpa navbar. Padding 24 20, gap 16.
- Header: tombol kembali 44 · "Keranjang" 22/700 · kanan "3 item" 13/600 muted.
- Segmented tipe pesanan **Makan di tempat | Ambil sendiri** (latar putih, terpilih `tint`/`primary`). Bila Makan di tempat: baris "Nomor meja … 7" (48 tinggi, garis bawah).
- Card putih radius 20 berisi item (baris dengan pemisah `dividerSoft`): thumbnail 56 radius 10 · nama 14/700 · opsi 12 muted (mis. "Large · Es · Gula normal · Es normal · + Extra shot") · harga 14/700 · stepper bulat − n +. Baris terakhir di card: voucher "KOPIKITA20 diterapkan" + link "Ganti".
- Ringkasan datar (13): Subtotal, Diskon (−), Pajak 10%, garis, **Total** 18/800. Catatan: "Bayar di kasir dengan tunai atau QRIS." 12 muted.
- Tombol utama tetap di bawah (left/right 20, bottom 24): "Pesan · Rp76.560" → buat pesanan status `menunggu_bayar` → layar Pesanan (Aktif).
- Contoh angka: Subtotal Rp87.000, Diskon −Rp17.400 (20%), Pajak Rp6.960 (10% dari setelah diskon), Total Rp76.560.

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
- Card profil (putih, radius 20, padding 14): avatar inisial 48 bulat latar `tint` · nama 16/800 · email 12 muted · chevron.
- **Voucher saya**: judul 16/800, daftar horizontal kartu 200×76 radius 18, latar `tint`, border 1.5 dashed `caramel`: kode 14/800 `primary` + info 12 `textSecondary`.
- Baris pengaturan datar (52 tinggi, 14/600, chevron muted, garis bawah `divider`):
  - **Edit profil** — membuka `showModalBottomSheet` (radius atas 24, latar `surface`, padding 20 + `viewInsets.bottom` agar naik di atas keyboard): judul "Edit profil" 18/800 ls −0.3 → label "Nama" 12/700 `textSecondary` → field nama (52, radius 14, latar `fill`, autofocus, `textCapitalization: words`) → tombol utama **Simpan** (52, radius 16). Simpan → tulis `users/{uid}.nama` lewat `UserRepo.update`; SnackBar "Profil diperbarui." Validasi: nama < 2 karakter ditolak.
  - **Notifikasi** — membuka halaman `NotificationPage`: `AppBar` latar `bg`, judul "Notifikasi" 18/800 ls −0.3, `titleSpacing: 0`. Satu `SwitchListTile` untuk `users/{uid}.notifikasi` (thumb aktif `primary`), judul "Notifikasi pesanan" 14/700, subtitle "Dapatkan pemberitahuan saat status pesananmu berubah." 12 muted. Perubahan langsung ditulis ke Firestore (optimistic UI + rollback bila gagal).
  - **Keluar** — `AuthService.keluar()` (hanya `signOut`, tanpa navigasi manual); AuthGate otomatis kembali ke `LoginPage`.
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
Lupa kata sandi, Notifikasi, Edit profil, pencarian menu, detail promo/voucher, keadaan kosong (keranjang kosong → strip keranjang disembunyikan; belum ada pesanan aktif), keadaan error/loading, serta aplikasi staf & admin. Ikuti token dan komponen di atas untuk layar-layar ini.