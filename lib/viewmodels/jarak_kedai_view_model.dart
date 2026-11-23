import 'package:flutter/foundation.dart';

import '../domain/entities/lokasi.dart';
import '../domain/hasil.dart';
import '../domain/repositories/perangkat_repository.dart';
import 'pesan_kegagalan.dart';

/// Empat keadaan kartu jarak kedai.
sealed class KeadaanJarak {
  const KeadaanJarak();
}

final class BelumDiminta extends KeadaanJarak {
  const BelumDiminta();
}

final class Mencari extends KeadaanJarak {
  const Mencari();
}

final class Ditemukan extends KeadaanJarak {
  const Ditemukan(this.jarak);
  final JarakKedai jarak;
}

final class GagalLokasi extends KeadaanJarak {
  const GagalLokasi(this.kegagalan);
  final Kegagalan kegagalan;

  String get pesan => pesanKegagalan(kegagalan) ?? 'Coba lagi.';
  bool get layananMati => kegagalan is LayananLokasiMati;
  bool get diblokir => kegagalan is IzinDiblokir;
}

// JarakKedaiViewModel: alur izin lokasi yang sopan (Pertemuan 13, Bagian 7).
// Lokasi TIDAK diminta saat aplikasi dibuka, hanya saat pengguna mengetuk
// tombol; aplikasi tetap bisa dipakai penuh bila izin ditolak.
class JarakKedaiViewModel extends ChangeNotifier {
  JarakKedaiViewModel(this._lokasi, this._pengaturan);

  final LayananLokasi _lokasi;
  final PengaturanPerangkat _pengaturan;

  KeadaanJarak _keadaan = const BelumDiminta();
  KeadaanJarak get keadaan => _keadaan;

  bool _dibuang = false;

  void _ubah(KeadaanJarak k) {
    if (_dibuang) return;
    _keadaan = k;
    notifyListeners();
  }

  Future<void> cari() async {
    if (_keadaan is Mencari) return; // cegah ketukan ganda
    _ubah(const Mencari());
    final hasil = await _lokasi.posisiSekarang();
    _ubah(switch (hasil) {
      Berhasil(:final nilai) => Ditemukan(JarakKedai.dari(nilai)),
      Gagal(:final kegagalan) => GagalLokasi(kegagalan),
    });
  }

  /// Dipanggil saat aplikasi kembali dari Pengaturan: periksa ulang otomatis.
  void saatKembali() {
    final k = _keadaan;
    if (k is GagalLokasi && (k.layananMati || k.diblokir)) cari();
  }

  Future<void> bukaPengaturanLokasi() => _pengaturan.bukaPengaturanLokasi();
  Future<void> bukaPengaturanAplikasi() => _pengaturan.bukaPengaturanAplikasi();

  /// Tautan Google Maps ke kedai (dibuka View lewat url_launcher).
  Uri get alamatPeta => Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$lintangKedai,$bujurKedai',
  });

  @override
  void dispose() {
    _dibuang = true;
    super.dispose();
  }
}
