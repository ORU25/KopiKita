import '../hasil.dart';

/// FavoritRepository: KONTRAK daftar id produk favorit user.
abstract class FavoritRepository {
  /// Stream himpunan id produk favorit. Kosong bila belum login.
  Stream<Set<String>> stream();

  /// Tambah (favorit = true) atau hapus (false) satu produk dari favorit.
  Future<Hasil<void>> set(String produkId, {required bool favorit});
}
