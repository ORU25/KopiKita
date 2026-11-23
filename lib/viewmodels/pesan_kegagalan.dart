import '../domain/hasil.dart';

// pesanKegagalan: kalimat siap tampil (Bahasa Indonesia) untuk sebuah Kegagalan.
// Satu tempat untuk semua ViewModel agar pesan konsisten.
String pesanKegagalan(Kegagalan k) => switch (k) {
  AturanDilanggar(:final alasan) => alasan,
  TanpaKoneksi() =>
    'Tidak bisa terhubung ke server. Periksa koneksi internetmu.',
  TanpaIzin() => 'Akses ditolak. Coba keluar lalu masuk lagi.',
  KredensialSalah() => 'Email atau kata sandi salah.',
  LayananBermasalah() => 'Terjadi kesalahan. Coba lagi sebentar lagi.',
};

// pesanDari: untuk hasil aksi; null = berhasil.
String? pesanDari(Hasil<Object?> h) => switch (h) {
  Berhasil() => null,
  Gagal(:final kegagalan) => pesanKegagalan(kegagalan),
};
