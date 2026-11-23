import '../entities/pesanan.dart';
import '../hasil.dart';

/// OrderRepository: KONTRAK akses pesanan milik user yang sedang login.
/// Implementasi sungguhan: data/repositories/order_repository_firestore.dart.
abstract class OrderRepository {
  /// streamAktif: pesanan user yang belum selesai/batal, terbaru dulu.
  Stream<List<Pesanan>> streamAktif();

  /// streamRiwayat: pesanan user yang sudah `selesai` atau `batal`, terbaru dulu.
  Stream<List<Pesanan>> streamRiwayat();

  /// buat: simpan [draf] sebagai pesanan baru berstatus `menunggu_bayar`.
  /// id, uid, dan nomor antrean diisi repository secara atomik (produk habis
  /// dan voucher diperiksa ulang di server). Berhasil berisi nomor antrean.
  Future<Hasil<String>> buat(Pesanan draf);

  /// batalkan: ubah status pesanan ke `batal` hanya bila masih `menunggu_bayar`.
  /// Tidak melempar exception: kegagalan dikembalikan sebagai Gagal(...).
  Future<Hasil<void>> batalkan(String orderId);
}
