# Pembagian Tugas KopiKita — 5 Orang, 7 Hari

## Kondisi awal (per commit `1a06aca`)

- **Sudah ada:** seluruh UI aplikasi pelanggan (Login, Daftar, Beranda, Menu, Kustomisasi, Keranjang, Pesanan Aktif/Riwayat, Akun) sesuai `kopikita-design/design/DESIGN.md`, state keranjang memakai `provider`.
- **Login Google dihapus** — autentikasi hanya email/kata sandi (tanpa `google_sign_in`, tanpa SHA-1).
- **Belum ada:** Firebase (Auth, Firestore), foto produk dari Cloudinary, layar yang belum didesain (Lupa kata sandi, Edit profil, Notifikasi, Cari menu, keadaan kosong/loading/error), serta **web Staf & Admin**.
- Semua data masih dari `lib/data/dummy_data.dart`; titik yang harus diganti sudah ditandai komentar `ponytail:`.

## Ringkasan pembagian

| Orang | Peran | Beban | Area utama |
|---|---|---|---|
| **P1** | Lead backend + Web | **Paling berat** | Setup Firebase, skema & rules Firestore, Cloudinary, **Web Staf**, **Web Admin**, deploy Hosting |
| **P2** | Auth & Akun | Sedang | Login & Daftar email/kata sandi, Lupa kata sandi, AuthGate, Akun, Edit profil, Keluar |
| **P3** | Menu & Katalog | Sedang | Produk dari Firestore, foto Cloudinary, Beranda (pemilik tunggal), Menu, Cari, Favorit |
| **P4** | Keranjang & Checkout | Sedang | Kustomisasi + `config/menu`, voucher, checkout → buat pesanan + nomor antrean, Voucher saya |
| **P5** | Pesanan & QA/Rilis | Sedang | Pesanan Aktif realtime, Riwayat, Pesan lagi, notifikasi in-app, test end-to-end, build APK, README |

> P1 memegang semua yang "di luar aplikasi pelanggan" sehingga P2–P5 cukup fokus di `lib/` aplikasi Android.

