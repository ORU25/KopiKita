import '../domain/hasil.dart';

// pesanKegagalan: kalimat siap tampil (Bahasa Indonesia) untuk sebuah Kegagalan.
// Satu tempat untuk semua ViewModel agar pesan konsisten.
// null = tidak perlu pesan apa pun (pengguna sendiri yang membatalkan).
String? pesanKegagalan(Kegagalan k) => switch (k) {
  AturanDilanggar(:final alasan) => alasan,
  TanpaKoneksi() =>
    'Tidak bisa terhubung ke server. Periksa koneksi internetmu.',
  TanpaIzin() => 'Akses ditolak. Coba keluar lalu masuk lagi.',
  KredensialSalah() => 'Email atau kata sandi salah.',
  LayananBermasalah() => 'Terjadi kesalahan. Coba lagi sebentar lagi.',
  // Fitur perangkat (Pertemuan 13)
  Dibatalkan() => null,
  LayananLokasiMati() => 'Layanan lokasi di HP sedang mati. Nyalakan dulu untuk melihat jarak ke kedai.',
  IzinDitolak(:final fitur) =>
    'Izin ${fitur.nama} belum diberikan. Kamu tetap bisa memesan seperti biasa.',
  IzinDiblokir(:final fitur) =>
    'Izin ${fitur.nama} diblokir. Izinkan lewat Pengaturan jika ingin memakai fitur ini.',
  PerangkatTidakMendukung(:final fitur) =>
    'Perangkat ini tidak mendukung ${fitur.nama}.',
  WaktuHabis() =>
    'Lokasi belum ketemu. Coba lagi di dekat jendela atau area terbuka.',
  PemilihSibuk() => 'Pemilih foto masih terbuka. Tutup dulu, lalu coba lagi.',
  GangguanPerangkat(:final kode) => 'Terjadi gangguan ($kode). Coba lagi.',
};

// pesanDari: untuk hasil aksi; null = berhasil (atau dibatalkan pengguna).
String? pesanDari(Hasil<Object?> h) => switch (h) {
  Berhasil() => null,
  Gagal(:final kegagalan) => pesanKegagalan(kegagalan),
};
