// Entitas & aturan lokasi (Pertemuan 13, Bagian 6): Dart murni, tanpa
// geolocator, sehingga bisa diuji tanpa HP.
import 'dart:math';

// GANTI dengan koordinat kedai KopiKita yang sebenarnya
// (Google Maps → klik kanan titik kedai → klik angka koordinat untuk menyalin).
const double lintangKedai = -0.467071;
const double bujurKedai = 117.157441;

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

const double jariJariBumiMeter = 6378137.0;

double _keRadian(double derajat) => derajat * pi / 180;

/// Jarak garis lurus di permukaan bumi (haversine), dalam meter.
double jarakMeter(
  double lintang1,
  double bujur1,
  double lintang2,
  double bujur2,
) {
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
double arahDerajat(
  double lintang1,
  double bujur1,
  double lintang2,
  double bujur2,
) {
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

/// Jarak ke kedai dihitung di domain, bukan di widget.
class JarakKedai {
  const JarakKedai({
    required this.meter,
    required this.arah,
    required this.akurasiMeter,
    required this.palsu,
  });

  /// arah = posisi pengguna dilihat dari kedai (sesuai tes perangkat_test).
  factory JarakKedai.dari(Posisi p) => JarakKedai(
    meter: jarakMeter(p.lintang, p.bujur, lintangKedai, bujurKedai),
    arah: namaArah(arahDerajat(lintangKedai, bujurKedai, p.lintang, p.bujur)),
    akurasiMeter: p.akurasiMeter,
    palsu: p.palsu,
  );

  final double meter;
  final String arah;
  final double akurasiMeter;

  /// true jika lokasi berasal dari aplikasi pemalsu GPS.
  final bool palsu;
}
