import '../entities/voucher.dart';
import '../hasil.dart';

/// VoucherRepository: KONTRAK katalog voucher (vouchers/{kode}).
abstract class VoucherRepository {
  /// Satu voucher berdasarkan kode; Berhasil(null) bila tidak ada.
  Future<Hasil<Voucher?>> ambil(String kode);

  /// Stream voucher untuk daftar kode (urutan mengikuti [kode]).
  Stream<List<Voucher>> streamKode(List<String> kode);
}
