# Arsitektur KopiKita: Clean Architecture + MVVM

Dokumen ini menjelaskan susunan folder, peran tiap lapisan, alur data dari layar sampai Firebase dan kembali, serta bagian mana yang termasuk **MVVM**, **Clean Architecture**, dan **fitur perangkat & izin**.

---

## 1. Gambaran besar

Ada dua pola yang dipakai bersamaan:

- **Clean Architecture** membagi **seluruh aplikasi** menjadi tiga lapisan: **UI**, **Domain**, dan **Data**.
- **MVVM** (Model–View–ViewModel) adalah cara menata **lapisan UI** saja.

Jadi MVVM berada **di dalam** lapisan UI milik Clean Architecture.

```
┌──────────────────────── LAPISAN UI (MVVM) ─────────────────────────┐
│                                                                     │
│   VIEW  (lib/screens/, lib/widgets/)                                │
│     │  context.watch / Consumer  → membaca state                    │
│     │  context.read(...).aksi()  → meneruskan aksi pengguna         │
│     ▼                                                               │
│   VIEWMODEL  (lib/viewmodels/)  — ChangeNotifier                    │
│     │  memegang state layar (memuat / data / galat)                 │
│     │  memanggil use case atau kontrak repository                   │
└─────┼───────────────────────────────────────────────────────────────┘
      ▼
┌──────────────────────── LAPISAN DOMAIN ─────────────────────────────┐
│   lib/domain/   (Dart murni: tanpa Flutter, tanpa Firebase)         │
│   • entities/      → bentuk data (Produk, Pesanan, Profil, ...)     │
│   • use_cases/     → aturan bisnis (BuatPesanan, BatalkanPesanan..) │
│   • repositories/  → KONTRAK (abstract class): "apa" yang tersedia  │
│   • hasil.dart     → Hasil (Berhasil/Gagal) + Kegagalan             │
└─────────────────────────────▲───────────────────────────────────────┘
                              │ implements (mengisi kontrak)
┌──────────────────────── LAPISAN DATA ───────────────────────────────┐
│   lib/data/   → "dari mana" datanya: Firebase Auth, Firestore,      │
│                 FCM (push), Cloudinary (REST/http)                  │
└─────────────────────────────────────────────────────────────────────┘

        lib/config/dependensi.dart = AKAR KOMPOSISI
        (satu-satunya tempat yang memasangkan kontrak ↔ implementasi)
```

**Aturan ketergantungan** (inti Clean Architecture). Panah import hanya boleh mengarah ke dalam, yaitu ke `domain/`:

| Lapisan | Boleh mengimpor | Tidak boleh mengimpor |
|---|---|---|
| `domain/` | hanya `domain/` sendiri | Flutter, Firebase, `data/`, `viewmodels/`, `screens/` |
| `data/` | `domain/`, Firebase, `http` | `viewmodels/`, `screens/` |
| `viewmodels/` | `domain/` | Firebase, `data/` |
| `screens/`, `widgets/` | `viewmodels/`, `domain/entities/` | Firebase, `data/`, kontrak repository, use case |
| `config/dependensi.dart` | semuanya, karena dialah yang merakit | (bebas) |

Keuntungannya: Firebase bisa diganti tanpa menyentuh layar, dan ViewModel/use case bisa dites dengan **data palsu**, tanpa internet dan tanpa HP.

---

## 2. Susunan folder

