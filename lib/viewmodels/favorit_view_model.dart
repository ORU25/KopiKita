import '../domain/repositories/favorit_repository.dart';
import 'pesan_kegagalan.dart';
import 'stream_view_model.dart';

// FavoritViewModel: himpunan id produk favorit + aksi tandai/hapus.
class FavoritViewModel extends StreamViewModel<Set<String>> {
  FavoritViewModel(this._repo) {
    muatUlang();
  }

  final FavoritRepository _repo;

  @override
  Stream<Set<String>> buatStream() => _repo.stream();

  Set<String> get ids => data ?? const <String>{};

  /// siap: false sampai daftar pertama datang (agar Favorit tidak sempat "kosong").
  bool get siap => keadaan.hasData;

  bool isFavorit(String produkId) => ids.contains(produkId);

  /// toggle: null = berhasil, selain itu pesan galat.
  Future<String?> toggle(String produkId) async {
    final h = await _repo.set(produkId, favorit: !isFavorit(produkId));
    return pesanDari(h) == null ? null : 'Gagal menyimpan favorit. Coba lagi.';
  }
}
