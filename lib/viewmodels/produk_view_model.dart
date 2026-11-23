import '../domain/entities/produk.dart';
import '../domain/repositories/product_repository.dart';
import 'stream_view_model.dart';

// ProdukViewModel: katalog produk realtime, dipakai bersama oleh Beranda,
// Menu, Cari, Favorit, dan Riwayat (satu langganan untuk semua layar).
class ProdukViewModel extends StreamViewModel<List<Produk>> {
  ProdukViewModel(this._repo) {
    muatUlang();
  }

  final ProductRepository _repo;

  @override
  Stream<List<Produk>> buatStream() => _repo.stream();
}