```
lib/
├── main.dart                  # Titik masuk: Firebase.init, MultiProvider, AuthGate, navbar
├── config/
│   └── dependensi.dart        # AKAR KOMPOSISI (dependency injection lewat provider)
│
├── domain/                    # ── CLEAN ARCHITECTURE: DOMAIN ──
│   ├── hasil.dart             # Hasil<T> = Berhasil | Gagal; Kegagalan (TanpaKoneksi, TanpaIzin, ...)
│   ├── entities/              # Produk, CartItem, Pesanan, Voucher, voucher_rules,
│   │                          #   Profil, Notifikasi, MenuConfig, lokasi (Posisi, JarakKedai), FotoDipilih
│   ├── repositories/          # KONTRAK: AuthRepository, ProfilRepository, ProductRepository,
│   │                          #   OrderRepository, FavoritRepository, VoucherRepository,
│   │                          #   NotifikasiRepository, MenuConfigRepository,
│   │                          #   FotoRepository, PushRepository,
│   │                          #   perangkat_repository (LayananLokasi, PemilihFoto, PengaturanPerangkat)
│   └── use_cases/             # BuatPesanan, BatalkanPesanan, UbahProfil, PantauStatusPesanan
│
├── data/                      # ── CLEAN ARCHITECTURE: DATA ──
│   ├── firebase_kegagalan.dart        # Penerjemah exception Firebase → Kegagalan (SATU tempat)
│   └── repositories/
│       ├── auth_repository_firebase.dart       # Firebase Auth + dokumen users/{uid}
│       ├── profil_repository_firestore.dart    # users/{uid}
│       ├── product_repository_firestore.dart   # products
│       ├── order_repository_firestore.dart     # orders + transaction checkout/batal
│       ├── favorit_repository_firestore.dart   # users/{uid}.favorit
│       ├── voucher_repository_firestore.dart   # vouchers
│       ├── notifikasi_repository_firestore.dart# users/{uid}/notifikasi
│       ├── menu_config_repository_firestore.dart # config/menu
│       ├── foto_repository_cloudinary.dart     # REST API Cloudinary (paket http)
│       ├── push_repository_fcm.dart            # Firebase Cloud Messaging (izin notifikasi)
│       └── perangkat_asli.dart                 # geolocator (lokasi) + image_picker (kamera/galeri) + Pengaturan
│
├── viewmodels/                # ── MVVM: VIEWMODEL ──
│   ├── stream_view_model.dart # Basis: 1 stream → keadaan (memuat/data/galat) + muatUlang()
│   ├── pesan_kegagalan.dart   # Kegagalan → kalimat Bahasa Indonesia
│   ├── auth_view_model.dart   # status login, masuk/daftar/reset/ubah sandi/keluar
│   ├── cart_view_model.dart   # keranjang, voucher, pajak, checkout
│   ├── produk_view_model.dart # katalog (dipakai Beranda, Menu, Cari, Favorit, Riwayat)
│   ├── favorit_view_model.dart
│   ├── profil_view_model.dart
│   ├── notifikasi_view_model.dart
│   ├── pesanan_view_model.dart        # PesananAktifViewModel + RiwayatPesananViewModel
│   ├── voucher_saya_view_model.dart
│   └── jarak_kedai_view_model.dart    # izin lokasi + jarak ke kedai
│
├── screens/                   # ── MVVM: VIEW (halaman) ──
├── widgets/                   # ── MVVM: VIEW (komponen) ──
├── theme/                     # Token warna & tipografi (bagian View)
└── seed.dart                  # Skrip pengisi data awal (alat bantu, BUKAN bagian aplikasi)

test/
├── fakes/                     # Repository PALSU (di memori) + perangkat_palsu.dart (lokasi/foto)
├── cart_view_model_test.dart  # Tes ViewModel tanpa layar
├── viewmodels/                # Tes AuthViewModel, ProfilViewModel, JarakKedaiViewModel
├── perangkat_test.dart        # Tes jarak/arah/pesan izin dengan perangkat palsu
├── domain/use_cases/          # Tes use case dengan data palsu
└── data/                      # Tes repository REST dengan MockClient (tanpa internet)
```

---

## 3. Mana yang masuk MVVM, mana yang masuk Clean Architecture

### 3.1 MVVM (menata lapisan UI)

| Peran MVVM | Di proyek ini | Tugas |
|---|---|---|
| **Model** | `lib/domain/entities/` (dan secara luas seluruh `domain/` + `data/`) | Bentuk data dan sumbernya |
| **View** | `lib/screens/`, `lib/widgets/`, `lib/theme/` | Menggambar UI, membaca state, meneruskan aksi. **Tanpa logika bisnis dan tanpa Firebase.** |
| **ViewModel** | `lib/viewmodels/` | Menyimpan state layar, memanggil use case/repository, mengubah hasil menjadi kalimat siap tampil, lalu `notifyListeners()` |

Pasangan View ↔ ViewModel:

