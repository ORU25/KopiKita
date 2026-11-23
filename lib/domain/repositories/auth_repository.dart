import '../hasil.dart';

/// AuthRepository: KONTRAK akun (masuk, daftar, keluar, sandi).
/// Implementasi: data/repositories/auth_repository_firebase.dart.
abstract class AuthRepository {
  /// UID user yang sedang login, atau null.
  String? get uid;

  /// Stream UID: berubah saat login/logout (null = belum login).
  Stream<String?> perubahanUid();

  /// Masuk; dokumen profil dibuat bila belum ada.
  Future<Hasil<void>> masuk({required String email, required String sandi});

  /// Daftar akun baru beserta dokumen profilnya.
  Future<Hasil<void>> daftar({
    required String nama,
    required String email,
    required String sandi,
  });

  /// Kirim tautan reset kata sandi ke email.
  Future<Hasil<void>> kirimResetSandi(String email);

  /// Verifikasi ulang dengan sandi lama, lalu ganti ke sandi baru.
  /// Sandi lama salah → Gagal(KredensialSalah()).
  Future<Hasil<void>> ubahSandi({required String lama, required String baru});

  Future<void> keluar();
}
