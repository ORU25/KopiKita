import '../domain/entities/pesanan.dart';
import '../domain/repositories/order_repository.dart';
import '../domain/use_cases/batalkan_pesanan.dart';
import 'pesan_kegagalan.dart';
import 'stream_view_model.dart';

// PesananAktifViewModel: pesanan yang masih berjalan + aksi batalkan.
class PesananAktifViewModel extends StreamViewModel<List<Pesanan>> {
  PesananAktifViewModel(this._repo, this._batalkan) {
    muatUlang();
  }

  final OrderRepository _repo;
  final BatalkanPesanan _batalkan;

  @override
  Stream<List<Pesanan>> buatStream() => _repo.streamAktif();

  /// batalkan: kalimat hasil untuk SnackBar (berhasil maupun gagal).
  Future<String> batalkan(Pesanan p) async {
    final h = await _batalkan.jalankan(p);
    return pesanDari(h) ?? 'Pesanan dibatalkan.';
  }
}

// RiwayatPesananViewModel: pesanan selesai/batal, terbaru dulu.
class RiwayatPesananViewModel extends StreamViewModel<List<Pesanan>> {
  RiwayatPesananViewModel(this._repo) {
    muatUlang();
  }

  final OrderRepository _repo;

  @override
  Stream<List<Pesanan>> buatStream() => _repo.streamRiwayat();
}