| View (layar / widget) | ViewModel yang dipakai |
|---|---|
| `main.dart` → `AuthGate` | `AuthViewModel` (status login) |
| `login_page.dart`, `register_page.dart` | `AuthViewModel` (`masuk`, `daftar`, `kirimResetSandi`, `memproses`) |
| `home_page.dart` | `ProdukViewModel` (Paling laris), `ProfilViewModel` (sapaan), `NotifikasiViewModel` (titik merah), `CartViewModel` (metode pesan) |
| `widgets/kartu_jarak_kedai.dart` (Beranda) | `JarakKedaiViewModel` (izin lokasi, jarak, Buka Pengaturan) |
| `menu_page.dart`, `search_page.dart` | `ProdukViewModel`, `FavoritViewModel`, `CartViewModel` |
| `favorite_page.dart` | `ProdukViewModel` × `FavoritViewModel` |
| `widgets/favorit.dart` (tombol hati) | `FavoritViewModel.toggle` |
| `customize_page.dart` | `CartViewModel` (`muatConfig`, `addItem`) |
| `cart_page.dart`, `widgets/voucher_sheet.dart` | `CartViewModel`, `VoucherSayaViewModel` |
| `orders_page.dart` (Aktif) | `PesananAktifViewModel` (`keadaan`, `batalkan`) |
| `orders_page.dart` (Riwayat) | `RiwayatPesananViewModel` + `ProdukViewModel` (status Habis) |
| `notification_page.dart` | `NotifikasiViewModel` |
| `promo_page.dart` (Voucher Saya) | `VoucherSayaViewModel` |
| `account_page.dart` | `ProfilViewModel` (profil, toggle + izin notifikasi, kamera/galeri, simpan profil), `AuthViewModel` (ubah sandi, keluar) |

**Yang tetap di View** (bukan ViewModel) adalah state tampilan murni: tab aktif, chip kategori, isi `TextEditingController`, baris accordion yang terbuka, dan header yang mengecil saat scroll. Semua ini tidak ada hubungannya dengan data atau aturan bisnis.

### 3.2 Clean Architecture (menata seluruh aplikasi)

| Lapisan | Folder | Isi |
|---|---|---|
| **UI / Presentation** | `screens/`, `widgets/`, `viewmodels/`, `theme/` | View dan ViewModel (MVVM) |
| **Domain** | `domain/` | Entitas, kontrak repository, use case, `Hasil`/`Kegagalan` |
| **Data** | `data/` | Implementasi kontrak memakai Firebase / Cloudinary |
| **Akar komposisi** | `config/dependensi.dart` | Memasang implementasi ke kontrak (dependency injection) |

Konsep kunci yang dipakai:

1. **Entitas.** Contohnya `Pesanan`, `Voucher`, dan `Profil` di `domain/entities/`. Isinya data dan aturan kecil yang melekat pada data, misalnya `voucher_rules.dart` dengan `alasanTidakBerlaku()` dan `hitungDiskon()`. Entitas tidak mengenal `Timestamp` Firestore; konversinya dilakukan `tanpaTimestamp()` di lapisan data.
2. **Kontrak repository.** Contohnya `abstract class OrderRepository`. Kontrak hanya menyebut **apa** yang bisa dilakukan (`streamAktif()`, `buat()`, `batalkan()`), bukan **dari mana** datanya.
3. **Implementasi repository.** Contohnya `OrderRepositoryFirestore implements OrderRepository`. Di sinilah Firebase dipakai.
4. **Use case.** Satu tindakan pengguna beserta aturan bisnisnya:
   - `BuatPesanan`: keranjang kosong atau rincian harga tidak valid → ditolak.
   - `BatalkanPesanan`: hanya pesanan berstatus `menunggu_bayar` yang boleh dibatalkan.
   - `UbahProfil`: nama minimal 2 karakter, foto maksimal 2 MB, unggah foto dulu baru simpan.
   - `PantauStatusPesanan`: saat status pesanan naik ke Dibayar/Diproses/Siap, tulis satu notifikasi.
5. **`Hasil` dan `Kegagalan`.** Repository tidak melempar exception Firebase ke atas. Ia mengembalikan `Berhasil(nilai)` atau `Gagal(Kegagalan)`. Jenis kegagalannya: `TanpaKoneksi`, `TanpaIzin`, `KredensialSalah`, `AturanDilanggar(alasan)`, dan `LayananBermasalah(kode)`. Karena `sealed`, setiap `switch` wajib menangani semua kemungkinan.
6. **Dependency injection.** `dependensi.dart` mendaftarkan, misalnya, `Provider<OrderRepository>(create: (_) => OrderRepositoryFirestore())`. Pihak yang memakai hanya meminta `context.read<OrderRepository>()` dan tidak tahu implementasinya. Saat tes, yang dipasang adalah `FakeOrderRepository`.

