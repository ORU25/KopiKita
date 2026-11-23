import '../domain/entities/notifikasi.dart';
import '../domain/repositories/notifikasi_repository.dart';
import 'stream_view_model.dart';

// NotifikasiViewModel: kotak notifikasi + jumlah belum dibaca (titik merah).
class NotifikasiViewModel extends StreamViewModel<List<Notifikasi>> {
  NotifikasiViewModel(this._repo) {
    muatUlang();
  }

  final NotifikasiRepository _repo;

  @override
  Stream<List<Notifikasi>> buatStream() => _repo.stream();

  int get belumDibaca => (data ?? const []).where((n) => !n.dibaca).length;

  Future<void> tandaiSemuaDibaca() async {
    try {
      await _repo.tandaiSemuaDibaca();
    } catch (_) {
      // Gagal ditandai: titik merah tetap tampil, tidak mengganggu pengguna
    }
  }
}
