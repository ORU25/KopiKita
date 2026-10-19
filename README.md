# KopiKita — Aplikasi Pelanggan (Flutter)

Aplikasi Android pelanggan kedai kopi KopiKita: pesan menu, kustomisasi, keranjang, pesanan aktif realtime, dan riwayat. Web Staf & Admin ada di repo terpisah `kopikita-web`.

## Fitur

- Login / Daftar / Lupa kata sandi (Firebase Auth email & kata sandi).
- Beranda (sapaan, metode pesan, promo, "Paling laris" realtime).
- Menu (katalog realtime dari Firestore, filter kategori, cari, favorit).
- Kustomisasi (ukuran, suhu, gula, es, add-on, catatan).
- Keranjang + voucher + ringkasan pajak.
- Pesanan Aktif realtime (stepper status, tombol Batalkan) + notifikasi in-app saat status berubah.
- Riwayat (dikelompokkan per bulan, badge "Dibatalkan", Pesan lagi).
- Akun (edit profil + foto Cloudinary, ubah kata sandi, notifikasi, voucher saya, keluar).

## Prasyarat

- Flutter SDK `^3.13.2`.
- Akun Firebase project `kopikita-dev` (sudah dikonfigurasi di `lib/firebase_options.dart`).
- Firestore dalam test mode atau rules final dari `kopikita-web`.

## Setup

```bash
flutter pub get
flutter run                       # Android / emulator
flutter run -d chrome             # Web (aplikasi pelanggan)