---

## 4. Akar komposisi dan siklus hidup ViewModel

`config/dependensi.dart` punya dua daftar:

| Daftar | Isi | Umur |
|---|---|---|
| `buatPenyedia()` | Semua repository, semua use case, `AuthViewModel` | Selama aplikasi hidup |
| `buatPenyediaSesi()` | `CartViewModel`, `ProdukViewModel`, `FavoritViewModel`, `ProfilViewModel`, `NotifikasiViewModel`, `PesananAktifViewModel`, `RiwayatPesananViewModel`, `VoucherSayaViewModel` | Satu sesi login |

Di `main.dart`:

```dart
MultiProvider(providers: buatPenyedia(), child: MainApp())   // seumur aplikasi

MaterialApp(
  builder: (context, child) => uid == null
      ? child!                                   // belum login: tanpa VM sesi
      : MultiProvider(
          key: ValueKey(uid),                    // ganti akun → semua VM sesi dibuat ulang
          providers: buatPenyediaSesi(),
          child: child!,                         // child = Navigator → semua halaman bisa membaca VM
        ),
  home: AuthGate(),
)
```

- VM sesi dipasang **di atas Navigator**, sehingga halaman yang dibuka dengan `Navigator.push` (Keranjang, Kustomisasi, Notifikasi, dll.) tetap bisa membacanya.
- `key: ValueKey(uid)` membuat semua VM sesi dibuang dan dibuat baru setiap kali akun berganti. Akibatnya keranjang dan data akun lama tidak terbawa.

---

## 5. Alur-alur utama (langkah demi langkah)

### 5.1 Membuka aplikasi dan login

```
main()  → Firebase.initializeApp()
        → MultiProvider(buatPenyedia())
            └─ AuthViewModel dibuat (lazy: false)
                 └─ mendengarkan AuthRepository.perubahanUid()   [data: FirebaseAuth.authStateChanges]

AuthGate (View) ── watch ──▶ AuthViewModel.status
   memeriksa → SplashScreen
   keluar    → LoginPage
   masuk     → NavigationPage (tab Beranda)

LoginPage: tombol Masuk
   → context.read<AuthViewModel>().masuk(email, sandi)
       → AuthRepository.masuk()                → Hasil
           [AuthRepositoryFirebase: signInWithEmailAndPassword + buat users/{uid} bila hilang]
       → Gagal(KredensialSalah) → pesanKegagalan() → "Email atau kata sandi salah."
   → View menampilkan SnackBar bila ada pesan; kalau berhasil tidak perlu navigasi manual

Saat uid berubah menjadi ada (login):
   AuthViewModel._onUid → PantauStatusPesanan.mulai()   (use case)
                        → PushRepository.daftar()        (minta izin notifikasi + simpan token FCM)
                        → status = masuk → AuthGate menampilkan Beranda
                        → MainApp memasang VM sesi baru (key = uid)
```

### 5.2 Menampilkan data realtime (contoh: Menu)

```
MenuPage (View)
  Consumer<ProdukViewModel>  → vm.keadaan (AsyncSnapshot: memuat / data / galat)
      keadaanStream(...) → LoadingView / ErrorView("Coba lagi" = vm.muatUlang) / EmptyView / daftar

ProdukViewModel extends StreamViewModel<List<Produk>>
  buatStream() → ProductRepository.stream()

ProductRepositoryFirestore
  products.snapshots() → map ke List<Produk> → .terjemahkanGalat()
  (galat Firebase menjadi Kegagalan, misalnya TanpaKoneksi → "Tidak bisa terhubung ke server...")
```

Saat staf mengubah status Habis dari web, Firestore mengirim snapshot baru → `ProdukViewModel` memanggil `notifyListeners()` → Menu, Beranda, Cari, Favorit, dan Riwayat ikut berubah. Kelima layar itu memakai **satu** ViewModel yang sama.

### 5.3 Dari keranjang sampai pesanan dibuat (checkout)

