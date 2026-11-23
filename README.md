# KopiKita — Aplikasi Pemesanan Kedai Kopi (Flutter)

KopiKita adalah aplikasi mobile untuk pelanggan kedai kopi yang memungkinkan mereka memesan minuman dan makanan langsung dari ponsel tanpa antre di kasir. Pelanggan memilih menu, menyesuaikan pesanan (ukuran, suhu, gula, es, add-on), memasukkannya ke keranjang, lalu mengirim pesanan dan memantau statusnya secara realtime sampai siap diambil. Aplikasi dibangun dengan Flutter dan memakai Firebase (Authentication, Cloud Firestore, Cloud Messaging) sebagai backend. Sisi staf dan admin (kasir, barista, pengelola menu) berada di repo terpisah, `kopikita-web`, dan memakai database Firebase yang sama.

Metode pemesanan yang tersedia ada dua, yaitu **Ambil Sendiri** dan **Makan di Tempat**.

## Fitur

- **Autentikasi**: daftar, masuk, dan lupa kata sandi dengan email dan kata sandi (Firebase Auth).
- **Beranda**: sapaan pengguna, pilihan metode pesan, banner promo, dan daftar "Paling laris" yang realtime.
- **Menu**: katalog produk dari Firestore dengan filter kategori (Kopi, Non-Kopi, Makanan), pencarian, dan favorit. Produk yang ditandai habis oleh staf langsung tampil sebagai habis.
- **Kustomisasi**: ukuran (Large menambah harga), suhu, tingkat gula, es, add-on (Extra shot, Oat milk, Sirup karamel), dan catatan.
- **Keranjang**: ditampilkan sebagai strip di atas navbar, dilengkapi voucher dan ringkasan pajak.
- **Pesanan Aktif**: stepper status realtime dan tombol Batalkan selama pesanan belum dibayar, ditambah notifikasi saat status berubah.
- **Riwayat**: pesanan selesai atau dibatalkan, dikelompokkan per bulan, dengan tombol "Pesan lagi".
- **Akun**: ubah profil dan foto (diunggah ke Cloudinary), ubah kata sandi, pengaturan notifikasi, voucher saya, dan keluar.

## Teknologi

| Bagian | Teknologi |
|---|---|
| Framework | Flutter (Dart SDK `^3.13.2`) |
| State management | `provider` (hanya untuk keranjang), selebihnya `StreamBuilder` + repository |
| Autentikasi | `firebase_auth` |
| Database | `cloud_firestore` |
| Notifikasi push | `firebase_messaging` (FCM) |
| Foto profil dan produk | Cloudinary (unggah lewat `http`, pemilih gambar `image_picker`) |
| Format tanggal dan mata uang | `intl` (locale `id_ID`) |

## Struktur Proyek

```
lib/
├── main.dart            # Inisialisasi Firebase, splash, AuthGate, navigasi 4 tab
├── firebase_options.dart# Konfigurasi Firebase hasil FlutterFire CLI
├── seed.dart            # Skrip pengisi data awal Firestore + akun uji
├── models/              # Produk, CartItem, Pesanan, Voucher, aturan voucher
├── providers/           # CartProvider (keranjang, voucher, pajak, checkout)
├── services/            # Akses Firebase: auth, produk, pesanan, voucher, favorit,
│                        #   notifikasi, push (FCM), upload Cloudinary
├── screens/             # Login, Daftar, Beranda, Menu, Cari, Favorit, Kustomisasi,
│                        #   Keranjang, Pesanan, Promo, Notifikasi, Akun
├── theme/               # Token warna dan tipografi (AppTheme)
└── widgets/             # Komponen UI bersama
kopikita-design/         # Acuan desain (DESIGN.md, screenshot layar, aset)
test/                    # Unit test CartProvider dan widget test
```

## Cara Kerja Aplikasi

### 1. Alur layar

Saat aplikasi dibuka, `main.dart` menginisialisasi data tanggal Indonesia dan Firebase, menampilkan splash screen selama dua detik, lalu menyerahkan kendali ke `AuthGate`. `AuthGate` mendengarkan `FirebaseAuth.authStateChanges()`: bila pengguna belum login ia menampilkan `LoginPage`, dan bila sudah login ia menampilkan `NavigationPage` yang berisi empat tab (Beranda, Menu, Pesanan, Akun). Pada saat login berhasil, `AuthGate` juga memasang listener notifikasi pesanan dan mendaftarkan token FCM perangkat. Saat logout, listener dilepas dan token dihapus.

### 2. Data realtime lewat repository

Hampir semua data dibaca sebagai stream Firestore melalui kelas repository di `lib/services/`, lalu ditampilkan dengan `StreamBuilder`. Karena itu, perubahan yang dilakukan staf atau admin lewat web, misalnya menandai produk habis, mengganti harga, atau mengubah status pesanan, langsung muncul di aplikasi pelanggan tanpa perlu refresh. Hanya keranjang yang memakai `provider` (`CartProvider`), karena keranjang adalah state lokal yang tidak disimpan di server sebelum checkout.

