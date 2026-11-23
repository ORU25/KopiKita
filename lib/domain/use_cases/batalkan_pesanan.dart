import '../../models/pesanan.dart';
import '../hasil.dart';
import '../repositories/order_repository.dart';

// Kalimat penolakan; dipakai juga repository saat server menolak (status
// sudah berubah di tengah jalan karena staf memproses pesanan).
const String alasanPesananSudahDiproses =
    'Pesanan sudah diproses kasir dan tidak bisa dibatalkan.';

// USE CASE: satu tindakan pengguna, lengkap dengan aturannya.
// Aturan bisnis: pelanggan hanya boleh membatalkan pesanan yang masih
// `menunggu_bayar`. Pemeriksaan ini sengaja ada di domain agar bisa diuji
// tanpa Firebase; repository tetap memeriksa ulang di dalam transaction
// untuk menangkap perubahan staf yang masuk bersamaan.
class BatalkanPesanan {
  BatalkanPesanan(this._pesanan);

  final OrderRepository _pesanan;

  // Index `statusKode` untuk 'menunggu_bayar' (lihat models/pesanan.dart)
  static const int _menungguBayar = 0;

  Future<Hasil<void>> jalankan(Pesanan pesanan) async {
    if (pesanan.status != _menungguBayar) {
      return const Gagal<void>(AturanDilanggar(alasanPesananSudahDiproses));
    }
    return _pesanan.batalkan(pesanan.id);
  }
}
