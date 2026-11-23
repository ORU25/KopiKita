/// PushRepository: KONTRAK pendaftaran HP ini untuk push notification.
abstract class PushRepository {
  /// Minta izin + simpan token perangkat ke akun. Gagal diam-diam.
  Future<void> daftar();

  /// Hapus token HP ini dari akun. Panggil SEBELUM keluar.
  Future<void> lepas();
}
