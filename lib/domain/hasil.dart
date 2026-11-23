// LAPISAN DOMAIN — Dart murni (tanpa Flutter, tanpa Firebase).
//
// Hasil<T>: kotak berisi nilai bertipe T (Berhasil) ATAU kegagalan (Gagal).
// Karena sealed, `switch` wajib menangani keduanya sehingga UI tidak perlu
// try-catch dan tidak perlu mengenal exception Firebase.
sealed class Hasil<T> {
  const Hasil();
}

final class Berhasil<T> extends Hasil<T> {
  const Berhasil(this.nilai);

  final T nilai;
}

final class Gagal<T> extends Hasil<T> {
  const Gagal(this.kegagalan);

  final Kegagalan kegagalan;
}

// Bahasa kegagalan milik aplikasi, bebas dari istilah Firebase.
// Exception teknis diterjemahkan SEKALI, di repository (lapisan data).
sealed class Kegagalan implements Exception {
  const Kegagalan();
}

// Tidak ada koneksi ke server (Firestore `unavailable`).
final class TanpaKoneksi extends Kegagalan {
  const TanpaKoneksi();
}

// Ditolak Security Rules (Firestore `permission-denied`).
final class TanpaIzin extends Kegagalan {
  const TanpaIzin();
}

// Layanan gagal karena sebab lain; [kode] = kode galat dari layanan.
final class LayananBermasalah extends Kegagalan {
  const LayananBermasalah(this.kode);

  final String kode;
}

// Aturan bisnis dilanggar; [alasan] = kalimat siap tampil (Bahasa Indonesia).
final class AturanDilanggar extends Kegagalan {
  const AturanDilanggar(this.alasan);

  final String alasan;
}

// Email atau kata sandi salah (login / verifikasi ulang saat ubah sandi).
final class KredensialSalah extends Kegagalan {
  const KredensialSalah();
}
