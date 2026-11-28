import 'package:flutter/widgets.dart';

import '../data/local/product_cache_repository.dart';
import '../domain/entities/produk.dart';
import '../domain/hasil.dart';
import '../domain/repositories/product_repository.dart';
import 'stream_view_model.dart';

// ProdukViewModel: katalog produk realtime, dipakai bersama oleh Beranda,
// Menu, Cari, Favorit, dan Riwayat (satu langganan untuk semua layar).
class ProdukViewModel extends StreamViewModel<List<Produk>> {
  ProdukViewModel(this._repo, this._cacheRepo) {
    muatUlang();
  }

  final ProductRepository _repo;
  final ProductCacheRepository _cacheRepo;

  @override
  Stream<List<Produk>> buatStream() => _repo.stream();

  /// Memuat produk dari cache lokal (untuk offline mode).
  /// Tidak memakai stream; sekali baca lalu selesai.
  Future<void> muatDariCache() async {
    setState(const AsyncSnapshot.waiting());
    notifyListeners();

    final hasil = await _cacheRepo.muatSemua();
    switch (hasil) {
      case Berhasil(:final nilai):
        setState(AsyncSnapshot.withData(ConnectionState.done, nilai));
      case Gagal():
        setState(AsyncSnapshot.withError(ConnectionState.done, Exception('Cache kosong'), StackTrace.current));
    }
    notifyListeners();
  }
}