```
CustomizePage → CartViewModel.addItem(CartItem)        (state lokal; belum ke server)
CartPage      → CartViewModel.setMakanDiTempat / terapkanVoucher(kode)
                   terapkanVoucher → VoucherRepository.ambil(kode) → Hasil<Voucher?>
                                     lalu aturan entitas voucher.alasanTidakBerlaku(subtotal)
              → hitung subtotal, diskon, pajak (MenuConfig dari MenuConfigRepository), total

Tombol Pesan → CartViewModel.checkout()
   1. susun draf Pesanan (items, metode, subtotal, diskon, pajak, total, voucher)
   2. BuatPesanan.jalankan(draf)                     ← USE CASE (aturan: keranjang tidak kosong)
   3.   → OrderRepository.buat(draf)                 ← KONTRAK
   4.     → OrderRepositoryFirestore.buat()          ← DATA: SATU Firestore transaction
            • cek setiap produk masih ada dan tidak Habis
            • cek ulang voucher
            • naikkan counters/antrean (A-001, direset tiap hari)
            • buat orders/{id} berstatus menunggu_bayar
   5. Berhasil → keranjang dikosongkan
      Gagal    → CheckoutException("... sedang habis ...") → View menampilkan pesan
```

### 5.4 Membatalkan pesanan

```
OrdersPage (Aktif) → dialog konfirmasi → PesananAktifViewModel.batalkan(p)
   → BatalkanPesanan.jalankan(p)    aturan domain: status harus menunggu_bayar
   → OrderRepository.batalkan(id)   data: transaction, cek ulang status di server
   → Hasil → pesanDari() → "Pesanan dibatalkan." / alasan penolakan → SnackBar
```

### 5.5 Notifikasi status pesanan

```
PantauStatusPesanan (use case, dinyalakan AuthViewModel saat login)
   mendengarkan OrderRepository.streamAktif()
   status naik ke 1/2/3 → NotifikasiRepository.tambah(judul, pesan)  → users/{uid}/notifikasi

Beranda (lonceng) → NotifikasiViewModel.belumDibaca → titik merah
NotificationPage  → NotifikasiViewModel.keadaan (daftar) + tandaiSemuaDibaca() saat dibuka

Saat app ditutup: kopikita-web mengirim push FCM ke token yang disimpan PushRepositoryFcm.
```

### 5.6 Edit profil dan unggah foto

```
AccountPage → sheet Edit profil
   pilih foto → ProfilViewModel.pilihFoto(kamera/galeri) → PemilihFoto  [FITUR PERANGKAT, lihat 6.2]
              → validasi format & ukuran (FotoDipilih.alasanDitolak, domain)
   Simpan     → ProfilViewModel.simpanProfil(nama, fotoBaru)
       → UbahProfil.jalankan()                  ← USE CASE
           • nama < 2 karakter → Gagal(AturanDilanggar)
           • foto > 2 MB      → Gagal(AturanDilanggar)
           • FotoRepository.unggah(bytes)       ← REST API (Cloudinary, paket http)
           • ProfilRepository.ubah(nama, fotoUrl)
       → null (berhasil) atau pesan galat → View menutup sheet / menampilkan galat
```

### 5.7 Keluar

```
AccountPage → AuthViewModel.keluar()
   → PushRepository.lepas()    (hapus token FCM selagi masih login)
   → AuthRepository.keluar()   (signOut)
   → View: bersihkan cache gambar
AuthRepository.perubahanUid() mengirim null → AuthViewModel: PantauStatusPesanan.berhenti(),
status = keluar → AuthGate menampilkan LoginPage; VM sesi dibuang.
```

---

## 6. Fitur perangkat & izin akses

Fitur perangkat mengikuti pola yang sama dengan Firebase: **kontrak di domain, implementasi asli di data, ViewModel di tengah, View hanya menampilkan.**

```
View                          ViewModel                    Domain (kontrak)            Data (asli)
kartu_jarak_kedai.dart  ──▶  JarakKedaiViewModel   ──▶  LayananLokasi        ◀──  LayananLokasiGeolocator (geolocator)
account_page.dart       ──▶  ProfilViewModel       ──▶  PemilihFoto          ◀──  PemilihFotoImagePicker  (image_picker)
  (foto & notifikasi)                              ──▶  PengaturanPerangkat  ◀──  PengaturanPerangkatAsli (Pengaturan HP)
                                                   ──▶  PushRepository       ◀──  PushRepositoryFcm       (firebase_messaging)
```