**Legenda:** ⏳ = **harus menunggu** pekerjaan orang lain di-merge dulu (lihat [Ketergantungan](#ketergantungan--yang-harus-menunggu)).

---

## Kontrak data Firestore (dikunci P1 di Hari 1)

Semua orang menulis kode berdasarkan skema ini. Perubahan skema **wajib** lewat P1 dan diumumkan di grup.

```
users/{uid}
  nama: string
  email: string
  role: "pelanggan" | "staf" | "admin"     // default "pelanggan"
  favorit: [productId]
  voucher: [kodeVoucher]                    // voucher yang dimiliki
  notifikasi: bool
  createdAt: timestamp

products/{id}
  nama, deskripsi: string
  harga: int                                // harga dasar
  kategori: "Kopi" | "Non-Kopi" | "Makanan"
  gambarUrl: string                         // URL Cloudinary
  habis: bool
  rekomendasi: bool                         // tampil di Rekomendasi / Paling laris
  urutan: int

config/menu
  hargaLarge: int                           // 4000
  addOn: { "Extra shot": 5000, "Oat milk": 6000, "Sirup karamel": 4000 }
  pajak: 0.10

vouchers/{kode}                             // id dokumen = kode, mis. KOPIKITA20
  info: string                              // "Diskon 20% · min. Rp50.000"
  tipe: "persen" | "potongan"
  nilai: int                                // 20 (persen) atau 5000 (rupiah)
  minBelanja: int
  berlakuSampai: timestamp
  aktif: bool

orders/{id}
  uid: string
  nomor: string                             // "A-014"
  makanDiTempat: bool
  nomorMeja: int | null
  items: [{ productId, nama, gambarUrl, harga, jumlah, ukuran, suhu, gula, es, addOn[], catatan, makanan }]
  subtotal, diskon, pajak, total: int
  voucher: string | null
  status: "menunggu_bayar" | "dibayar" | "diproses" | "siap" | "selesai" | "batal"
  createdAt, updatedAt: timestamp

counters/antrean
  tanggal: "2026-10-14"                     // reset nomor tiap hari
  nomor: int                                // dinaikkan lewat transaction saat checkout
```

**Aturan alur status:** pelanggan membuat pesanan (`menunggu_bayar`) dan hanya boleh mengubahnya ke `batal` selama masih `menunggu_bayar`. Staf mengubah `dibayar → diproses → siap → selesai` atau `batal`. Admin boleh semuanya.

> ponytail: tanpa Cloud Functions (cukup paket Spark gratis). Nomor antrean dibuat lewat Firestore transaction dari aplikasi; role dicek di Security Rules lewat `users/{uid}.role`. Push notification (FCM) butuh Functions/Blaze — diganti notifikasi in-app dari stream pesanan.

---

## Analisis konflik merge

Pembagian awal **belum** cukup aman: beberapa file disentuh 3–5 orang. Di bawah ini titik rawannya dan solusinya (sudah diterapkan ke rincian tugas).

| File / titik rawan | Disentuh oleh | Masalah | Solusi |
|---|---|---|---|
| `lib/data/dummy_data.dart` | Semua (diimpor 7 file) | Memindah model ke `lib/models/` mengubah import di semua layar → konflik massal | P1 memindah class ke `lib/models/` lalu **`dummy_data.dart` meng-`export` model itu** → import di layar tidak perlu diubah. Tiap pemilik layar menghapus import dummy-nya sendiri. P5 menghapus file ini paling akhir (Hari 6). |
| `pubspec.yaml` / `pubspec.lock` | Semua (tambah package) | Konflik di lock file hampir pasti | P1 menambah **semua** package di PR Fondasi Hari 1. Butuh package baru → minta P1. |
| `lib/main.dart` | P1 (Firebase init), P2 (AuthGate) | Dua orang mengedit `main()` | P1 hanya menambah `Firebase.initializeApp()` di PR Fondasi; setelah itu **hanya P2** yang mengedit. Jangan tambah provider baru — pakai `StreamBuilder` + repository. |
| `lib/models/cart_item.dart` | P1 (`toMap`), P4 (`productId`), P5 (Pesan lagi) | Tiga orang mengubah class yang sama | P1 menambah `productId`, `gambarUrl`, `toMap()`/`fromMap()` di PR Fondasi. Setelah itu milik P4. |
| `home_page.dart` | P2 (sapaan nama, notifikasi), P3 (Paling laris), P4 (Promo/Voucher), P5 (Pesan Lagi) | Aksi cepat Promo/Voucher/Favorit/Pesan Lagi ada di baris 339–355 yang berdempetan → pasti konflik | **Hanya P3** yang mengedit `home_page.dart`. Orang lain membuat halaman/fungsinya di file sendiri, lalu P3 yang menyambungkan (Hari 5). |
| `account_page.dart` | P2 (profil, pengaturan), P4 (Voucher saya) | Dua orang di file yang sama | Berurutan: P2 merge Akun dulu (Hari 4), ⏳ P4 baru mengganti sumber data Voucher saya (Hari 5). |
| `cart_provider.dart` → `pesananAktif` | P4 (checkout), P5 (Pesanan Aktif membaca field ini) | Jika P4 menghapus field sebelum P5 pindah ke stream, layar Pesanan gagal compile | ⏳ P4 baru menghapus `pesananAktif` setelah PR stream P5 di-merge (Hari 3). |
| `ProductThumb` (`common.dart`) | Pemilik: P3. Dipanggil P3, P4 (Keranjang), P5 (Pesanan) | Ganti parameter → pemanggil lain rusak | P3 **menambah** parameter opsional `url`, **jangan hapus/rename** `nama`. |
| `bukaKustomisasi(context, Produk p)` | Pemilik: P4. Dipanggil P3 | Ganti signature → Menu & Beranda rusak | Signature **dibekukan**. `Produk` sudah membawa `id` dari P1. |
| `config/menu` | Semula P3 (repository) dipakai P4 | P4 menunggu P3 | Dipindah: P4 yang membaca `config/menu` sendiri → P3 & P4 bebas paralel. |
| `test/widget_test.dart` | P4 (test CartProvider: diskon hardcode 20%), P2 (Login→Beranda butuh Firebase), P5 | Test rusak saat logika berubah | Siapa yang membuat test gagal **memperbaikinya di PR yang sama**. |
| `DESIGN.md` | Semua | Semua menambah subbagian di titik yang sama + mengedit bagian 5 | Tiap orang hanya mengedit bagiannya; layar baru diletakkan **tepat setelah** bagian terkait (P2 setelah 3.1, P3 setelah 3.3, P4 setelah 3.5, P5 di 3.6/3.7, P1 bagian baru `## 6` di akhir). Bagian 5 "Belum didesain" **hanya diedit P5** di Hari 7. |
| `firestore.rules` | P1, tapi memengaruhi semua | Rules ketat terlalu awal memblokir orang lain | Hari 1–4 pakai *test mode* (berkedaluwarsa), rules final Hari 5, semua uji ulang Hari 6. |

**Kesimpulan:** dengan solusi di atas, file yang diedit bersamaan tinggal `test/widget_test.dart` dan `DESIGN.md`, dan keduanya diedit di blok yang berbeda. Semua edit lain punya satu pemilik atau sudah diurutkan dengan ⏳.

---

## Ketergantungan — yang harus menunggu

| # | Yang menunggu | Menunggu apa | Dari | Target siap | Sambil menunggu, kerjakan |
|---|---|---|---|---|---|
| 1 | **P2, P3, P4, P5** | **PR Fondasi**: Firebase init, package, `lib/models/`, `CartItem.toMap`, `firebase_options.dart`, seed data | P1 | **Akhir Hari 1** | Hanya buat **file baru** (layar Lupa kata sandi, Cari, sheet Ganti voucher, empty state). Jangan sentuh file lama sampai PR Fondasi di-merge. |
| 2 | ~~P2 (Google Sign-In)~~ | **Dihapus** — login Google tidak dipakai, tidak perlu menunggu SHA-1 | — | — | — |
| 3 | P4 (hapus `pesananAktif`) | Pesanan Aktif sudah memakai stream Firestore | P5 | Hari 3 | Kerjakan voucher & config Kustomisasi |
| 4 | P5 (uji Pesanan Aktif dengan data asli) | Checkout membuat dokumen `orders` | P4 | Hari 4 | Buat dokumen `orders` manual di Firestore Console |
| 5 | P1 (uji penuh papan antrean Staf) | Checkout membuat dokumen `orders` | P4 | Hari 4 | Pesanan manual di Console |
| 6 | P4 (Voucher saya di Akun) | Akun P2 sudah di-merge | P2 | Hari 4 | Voucher di Keranjang & sheet Ganti voucher |
| 7 | P3 (menyambungkan Beranda) | Nama user (P2), halaman Promo/Voucher (P4), fungsi Pesan lagi (P5) | P2, P4, P5 | Hari 5 | Menu, Favorit, Cari |
| 8 | Semua (uji akhir) | `firestore.rules` final | P1 | Hari 5 | Fitur masing-masing (test mode) |
| 9 | P5 (hapus `dummy_data.dart`) | Semua layar sudah lepas dari data dummy | P2, P3, P4 | Hari 6 | QA |
| 10 | P5 (edit `DESIGN.md` bagian 5) | Semua sudah menambah bagian layar barunya | Semua | Hari 7 | Build APK, README |

**Jalur kritis:** P1 PR Fondasi (H1) → P4 Checkout (H4) → QA end-to-end P5 + uji Web Staf P1 (H6). Jika PR Fondasi atau Checkout telat, seluruh jadwal mundur, jadi dua pekerjaan ini harus didahulukan di atas pekerjaan lain.

---

## Rincian tugas per orang

### P1 — Lead Backend + Web Staf & Admin (beban lebih)

**PR Fondasi (Hari 1, prioritas tertinggi — semua orang menunggu ini)**
- [ ] Buat project Firebase, daftarkan app Android + Web, jalankan `flutterfire configure` → `lib/firebase_options.dart`.
- [ ] Aktifkan Auth: Email/Password saja.
- [ ] Tambahkan **semua dependency sekaligus** di `pubspec.yaml`: `firebase_core`, `firebase_auth`, `cloud_firestore`, `cached_network_image`, `intl`, `http`, `image_picker`.
- [ ] `Firebase.initializeApp()` di `lib/main.dart` (setelah ini `main.dart` milik P2).
- [ ] Pindahkan `Produk`, `Voucher`, `Pesanan`, `kategoriMenu`, `statusPesanan` ke `lib/models/` + `id` + `fromMap`/`toMap`; `dummy_data.dart` cukup `export` model tersebut (import di layar tidak berubah).
- [ ] `CartItem`: tambah `productId`, `gambarUrl`, `toMap()`/`fromMap()` (setelah ini milik P4).
- [ ] Firestore dalam *test mode* + seed data: produk dari `dummy_data.dart`, `config/menu`, voucher `KOPIKITA20` & `HEMAT5RB`, `counters/antrean`.
- [ ] Akun uji: 1 admin, 1 staf, 1 pelanggan; bagikan kredensial di grup.
- [ ] Merge sebelum akhir Hari 1 dan umumkan di grup → semua `git pull`.

**Hari 2**
- [ ] Akun Cloudinary + *unsigned upload preset*; upload foto `assets/images/` dan isi `gambarUrl`.

**Web Staf & Admin (Hari 2–6)** — satu aplikasi Flutter Web di folder `lib/web/` (hanya P1), entrypoint `lib/web/main_web.dart` (`flutter run -t lib/web/main_web.dart -d chrome`), memakai model & token `lib/theme/` yang sama (hanya dibaca, tidak diubah). Setelah login, arahkan berdasarkan `role`.

- Staf:
  - [ ] Login (email/kata sandi), tolak jika role `pelanggan`.
  - [ ] **Papan antrean realtime** (stream `orders` hari ini): kolom per status, kartu berisi nomor antrean, metode/meja, item + opsi, total. ⏳ #5 untuk uji dengan pesanan asli.
  - [ ] Tombol ubah status: Konfirmasi bayar → Proses → Siap → Selesai, dan Batalkan.
  - [ ] Toggle stok **Habis** per produk.
- Admin (semua fitur staf, ditambah):
  - [ ] CRUD menu + upload foto ke Cloudinary (`image_picker` + `http` multipart).
  - [ ] CRUD voucher; beri voucher ke pelanggan (tambah ke `users.voucher`).
  - [ ] Kelola pengguna: ubah role pelanggan ↔ staf ↔ admin (staf daftar sendiri lalu dinaikkan role-nya oleh admin — tidak perlu Admin SDK).
  - [ ] Laporan sederhana: jumlah pesanan & omzet per hari dari `orders` berstatus `selesai`.
- [ ] `firestore.rules` final (Hari 5) sesuai aturan alur status.
- [ ] Deploy web ke **Firebase Hosting** (Hari 6).
- [ ] Tambah bagian `## 6. Web Staf & Admin` di akhir `DESIGN.md`.
- [ ] Review & merge PR (bersama P5).

### P2 — Auth & Akun

- [x] UI layar **Daftar** (`lib/screens/register_page.dart`, kerangka bersama `AuthScaffold` di `login_page.dart`) — sudah ada.
- [ ] Hari 1 (file baru saja): UI layar **Lupa kata sandi**.
- [ ] ⏳ #1 `AuthService` (masuk & daftar email/kata sandi, keluar, reset kata sandi).
- [ ] ⏳ #1 **AuthGate** di `main.dart`: belum login → Login, sudah login → Beranda (`authStateChanges()`).
- [ ] Hubungkan `login_page.dart` (lihat `ponytail:` baris 21): validasi, pesan error Bahasa Indonesia, loading pada tombol.
- [ ] Hubungkan `register_page.dart` (`ponytail:` di `_daftar`): validasi nama/email/kata sandi ≥ 6, `createUserWithEmailAndPassword` → buat dokumen `users/{uid}` role `pelanggan`.
- [ ] Akun: profil dari `users/{uid}`; **Edit profil** (ubah nama); **Keluar**. Merge paling lambat Hari 4 (P4 menunggu, #6).
- [ ] Layar **Notifikasi** (aktif/nonaktif notifikasi status pesanan → `users.notifikasi`).
- [ ] Sediakan stream/fungsi nama user agar P3 bisa menampilkan "Hai, {nama}" di Beranda.
- [ ] Perbaiki test "Login → Beranda" bila rusak karena AuthGate.
- [ ] Update `DESIGN.md`: 3.1, 3.1a (Daftar), 3.8, layar baru tepat setelah 3.1a.

### P3 — Menu, Katalog & Beranda (pemilik tunggal `home_page.dart`)

- [ ] Hari 1 (file baru saja): widget loading/error/kosong, UI layar Cari.
- [ ] ⏳ #1 `ProductRepository`: stream `products`.
- [ ] Ganti data dummy di **Menu** (`menu_page.dart`) dan **Beranda "Paling laris"** (`home_page.dart`); filter kategori tetap jalan.
- [ ] `ProductThumb`: tambah parameter opsional `url` → `CachedNetworkImage`, placeholder `tint` saat loading/gagal. **Jangan hapus parameter `nama`.**
- [ ] Status **Habis** realtime (badge + tombol + disabled).
- [ ] **Favorit**: tombol hati menyimpan ke `users.favorit` + layar daftar favorit.
- [ ] **Cari menu**: filter nama secara lokal dari list yang sudah dimuat.
- [ ] ⏳ #7 Sambungkan Beranda (Hari 5): "Hai, {nama}" (P2), tombol Notifikasi (P2), Promo & Voucher (P4), Favorit (milik sendiri), Pesan Lagi (P5).
- [ ] Update `DESIGN.md`: 3.2, 3.3, layar Cari & Favorit tepat setelah 3.3.

### P4 — Keranjang, Kustomisasi & Checkout

- [ ] Hari 1 (file baru saja): UI sheet **Ganti voucher**.
- [ ] ⏳ #1 Kustomisasi (`customize_page.dart`) membaca `hargaLarge`, `addOn`, `pajak` dari `config/menu` sendiri. **Signature `bukaKustomisasi(context, Produk p)` jangan diubah.**
- [ ] Voucher: validasi dari `vouchers/{kode}` (aktif, belum kedaluwarsa, `minBelanja`, persen/potongan) — ganti diskon 20% hardcode di `cart_provider.dart`; perbarui test CartProvider di PR yang sama.
- [ ] Sheet Ganti voucher dihubungkan ke link "Ganti" di Keranjang.
- [ ] Validasi nomor meja wajib bila Makan di Tempat.
- [ ] **Checkout** (`cart_provider.dart`, `ponytail:` baris 83): transaction naikkan `counters/antrean` (reset bila beda tanggal) → buat `orders` status `menunggu_bayar` → kosongkan keranjang → buka tab Pesanan. Tangani error (offline, produk habis). **Merge paling lambat Hari 4** (jalur kritis).
- [ ] ⏳ #3 Hapus `pesananAktif` & `contohPesananAktif` dari `CartProvider`.
- [ ] ⏳ #6 **Voucher saya** di `account_page.dart` dari Firestore (hanya blok voucher).
- [ ] Halaman Promo & Voucher (file sendiri) untuk disambungkan P3 di Beranda.
- [ ] Keadaan keranjang kosong (strip keranjang disembunyikan — cek perilaku `AppBottomBar`, minta P3 bila perlu ubah `common.dart`).
- [ ] Update `DESIGN.md`: 3.4, 3.5, sheet Ganti voucher tepat setelah 3.5.

### P5 — Pesanan, Notifikasi & QA/Rilis

- [ ] Hari 1 (file baru saja): widget keadaan "belum ada pesanan aktif", tombol Batalkan.
- [ ] ⏳ #1 `OrderRepository`: stream pesanan aktif user (status bukan `selesai`/`batal`) dan riwayat.
- [ ] **Pesanan Aktif** realtime (`orders_page.dart`, `ponytail:` baris 73) — berhenti membaca `CartProvider.pesananAktif`. **Merge Hari 3** (P4 menunggu, #3). ⏳ #4 uji pakai pesanan asli; sebelumnya pakai dokumen manual.
- [ ] Tombol **Batalkan** saat masih `menunggu_bayar`.
- [ ] **Riwayat** dari Firestore, dikelompokkan per bulan (`intl`), badge "Dibatalkan".
- [ ] Fungsi **Pesan lagi** (`CartItem.fromMap` → `CartProvider.addItem`); pakai di Riwayat, dan sediakan untuk P3 di Beranda.
- [ ] Notifikasi in-app (SnackBar/banner) saat status berubah, terutama **Siap diambil** (hormati `users.notifikasi`).
- [ ] ⏳ #9 Hapus `lib/data/dummy_data.dart` (Hari 6).
- [ ] ⏳ #8 QA end-to-end (Hari 6–7): daftar → pesan → staf proses di web → status berubah di HP → riwayat.
- [ ] Semua test lulus, `flutter analyze` bersih.
- [ ] Build **APK release**, tulis `README.md` (setup, akun uji, cara jalankan web).
- [ ] Update `DESIGN.md`: 3.6, 3.7, keadaan kosong; ⏳ #10 bagian 5 di Hari 7.

---

## Jadwal 7 hari

| Hari | P1 | P2 | P3 | P4 | P5 |
|---|---|---|---|---|---|
| **1** | **PR Fondasi** (Firebase, package, model, seed, akun uji) | UI Lupa kata sandi *(file baru)* | Widget loading/error, UI Cari *(file baru)* | UI sheet Ganti voucher *(file baru)* | UI empty state Pesanan, Batalkan *(file baru)* |
| **2** | Cloudinary; web: login + routing role | ⏳#1 AuthService + AuthGate + Login | ⏳#1 ProductRepository, Menu dari Firestore | ⏳#1 config Kustomisasi, validasi meja | ⏳#1 OrderRepository |
| **3** | Web Staf: papan antrean (data manual) + ubah status | Daftar → Firebase + dokumen `users` | Beranda Paling laris + foto Cloudinary | Voucher dari Firestore | **Pesanan Aktif realtime → merge** |
| **4** | Web Staf: toggle Habis; Admin: CRUD menu + upload foto | **Akun, Edit profil, Keluar → merge** | Habis realtime + Favorit | **Checkout + antrean → merge**; ⏳#3 hapus `pesananAktif` | Riwayat per bulan; ⏳#4 uji pakai pesanan asli |
| **5** | Admin: voucher, role, laporan; **rules final** | Notifikasi, polish error | Cari menu; ⏳#7 sambungkan Beranda | ⏳#6 Voucher saya, halaman Promo/Voucher | Pesan lagi, notifikasi in-app |
| **6** | Deploy Hosting, ⏳#5 uji Staf penuh, bantu bug | ⏳#8 Integrasi & bug fix | ⏳#8 Integrasi & bug fix | ⏳#8 Integrasi & bug fix | QA end-to-end, ⏳#9 hapus dummy data |
| **7** | Uji web staf/admin + demo | DESIGN.md + bug fix | DESIGN.md + bug fix | DESIGN.md + bug fix | Build APK, README, ⏳#10 DESIGN.md bagian 5, demo |

---

## Alur branch & merge

### Model

```
main  ──●────●────●────●────●────●────●──── (selalu bisa di-build & di-run)
         \  /  \  /  \  /
          p1/fondasi  p2/auth  p4/checkout ...   ← branch pendek, umur ≤ 1–2 hari
```

- **Satu branch utama: `main`.** Tidak ada `develop` — 7 hari terlalu singkat untuk dua lapis branch.
- **Branch fitur pendek** dibuat dari `main` terbaru, format `p<nomor>/<fitur>`, umur maksimal 2 hari, lalu PR ke `main`.
- **Squash and merge.** Setelah di-merge, branch dihapus. Kerjaan berikutnya = **branch baru dari `main`** (jangan lanjut di branch lama).
- **Hotfix** saat integrasi/QA: `fix/<deskripsi>`, contoh `fix/stepper-overflow`.

### Daftar branch per orang

| Hari | P1 | P2 | P3 | P4 | P5 |
|---|---|---|---|---|---|
| 1 | `p1/fondasi` **(merge pertama)** | `p2/ui-lupa-sandi` | `p3/ui-state-cari` | `p4/ui-ganti-voucher` | `p5/ui-pesanan-kosong` |
| 2 | `p1/cloudinary`, `p1/web-login` | `p2/auth` | `p3/menu-firestore` | `p4/config-kustomisasi` | `p5/order-repo` |
| 3 | `p1/web-staf` | `p2/auth` (lanjut: Daftar + `users`) | `p3/beranda-laris` | `p4/voucher` | `p5/pesanan-aktif` |
| 4 | `p1/web-admin-menu` | `p2/akun` | `p3/habis-favorit` | `p4/checkout` → `p4/hapus-pesanan-aktif` | `p5/riwayat` |
| 5 | `p1/web-admin-lain`, `p1/rules` | `p2/notifikasi` | `p3/cari`, `p3/beranda-sambung` | `p4/voucher-saya`, `p4/halaman-promo-voucher` | `p5/pesan-lagi-notif` |
| 6 | `p1/deploy-hosting`, `fix/*` | `fix/*` | `fix/*` | `fix/*` | `p5/hapus-dummy`, `fix/*` |
| 7 | `fix/*` | `p2/design-md` | `p3/design-md` | `p4/design-md` | `p5/rilis` (README, DESIGN.md bagian 5) → tag `v1.0` |

### Urutan merge yang wajib (sesuai ⏳)

Branch di kolom "Merge sesudah" **tidak boleh** di-merge sebelum branch prasyaratnya ada di `main`.

| Branch | Merge sesudah | Alasan |
|---|---|---|
| `p1/fondasi` | — | Semua bergantung padanya (⏳#1). Target merge siang–sore Hari 1. |
| `p2/ui-lupa-sandi`, `p3/ui-state-cari`, `p4/ui-ganti-voucher`, `p5/ui-pesanan-kosong` | `p1/fondasi` | Rebase ke `main` setelah fondasi masuk, lalu merge (malam Hari 1 / pagi Hari 2). |
| Semua branch Hari 2 | `p1/fondasi` | Dibuat dari `main` yang sudah berisi fondasi. |
| `p4/hapus-pesanan-aktif` | `p5/pesanan-aktif` | ⏳#3 — Pesanan harus sudah pakai stream. |
| `p4/voucher-saya` | `p2/akun` | ⏳#6 — file `account_page.dart` yang sama. |
| `p3/beranda-sambung` | `p2/auth`, `p4/halaman-promo-voucher`, `p5/pesan-lagi-notif` | ⏳#7 — menyambungkan halaman/fungsi milik orang lain. |
| `p5/hapus-dummy` | semua branch P2–P4 yang mengganti data dummy | ⏳#9 |
| `p5/rilis` | semua `*/design-md` | ⏳#10 |

### Jam merge harian

- **19.00–21.00 = jam merge.** PR yang siap dibuka sebelum 19.00; reviewer menyelesaikan review di jam ini.
- **Urutan merge dalam sehari:** branch yang ditunggu orang lain dulu (lihat tabel di atas), lalu sisanya. Hari 1: `p1/fondasi` tidak menunggu jam merge — merge begitu siap.
- **Reviewer:** P1 me-review PR P2–P5; P5 me-review PR P1. Jika P1 sibuk, P5 menggantikan.
- **Pagi hari:** semua `git pull` dari `main` sebelum membuat branch baru.

### Perintah sehari-hari

```bash
# Mulai fitur baru (selalu dari main terbaru)
git switch main
git pull
git switch -c p3/menu-firestore

# Kerja + commit kecil-kecil
git add -A
git commit -m "Menu membaca produk dari Firestore"

# Sebelum buka PR: susul main terbaru, cek, push
git fetch origin
git rebase origin/main          # konflik? perbaiki file → git add <file> → git rebase --continue
flutter analyze
flutter test
git push -u origin p3/menu-firestore   # setelah rebase ulang: git push --force-with-lease

# Buka PR ke main (GitHub web atau gh CLI)
gh pr create --base main --fill

# Setelah PR di-merge
git switch main
git pull
git branch -d p3/menu-firestore
```

### Aturan merge

- **Syarat PR boleh di-merge:** `flutter analyze` tanpa error, `flutter test` lulus, app jalan di emulator, 1 approval, `DESIGN.md` diperbarui bila UI berubah, tidak mengedit file milik orang lain (lihat tabel kepemilikan).
- **Konflik diselesaikan oleh pembuat PR**, bukan reviewer. Jika konflik menyentuh file orang lain, selesaikan bersama pemiliknya.
- **Proteksi `main` di GitHub** (diatur P1 Hari 1): wajib PR + 1 approval, larang push langsung & force push ke `main`.
- **Jangan commit:** `build/`, `.dart_tool/`, file kunci/kredensial selain `firebase_options.dart` & `google-services.json` (keduanya aman untuk repo privat proyek).
- **Hari 7 = freeze:** hanya branch `fix/*` dan `*/design-md` yang boleh di-merge. Setelah `p5/rilis` masuk, P5 membuat tag: `git tag v1.0 && git push origin v1.0`.

---

## Aturan kerja tim

- **Branch & merge:** ikuti [Alur branch & merge](#alur-branch--merge).
- **Kepemilikan file** (hanya pemilik yang mengedit; selain itu minta pemiliknya):

  | File | Pemilik |
  |---|---|
  | `pubspec.yaml`, `firebase_options.dart`, `firestore.rules`, `lib/models/` (kecuali `cart_item.dart`), `lib/web/`, `DESIGN.md` bagian 6 | P1 |
  | `lib/main.dart` (setelah PR Fondasi), `login_page.dart`, `register_page.dart`, `account_page.dart` (kecuali blok Voucher saya), layar auth/notifikasi baru | P2 |
  | `home_page.dart`, `menu_page.dart`, `lib/widgets/common.dart`, layar Cari/Favorit | P3 |
  | `cart_provider.dart`, `cart_item.dart` (setelah PR Fondasi), `cart_page.dart`, `customize_page.dart`, blok Voucher saya, halaman Promo/Voucher | P4 |
  | `orders_page.dart`, `test/`, `README.md`, `dummy_data.dart` (hapus), `DESIGN.md` bagian 5 | P5 |
  | `lib/theme/` | Tidak diubah, kecuali disepakati di grup |

- **Kontrak antar-orang yang dibekukan:** skema Firestore, `bukaKustomisasi(context, Produk p)`, parameter `ProductThumb` (hanya boleh ditambah), `CartItem.toMap/fromMap`.
- **Wajib dari `CLAUDE.md`:** ikuti `DESIGN.md`, pakai token `lib/theme/` (tanpa hex langsung), teks ≥ 12, target sentuh ≥ 44×44, hanya Ambil Sendiri & Makan di Tempat, tanpa fitur poin. Setiap perubahan UI **sekaligus** diperbarui di `DESIGN.md` (di bagian milik sendiri). Web staf/admin belum didesain → tetap pakai token & komponen yang sama.
- **Stand-up singkat tiap hari** (10 menit): kemarin apa, hari ini apa, terhambat apa — sebutkan nomor ⏳ yang sedang ditunggu.
- **Definisi selesai:** jalan di HP/emulator, `flutter analyze` tanpa error, test lulus, PR sudah di-merge, `DESIGN.md` diperbarui bila UI berubah.
