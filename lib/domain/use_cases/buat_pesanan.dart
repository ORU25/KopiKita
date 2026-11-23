import '../entities/pesanan.dart';
import '../hasil.dart';
import '../repositories/order_repository.dart';

// USE CASE: kirim isi keranjang sebagai pesanan baru.
// Aturan bisnis yang bisa diperiksa tanpa server ada di sini; aturan yang
// butuh data terbaru (produk habis, voucher, nomor antrean) diperiksa
// repository di dalam transaction.
class BuatPesanan {
  BuatPesanan(this._pesanan);

  final OrderRepository _pesanan;

  /// Berhasil berisi nomor antrean, mis. "A-014".
  Future<Hasil<String>> jalankan(Pesanan draf) async {
    if (draf.items.isEmpty) {
      return const Gagal(AturanDilanggar('Keranjang masih kosong.'));
    }
    if (draf.total < 0 || draf.diskon > draf.subtotal) {
      return const Gagal(AturanDilanggar('Rincian harga tidak valid.'));
    }
    return _pesanan.buat(draf);
  }
}