| Fitur | Paket | Izin (Android / iOS) | Kontrak → implementasi | ViewModel → View |
|---|---|---|---|---|
| **Jarak & arah ke kedai** | `geolocator` | `ACCESS_COARSE_LOCATION` + `ACCESS_FINE_LOCATION` / `NSLocationWhenInUseUsageDescription` | `LayananLokasi` → `LayananLokasiGeolocator` | `JarakKedaiViewModel` → `KartuJarakKedai` (Beranda) |
| **Foto profil dari kamera** | `image_picker` | Tanpa izin `CAMERA` di Manifest (memakai aplikasi kamera bawaan) / `NSCameraUsageDescription` | `PemilihFoto` → `PemilihFotoImagePicker` | `ProfilViewModel.pilihFoto(dariKamera: true)` → sheet Edit profil |
| **Foto profil dari galeri** | `image_picker` | Pemilih foto sistem / `NSPhotoLibraryUsageDescription` | `PemilihFoto` → `PemilihFotoImagePicker` | `ProfilViewModel.pilihFoto(dariKamera: false)` |
| **Buka Pengaturan HP** | `geolocator` | – | `PengaturanPerangkat` → `PengaturanPerangkatAsli` | dipakai `JarakKedaiViewModel` & `ProfilViewModel` |
| **Push notification** | `firebase_messaging` | `POST_NOTIFICATIONS` (Android 13+) | `PushRepository` → `PushRepositoryFcm` | `AuthViewModel` (daftar token), `ProfilViewModel.setNotifikasi` (minta izin) |
| **Unggah foto** | `http` (REST) | `INTERNET` | `FotoRepository` → `FotoRepositoryCloudinary` | use case `UbahProfil` |

Lokasi kode:

| Lapisan | File |
|---|---|
| Domain: entitas | `domain/entities/lokasi.dart` (`Posisi`, `JarakKedai`, `jarakMeter` haversine, `arahDerajat`, `namaArah`, `formatJarak`, koordinat kedai), `domain/entities/foto_dipilih.dart` (`FotoDipilih` + aturan format/ukuran) |
| Domain: kontrak | `domain/repositories/perangkat_repository.dart` (`LayananLokasi`, `PemilihFoto`, `PengaturanPerangkat`), `domain/repositories/push_repository.dart` |
| Domain: kegagalan | `domain/hasil.dart`: `LayananLokasiMati`, `IzinDitolak(fitur)`, `IzinDiblokir(fitur)`, `PerangkatTidakMendukung`, `Dibatalkan`, `WaktuHabis`, `PemilihSibuk`, `GangguanPerangkat` |
| Data | `data/repositories/perangkat_asli.dart` (satu-satunya file yang mengimpor `geolocator`/`image_picker` dan menerjemahkan exception-nya), `data/repositories/push_repository_fcm.dart` |
| ViewModel | `viewmodels/jarak_kedai_view_model.dart`, `viewmodels/profil_view_model.dart` |
| View | `widgets/kartu_jarak_kedai.dart`, `screens/account_page.dart` |
| Pesan untuk pengguna | `viewmodels/pesan_kegagalan.dart` (`Dibatalkan` → tanpa pesan) |
| Palsu untuk tes | `test/fakes/perangkat_palsu.dart` (`LayananLokasiPalsu` + `SkenarioLokasi`, `PemilihFotoPalsu`, `PengaturanPerangkatPalsu`) |

### 6.1 Alur izin lokasi (sopan)

```
Beranda: KartuJarakKedai → keadaan BelumDiminta (penjelasan manfaat + privasi, BELUM ada dialog)
  ketuk "Cek jarak ke kedai" → JarakKedaiViewModel.cari() → Mencari
     → LayananLokasi.posisiSekarang()
         1. sakelar Lokasi mati?        → Gagal(LayananLokasiMati)  → tombol "Nyalakan Lokasi"
         2. checkPermission / request   → denied        → Gagal(IzinDitolak)   → tombol "Coba lagi"
                                        → deniedForever → Gagal(IzinDiblokir)  → tombol "Buka Pengaturan"
         3. getCurrentPosition (20 dtk) → timeout       → Gagal(WaktuHabis)
     → Berhasil(Posisi) → JarakKedai.dari(posisi) → Ditemukan (jarak, arah, akurasi, peringatan GPS palsu)
  kembali dari Pengaturan (AppLifecycleListener.onResume) → vm.saatKembali() → cek ulang otomatis
  "Buka di peta" → vm.alamatPeta → url_launcher (selalu tersedia, tanpa izin)
```

