// Kontrak fitur perangkat (Pertemuan 13, Bagian 9): lokasi, kamera, galeri.
// File ini Dart murni: TIDAK mengimpor geolocator / image_picker, sehingga
// aturan di sini bisa diuji tanpa HP. Implementasi asli ada di
// perangkat_asli.dart, versi palsu untuk uji ada di perangkat_palsu.dart.
import 'dart:math';
import 'dart:typed_data';

// ── Koordinat kedai ─────────────────────────────────────────────
// GANTI dengan koordinat kedai KopiKita yang sebenarnya
// (Google Maps → klik kanan titik kedai → klik angka koordinat untuk menyalin).
const double lintangKedai = -0.467071;
const double bujurKedai = 117.157441;

// ── Hasil & Kegagalan ───────────────────────────────────────────
enum Fitur {
  lokasi('lokasi'),
  kamera('kamera'),
  galeri('galeri');

  const Fitur(this.nama);
  final String nama;
}

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

sealed class Kegagalan {
  const Kegagalan();
}

/// Sakelar Lokasi di HP mati.
final class LayananLokasiMati extends Kegagalan {
  const LayananLokasiMati();
}

/// Izin belum diberikan, tetapi masih boleh diminta lagi.
final class IzinDitolak extends Kegagalan {
  const IzinDitolak(this.fitur);
  final Fitur fitur;
}

/// Izin diblokir: dialog tidak akan muncul lagi, hanya lewat Pengaturan.
final class IzinDiblokir extends Kegagalan {
  const IzinDiblokir(this.fitur);
  final Fitur fitur;
}

final class PerangkatTidakMendukung extends Kegagalan {
  const PerangkatTidakMendukung(this.fitur);
  final Fitur fitur;
}

/// Pengguna sendiri yang membatalkan. Bukan kesalahan.
final class Dibatalkan extends Kegagalan {
  const Dibatalkan();
}

final class WaktuHabis extends Kegagalan {
  const WaktuHabis();
}

/// Pemilih foto masih terbuka (kode already_active / multiple_request).
final class PemilihSibuk extends Kegagalan {
  const PemilihSibuk();
}

/// Galat lain yang tidak dikenali (kodenya ikut ditampilkan agar mudah dilaporkan).
final class GangguanPerangkat extends Kegagalan {
  const GangguanPerangkat(this.kode);
  final String kode;
}

/// Satu-satunya tempat kegagalan diubah menjadi kalimat untuk pengguna.
/// null berarti TIDAK perlu pesan apa pun (pengguna sengaja membatalkan).
String? pesanKegagalan(Kegagalan k) {
  return switch (k) {
    Dibatalkan() => null,
    LayananLokasiMati() =>
      'Layanan lokasi di HP sedang mati. Nyalakan dulu untuk melihat jarak ke kedai.',
    IzinDitolak(:final fitur) =>
      'Izin ${fitur.nama} belum diberikan. Kamu tetap bisa memesan seperti biasa.',
    IzinDiblokir(:final fitur) =>
      'Izin ${fitur.nama} diblokir. Izinkan lewat Pengaturan jika ingin memakai fitur ini.',
    PerangkatTidakMendukung(:final fitur) =>
      'Perangkat ini tidak mendukung ${fitur.nama}.',
    WaktuHabis() =>
      'Lokasi belum ketemu. Coba lagi di dekat jendela atau area terbuka.',
    PemilihSibuk() =>
      'Pemilih foto masih terbuka. Tutup dulu, lalu coba lagi.',
    GangguanPerangkat(:final kode) => 'Terjadi gangguan ($kode). Coba lagi.',
  };
}

// ── Entitas domain ──────────────────────────────────────────────
class Posisi {
  const Posisi({
    required this.lintang,
    required this.bujur,
    required this.akurasiMeter,
    required this.waktu,
    this.palsu = false,
  });

  final double lintang;
  final double bujur;
  final double akurasiMeter;
  final DateTime waktu;