### 3. Dari keranjang sampai pesanan siap

1. Pelanggan membuka produk di Menu atau Beranda, mengatur kustomisasi, lalu menambahkannya ke keranjang. Item dengan pilihan kustomisasi yang sama digabung dan jumlahnya ditambah.
2. Di Keranjang, pelanggan memilih metode pesan dan dapat memasang voucher. Voucher divalidasi ke koleksi `vouchers` (aktif, belum kedaluwarsa, dan memenuhi minimum belanja). Diskon dihitung dari subtotal, lalu pajak (default 10%, dibaca dari `config/menu`) dihitung dari subtotal setelah diskon.
3. Saat checkout, `CartProvider.checkout()` menjalankan satu **Firestore transaction** yang memeriksa setiap produk masih ada dan tidak habis, memeriksa ulang voucher, menaikkan nomor antrean di `counters/antrean` (nomor direset tiap hari dan berformat `A-001`), lalu membuat dokumen di `orders` dengan status `menunggu_bayar`. Karena semuanya dalam satu transaction, dua pelanggan tidak akan mendapat nomor antrean yang sama.
4. Pelanggan membayar di kasir. Staf mengubah status melalui web: `dibayar` → `diproses` → `siap` → `selesai`. Setiap perubahan tampil di tab Pesanan sebagai stepper.
5. `NotifPesanan` memantau stream pesanan aktif. Ketika status berubah menjadi dibayar, diproses, atau siap, sebuah dokumen ditulis ke `users/{uid}/notifikasi` sehingga muncul di lonceng Beranda lengkap dengan penanda belum dibaca. Untuk notifikasi saat aplikasi ditutup, `PushService` menyimpan token FCM di `users/{uid}.fcmTokens` agar `kopikita-web` dapat mengirim push.
6. Pelanggan hanya boleh membatalkan pesanan selama statusnya masih `menunggu_bayar`. Pembatalan dilakukan dengan transaction agar tidak menimpa perubahan staf yang masuk bersamaan.

### 4. Peran pengguna

Setiap akun memiliki field `role` di dokumen `users/{uid}`, yaitu `pelanggan` (default untuk akun baru), `staf`, atau `admin`. Aplikasi ini ditujukan untuk pelanggan; peran staf dan admin dipakai oleh `kopikita-web` dan dicek di Firestore Security Rules.

## Cara Menghubungkan dengan Database

Database yang dipakai adalah **Cloud Firestore** milik project Firebase `kopikita-dev`. Konfigurasinya sudah ada di repo (`lib/firebase_options.dart` dan `android/app/google-services.json`), sehingga untuk menjalankan aplikasi dengan database yang sama Anda tidak perlu menghubungkan apa pun secara manual. Jika Anda ingin memakai project Firebase milik sendiri, ikuti langkah berikut.

### Langkah 1 — Siapkan project Firebase

