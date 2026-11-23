import 'dart:typed_data';

import '../hasil.dart';
import '../repositories/foto_repository.dart';
import '../repositories/profil_repository.dart';

// USE CASE: simpan nama + foto profil baru (foto diunggah dulu bila ada).
class UbahProfil {
  UbahProfil(this._profil, this._foto);

  final ProfilRepository _profil;
  final FotoRepository _foto;

  static const int maksFotoBytes = 2 * 1024 * 1024;

  Future<Hasil<void>> jalankan({
    required String nama,
    Uint8List? fotoBaru,
  }) async {
    final n = nama.trim();
    if (n.length < 2) {
      return const Gagal(AturanDilanggar('Nama minimal 2 karakter.'));
    }
    String? url;
    if (fotoBaru != null) {
      if (fotoBaru.length > maksFotoBytes) {
        return const Gagal(AturanDilanggar('Ukuran foto maksimal 2 MB.'));
      }
      switch (await _foto.unggah(fotoBaru)) {
        case Berhasil(:final nilai):
          url = nilai;
        case Gagal(:final kegagalan):
          return Gagal(kegagalan);
      }
    }
    return _profil.ubah(nama: n, fotoUrl: url);
  }
}