  /// true jika berasal dari aplikasi pemalsu GPS.
  final bool palsu;
}

class FotoDipilih {
  const FotoDipilih({required this.nama, required this.bita});
  final String nama;
  final Uint8List bita;
}

// ── Kontrak ─────────────────────────────────────────────────────
abstract interface class LayananLokasi {
  /// Memeriksa layanan dan izin, lalu mengambil posisi sekarang.
  Future<Hasil<Posisi>> posisiSekarang();

  /// Mengikuti posisi terus-menerus (Pertemuan 13, Bagian 8).
  /// Pemanggil WAJIB membatalkan langganan ini di dispose().
  Stream<Hasil<Posisi>> ikutiPosisi({int jarakMinimumMeter = 10});
}

abstract interface class PemilihFoto {
  bool get kameraTersedia;

  Future<Hasil<FotoDipilih>> ambil({required bool dariKamera});

  /// Android: ambil kembali foto yang hilang saat aplikasi dimatikan
  /// sistem ketika kamera terbuka (Pertemuan 13, Bagian 4.6).
  /// Platform lain: selalu mengembalikan null.
  Future<Hasil<FotoDipilih>?> fotoHilang();
}

abstract interface class PengaturanPerangkat {
  Future<void> bukaPengaturanAplikasi();

  Future<void> bukaPengaturanLokasi();
}

// ── Jarak, arah, dan zona (Bagian 6) ────────────────────────────
const double jariJariBumiMeter = 6378137.0;

double _keRadian(double derajat) => derajat * pi / 180;

/// Jarak garis lurus di permukaan bumi (haversine), dalam meter.
double jarakMeter(double lintang1, double bujur1, double lintang2, double bujur2) {
  final double dLintang = _keRadian(lintang2 - lintang1);
  final double dBujur = _keRadian(bujur2 - bujur1);
  final double sLintang = sin(dLintang / 2);
  final double sBujur = sin(dBujur / 2);
  final double h =
      sLintang * sLintang +
      sBujur * sBujur * cos(_keRadian(lintang1)) * cos(_keRadian(lintang2));
  return jariJariBumiMeter * 2 * asin(sqrt(h));
}

/// Arah dari titik 1 ke titik 2, 0-360 derajat searah jarum jam dari utara.
double arahDerajat(double lintang1, double bujur1, double lintang2, double bujur2) {
  final double dBujur = _keRadian(bujur2 - bujur1);
  final double y = sin(dBujur) * cos(_keRadian(lintang2));
  final double x =
      cos(_keRadian(lintang1)) * sin(_keRadian(lintang2)) -
      sin(_keRadian(lintang1)) * cos(_keRadian(lintang2)) * cos(dBujur);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}

String namaArah(double derajat) {
  const List<String> nama = [
    'utara',
    'timur laut',
    'timur',
    'tenggara',
    'selatan',
    'barat daya',
    'barat',
    'barat laut',
  ];
  return nama[((derajat + 22.5) ~/ 45) % 8];
}

/// 85 m -> "85 m", 1234 m -> "1,2 km".
String formatJarak(double meter) {
  if (meter < 1000) return '${meter.round()} m';
  return '${(meter / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
}

/// Jarak ke kedai dihitung di sini (domain), bukan di widget.
class JarakKedai {
  const JarakKedai({
    required this.meter,
    required this.arah,
    required this.akurasiMeter,
    required this.palsu,
  });

  factory JarakKedai.dari(Posisi p) => JarakKedai(
    meter: jarakMeter(p.lintang, p.bujur, lintangKedai, bujurKedai),
    arah: namaArah(
      arahDerajat(lintangKedai, bujurKedai, p.lintang, p.bujur),
    ),
    akurasiMeter: p.akurasiMeter,
    palsu: p.palsu,
  );

  final double meter;
  final String arah;
  final double akurasiMeter;

  /// true jika lokasi berasal dari aplikasi pemalsu GPS.
  final bool palsu;
}