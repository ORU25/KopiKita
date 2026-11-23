import '../entities/foto_dipilih.dart';
import '../entities/lokasi.dart';
import '../hasil.dart';

// KONTRAK fitur perangkat (Pertemuan 13, Bagian 9). Implementasi asli
// (geolocator, image_picker) ada di data/repositories/perangkat_asli.dart;
// versi palsu untuk uji ada di test/fakes/perangkat_palsu.dart.

abstract interface class LayananLokasi {
  /// Memeriksa layanan dan izin, lalu mengambil posisi sekarang.
  Future<Hasil<Posisi>> posisiSekarang();

  /// Mengikuti posisi terus-menerus (Pertemuan 13, Bagian 8).
  /// Pemanggil WAJIB membatalkan langganan ini saat selesai.
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