### 6.2 Alur kamera / galeri

```
Sheet Edit profil → ketuk ikon kamera → pilih "Ambil dengan kamera" / "Pilih dari galeri"
   (bila perangkat tanpa kamera, langsung galeri)
   → ProfilViewModel.pilihFoto(dariKamera)
       → PemilihFoto.ambil()         batal → Dibatalkan (tanpa pesan)
                                     izin kamera/galeri diblokir → IzinDiblokir → tombol "Buka Pengaturan"
                                     pemilih masih terbuka → PemilihSibuk
       → FotoDipilih.alasanDitolak() format bukan JPG/PNG/WEBP atau > 2 MB → pesan
   → foto pratinjau → Simpan → use case UbahProfil → FotoRepository.unggah (Cloudinary) → ProfilRepository.ubah
Android: saat sheet dibuka, ProfilViewModel.fotoHilang() memulihkan foto bila aplikasi sempat dimatikan sistem saat kamera terbuka.
```

### 6.3 Alur izin notifikasi

```
Login → AuthViewModel → PushRepository.daftar(): simpan token HANYA bila izin sudah ada (tanpa dialog)
Akun → nyalakan "Notifikasi pesanan" → ProfilViewModel.setNotifikasi(true)
   → PushRepository.mintaIzin() (dialog Android 13+)
   → ditolak → SnackBar "Izin notifikasi belum diberikan..." + aksi "Pengaturan"
   → toggle tetap disimpan; lonceng di Beranda tetap terisi (dari Firestore, bukan push)
```

Semua perilaku di atas diuji tanpa HP di `test/perangkat_test.dart` dan `test/viewmodels/view_models_test.dart` memakai versi palsu.

---

## 7. Pengujian: kenapa arsitektur ini memudahkan

Karena ViewModel dan use case hanya bergantung pada **kontrak**, tes cukup memasang repository palsu dari `test/fakes/`:

```dart
final repo = FakeOrderRepository(
  hasilBuat: const Gagal(AturanDilanggar('Kopi sedang habis.')),
);
final cart = buatCart(pesanan: repo)..addItem(item);
expect(cart.checkout(), throwsA(isA<CheckoutException>()));   // tanpa Firebase, tanpa HP
```

| File tes | Yang diuji | Lapisan |
|---|---|---|
| `test/cart_view_model_test.dart`, `test/widget_test.dart` | Total, voucher, checkout, config | ViewModel (MVVM) |
| `test/viewmodels/view_models_test.dart` | `AuthViewModel`, `ProfilViewModel` (izin notifikasi, kamera/galeri), `JarakKedaiViewModel` (izin lokasi) | ViewModel (MVVM) |
| `test/perangkat_test.dart` | Haversine, arah, format jarak, pesan izin, perangkat palsu | Domain (fitur perangkat) |
| `test/domain/use_cases/*` | `BuatPesanan`, `BatalkanPesanan`, `UbahProfil`, `PantauStatusPesanan` | Domain |
| `test/data/foto_repository_cloudinary_test.dart` | REST Cloudinary dengan `MockClient` | Data |

Jalankan dengan `flutter test`.

---

## 8. Ringkasan cepat (untuk presentasi)

- **Clean Architecture** = tiga lapisan: `domain/` (aturan, Dart murni) ← `data/` (Firebase/REST), dipakai oleh UI. Semuanya dirakit di `config/dependensi.dart`.
- **MVVM** = cara menata UI: **View** (`screens/`, `widgets/`) ↔ **ViewModel** (`viewmodels/`, `ChangeNotifier` + `provider`) ↔ **Model** (`domain/entities/`).
- **Alur data:** View → ViewModel → use case → kontrak repository → implementasi Firebase → `Hasil` → ViewModel (`notifyListeners`) → View digambar ulang.
- **Galat** diterjemahkan sekali di `data/firebase_kegagalan.dart` menjadi `Kegagalan`, lalu menjadi kalimat Indonesia di `viewmodels/pesan_kegagalan.dart`.
- **Fitur perangkat:** lokasi/jarak ke kedai (`geolocator`), kamera & galeri (`image_picker`), izin notifikasi + push (`firebase_messaging`), semuanya di balik kontrak domain + ViewModel, lengkap dengan alur izin ditolak/diblokir → Pengaturan.