1. Buka [Firebase Console](https://console.firebase.google.com) lalu buat project baru.
2. Di menu **Build → Authentication**, aktifkan provider **Email/Password**.
3. Di menu **Build → Firestore Database**, buat database. Untuk pengembangan awal Anda dapat memakai *test mode*; untuk penggunaan sebenarnya pasang Security Rules yang membatasi akses berdasarkan `role` (rules final dikelola di repo `kopikita-web`).
4. Di menu **Build → Cloud Messaging**, pastikan FCM aktif bila ingin menguji push notification.

### Langkah 2 — Hubungkan aplikasi Flutter ke project tersebut

Pasang Firebase CLI dan FlutterFire CLI, lalu jalankan konfigurasi dari folder proyek:

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli

firebase login
flutterfire configure
```

Perintah `flutterfire configure` akan memilih project Anda, mendaftarkan aplikasi Android dan Web, lalu menimpa `lib/firebase_options.dart` dan `android/app/google-services.json` dengan konfigurasi milik Anda. Aplikasi memanggil `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` di `main.dart`, jadi tidak ada kode lain yang perlu diubah. Bila Anda memakai package name Android berbeda dari `com.pa.kopikita`, ubah juga `applicationId` di `android/app/build.gradle.kts`.

### Langkah 3 — Isi data awal (seed)

Database yang baru masih kosong, sedangkan aplikasi membutuhkan produk, konfigurasi harga, voucher, dan counter antrean. Skrip `lib/seed.dart` mengisi semuanya sekaligus:

```bash
flutter run -t lib/seed.dart -d chrome
```

Skrip ini membuat atau memperbarui:

- koleksi `products` (menu awal berikut field `urutan`, `rekomendasi`, `habis`),
- dokumen `config/menu` (harga ukuran Large, daftar add-on, dan tarif pajak 10%),
- koleksi `vouchers` (`KOPIKITA20` dan `HEMAT5RB`),
- dokumen `counters/antrean` (nomor antrean harian),
- tiga akun uji beserta dokumen `users/{uid}`.

Skrip ini aman dijalankan berulang kali: produk yang sudah ada tidak kehilangan `gambarUrl`, status `habis`, dan pengaturan lain hasil edit admin, serta nomor antrean tidak direset bila masih di hari yang sama. Setelah pesan "Selesai" muncul, tutup jendelanya.

Akun uji yang dibuat (hanya untuk pengembangan, jangan dipakai di produksi):

| Email | Peran | Kata sandi |
|---|---|---|
| `pelanggan@kopikita.test` | pelanggan | `kopikita123` |
| `staf@kopikita.test` | staf | `kopikita123` |
| `admin@kopikita.test` | admin | `kopikita123` |

### Langkah 4 — Jalankan aplikasi

```bash
flutter pub get
flutter run                 # Android / emulator
flutter run -d chrome       # Web
```

Masuk dengan akun pelanggan di atas, atau daftar akun baru dari layar Daftar. Akun baru otomatis mendapat dokumen `users/{uid}` dengan peran `pelanggan` dan dua voucher awal.

### Skema Firestore

Berikut koleksi yang dipakai aplikasi. Perubahan skema harus dikoordinasikan dengan `kopikita-web` karena kedua aplikasi membaca dan menulis data yang sama.

```
users/{uid}
  nama, email: string
  role: "pelanggan" | "staf" | "admin"
  favorit: [productId]          # produk favorit
  voucher: [kodeVoucher]        # voucher yang dimiliki
  notifikasi: bool
  fcmTokens: [string]           # token push perangkat
  createdAt: timestamp
  └─ notifikasi/{id}            # subkoleksi: judul, pesan, orderId, waktu, dibaca

products/{id}
  nama, deskripsi: string
  harga: int
  kategori: "Kopi" | "Non-Kopi" | "Makanan"
  gambarUrl: string             # URL Cloudinary
  habis: bool
  rekomendasi: bool             # tampil di "Paling laris"
  urutan: int
  suhu, bisaLarge, addOn        # opsi kustomisasi per produk

config/menu
  hargaLarge: int
  addOn: { "Extra shot": 5000, "Oat milk": 6000, "Sirup karamel": 4000 }
  pajak: 0.10

vouchers/{kode}
  info: string
  tipe: "persen" | "potongan"
  nilai: int
  minBelanja: int
  berlakuSampai: timestamp
  aktif: bool

orders/{id}
  uid, nomor ("A-014"), makanDiTempat, nomorMeja
  items: [{ productId, nama, gambarUrl, harga, jumlah, ukuran, suhu, gula, es, addOn, catatan }]
  subtotal, diskon, pajak, total: int
  voucher: string | null
  status: "menunggu_bayar" | "dibayar" | "diproses" | "siap" | "selesai" | "batal"
  createdAt, updatedAt: timestamp

counters/antrean
  tanggal: "2026-10-21"         # nomor direset tiap hari
  nomor: int
```

### Cloudinary (foto)

Foto profil diunggah dari aplikasi ke Cloudinary memakai *unsigned upload preset*. Nilai `cloud name` dan `upload preset` ada di `lib/services/acc_cloud.dart` dan harus sama dengan yang dipakai `kopikita-web`. Untuk memakai akun Cloudinary sendiri, buat upload preset bertipe *unsigned* yang mengizinkan folder `foto-profil`, lalu ganti konstanta `_cloudName` dan `_uploadPreset` di file tersebut. URL gambar (`secure_url`) yang dikembalikan Cloudinary disimpan ke Firestore, bukan file gambarnya.

## Menjalankan Pengujian

```bash
flutter test
```

Pengujian mencakup logika keranjang (`test/cart_provider_test.dart`), seperti perhitungan subtotal, diskon voucher, dan pajak, serta widget test dasar.

## Build APK

```bash
flutter build apk --release
```

Hasilnya berada di `build/app/outputs/flutter-apk/app-release.apk`.

## Pemecahan Masalah

- **"Akses Firestore ditolak. Periksa rules."** — Security Rules belum mengizinkan operasi tersebut atau *test mode* sudah kedaluwarsa. Periksa rules di Firebase Console.
- **Menu kosong setelah login** — database belum di-seed. Jalankan langkah 3.
- **Gagal checkout "Tidak punya izin membuat pesanan"** — rules untuk koleksi `orders` dan `counters` belum mengizinkan pelanggan membuat pesanan.
- **Upload foto gagal** — periksa bahwa upload preset Cloudinary bertipe *unsigned* dan mengizinkan folder `foto-profil`.
- **Push notification tidak muncul** — pastikan izin notifikasi diberikan (Android 13 ke atas) dan perangkat memiliki Google Play Services.

## Dokumen Lain

- `kopikita-design/design/DESIGN.md` — acuan desain UI (warna, tipografi, komponen, perilaku layar).
- `PEMBAGIAN_TUGAS.md` — pembagian tugas tim dan kontrak data Firestore.
