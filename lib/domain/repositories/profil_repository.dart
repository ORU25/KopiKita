import '../entities/profil.dart';
import '../hasil.dart';

/// ProfilRepository: KONTRAK profil user yang sedang login (users/{uid}).
abstract class ProfilRepository {
  /// Stream profil (realtime). Belum login → profil kosong.
  Stream<Profil> stream();

  /// Ubah nama dan (opsional) foto profil.
  Future<Hasil<void>> ubah({required String nama, String? fotoUrl});

  Future<Hasil<void>> setNotifikasi(bool aktif);
}
