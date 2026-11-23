/// PushRepository: KONTRAK pendaftaran HP ini untuk push notification.
abstract class PushRepository {
  /// Saat login: simpan token HANYA jika izin sudah ada (tanpa dialog).
  Future<void> daftar();

  /// Tampilkan dialog izin notifikasi (Android 13+), lalu simpan token.
  /// true = diizinkan. Dipanggil saat pengguna menyalakan fitur notifikasi.
  Future<bool> mintaIzin();

  /// Hapus token HP ini dari akun. Panggil SEBELUM keluar.
  Future<void> lepas();
}
